package ws

import (
	"context"
	"encoding/json"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
)

type LocationData struct {
	UserID      string  `json:"user_id"`
	CoupleID    string  `json:"couple_id"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	Battery     int     `json:"battery"`
	IsMoving    bool    `json:"is_moving"`
	Timestamp   int64   `json:"timestamp"`
}

type Client struct {
	UserID   uuid.UUID
	CoupleID uuid.UUID
	Conn     *websocket.Conn
	Send     chan []byte
	Hub      *Hub
}

type Hub struct {
	mu      sync.RWMutex
	clients map[string]*Client // userID -> client
	rooms   map[string]map[string]*Client // coupleID -> userID -> client
	redis   *redis.Client
}

func NewHub(redis *redis.Client) *Hub {
	return &Hub{
		clients: make(map[string]*Client),
		rooms:   make(map[string]map[string]*Client),
		redis:   redis,
	}
}

func (h *Hub) Register(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	uid := client.UserID.String()
	h.clients[uid] = client

	cid := client.CoupleID.String()
	if h.rooms[cid] == nil {
		h.rooms[cid] = make(map[string]*Client)
	}
	h.rooms[cid][uid] = client
}

func (h *Hub) Unregister(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	uid := client.UserID.String()
	delete(h.clients, uid)

	cid := client.CoupleID.String()
	if room, ok := h.rooms[cid]; ok {
		delete(room, uid)
		if len(room) == 0 {
			delete(h.rooms, cid)
		}
	}
}

func (h *Hub) GetRoomClients(coupleID uuid.UUID) []*Client {
	h.mu.RLock()
	defer h.mu.RUnlock()

	cid := coupleID.String()
	room, ok := h.rooms[cid]
	if !ok {
		return nil
	}

	clients := make([]*Client, 0, len(room))
	for _, c := range room {
		clients = append(clients, c)
	}
	return clients
}

func (h *Hub) BroadcastToRoom(coupleID uuid.UUID, message []byte, senderID uuid.UUID) {
	clients := h.GetRoomClients(coupleID)
	for _, client := range clients {
		if client.UserID != senderID {
			select {
			case client.Send <- message:
			default:
			}
		}
	}
}

func (h *Hub) HandleLocationUpdate(client *Client, data []byte) {
	var loc LocationData
	if err := json.Unmarshal(data, &loc); err != nil {
		return
	}

	loc.Timestamp = time.Now().UnixMilli()
	loc.UserID = client.UserID.String()
	loc.CoupleID = client.CoupleID.String()

	msg, _ := json.Marshal(map[string]interface{}{
		"type": "location_update",
		"data": loc,
	})

	// Publish to Redis for persistence
	if h.redis != nil {
		key := "location:" + client.CoupleID.String() + ":" + client.UserID.String()
		h.redis.Set(ctx, key, string(msg), 30*time.Second)
	}

	// Broadcast to partner in the room
	h.BroadcastToRoom(client.CoupleID, msg, client.UserID)
}

var ctx = context.Background()

func (c *Client) ReadPump() {
	defer func() {
		c.Hub.Unregister(c)
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(4096)
	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			break
		}
		c.Hub.HandleLocationUpdate(c, message)
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
