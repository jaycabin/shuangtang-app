package model

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID                uuid.UUID `json:"id" db:"id"`
	Email             string    `json:"email" db:"email"`
	PasswordHash      string    `json:"-" db:"password_hash"`
	Nickname          string    `json:"nickname" db:"nickname"`
	AvatarURL         string    `json:"avatar_url" db:"avatar_url"`
	PreferredLanguage string    `json:"preferred_language" db:"preferred_language"`
	IsAdmin           bool      `json:"is_admin" db:"is_admin"`
	CreatedAt         time.Time `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time `json:"updated_at" db:"updated_at"`
}

type Couple struct {
	ID             uuid.UUID  `json:"id" db:"id"`
	User1ID        uuid.UUID  `json:"user1_id" db:"user1_id"`
	User2ID        *uuid.UUID `json:"user2_id,omitempty" db:"user2_id"`
	InvitationCode string     `json:"invitation_code" db:"invitation_code"`
	Status         string     `json:"status" db:"status"`
	StartedAt      *time.Time `json:"started_at,omitempty" db:"started_at"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at" db:"updated_at"`
}

type Moment struct {
	ID        uuid.UUID              `json:"id" db:"id"`
	CoupleID  uuid.UUID              `json:"couple_id" db:"couple_id"`
	AuthorID  uuid.UUID              `json:"author_id" db:"author_id"`
	Type      string                 `json:"type" db:"type"`
	Content   string                 `json:"content" db:"content"`
	ImageURLs []string               `json:"image_urls" db:"image_urls"`
	Location  map[string]interface{} `json:"location,omitempty" db:"location"`
	MoodTag   string                 `json:"mood_tag,omitempty" db:"mood_tag"`
	IsPinned  bool                   `json:"is_pinned" db:"is_pinned"`
	CreatedAt time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt time.Time              `json:"updated_at" db:"updated_at"`
}

type Anniversary struct {
	ID          uuid.UUID              `json:"id" db:"id"`
	CoupleID    uuid.UUID              `json:"couple_id" db:"couple_id"`
	Title       map[string]string      `json:"title" db:"title"`
	Date        time.Time              `json:"date" db:"date"`
	IsRecurring bool                   `json:"is_recurring" db:"is_recurring"`
	RemindBefore int                   `json:"remind_before" db:"remind_before"`
	Icon        string                 `json:"icon" db:"icon"`
	CreatedBy   uuid.UUID              `json:"created_by" db:"created_by"`
	CreatedAt   time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at" db:"updated_at"`
}

type CheckInTask struct {
	ID           uuid.UUID         `json:"id" db:"id"`
	CoupleID     uuid.UUID         `json:"couple_id" db:"couple_id"`
	Title        map[string]string `json:"title" db:"title"`
	Icon         string            `json:"icon" db:"icon"`
	ScheduleType string            `json:"schedule_type" db:"schedule_type"`
	SortOrder    int               `json:"sort_order" db:"sort_order"`
	IsActive     bool              `json:"is_active" db:"is_active"`
	CreatedBy    uuid.UUID         `json:"created_by" db:"created_by"`
	CreatedAt    time.Time         `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time         `json:"updated_at" db:"updated_at"`
}

type CheckInRecord struct {
	ID        uuid.UUID `json:"id" db:"id"`
	TaskID    uuid.UUID `json:"task_id" db:"task_id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	CheckDate time.Time `json:"check_date" db:"check_date"`
	DoneAt    time.Time `json:"done_at" db:"done_at"`
	Note      string    `json:"note,omitempty" db:"note"`
}

type WishlistItem struct {
	ID          uuid.UUID         `json:"id" db:"id"`
	CoupleID    uuid.UUID         `json:"couple_id" db:"couple_id"`
	CreatorID   uuid.UUID         `json:"creator_id" db:"creator_id"`
	Title       map[string]string `json:"title" db:"title"`
	Description string            `json:"description" db:"description"`
	ImageURL    string            `json:"image_url,omitempty" db:"image_url"`
	Price       *float64          `json:"price,omitempty" db:"price"`
	Status      string            `json:"status" db:"status"`
	ClaimedBy   *uuid.UUID        `json:"claimed_by,omitempty" db:"claimed_by"`
	CompletedAt *time.Time        `json:"completed_at,omitempty" db:"completed_at"`
	CreatedAt   time.Time         `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at" db:"updated_at"`
}

type Album struct {
	ID           uuid.UUID `json:"id" db:"id"`
	CoupleID     uuid.UUID `json:"couple_id" db:"couple_id"`
	UploaderID   uuid.UUID `json:"uploader_id" db:"uploader_id"`
	ImageURL     string    `json:"image_url" db:"image_url"`
	ThumbnailURL string    `json:"thumbnail_url,omitempty" db:"thumbnail_url"`
	TakenAt      *time.Time `json:"taken_at,omitempty" db:"taken_at"`
	Location     map[string]interface{} `json:"location,omitempty" db:"location"`
	Tags         []string  `json:"tags,omitempty" db:"tags"`
	Width        int       `json:"width" db:"width"`
	Height       int       `json:"height" db:"height"`
	FileSize     int       `json:"file_size" db:"file_size"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

type SecretMessage struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	CoupleID         uuid.UUID  `json:"couple_id" db:"couple_id"`
	SenderID         uuid.UUID  `json:"sender_id" db:"sender_id"`
	Content          string     `json:"content" db:"content"`
	EncryptedContent string     `json:"encrypted_content" db:"encrypted_content"`
	IsRead           bool       `json:"is_read" db:"is_read"`
	ReadAt           *time.Time `json:"read_at,omitempty" db:"read_at"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
}

type Alarm struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	CoupleID        uuid.UUID  `json:"couple_id" db:"couple_id"`
	SetterID        uuid.UUID  `json:"setter_id" db:"setter_id"`
	CloserID        *uuid.UUID `json:"closer_id,omitempty" db:"closer_id"`
	AlarmTime       time.Time  `json:"alarm_time" db:"alarm_time"`
	TaskType        string     `json:"task_type" db:"task_type"`
	TaskDescription string     `json:"task_description" db:"task_description"`
	AudioURL        string     `json:"audio_url,omitempty" db:"audio_url"`
	Status          string     `json:"status" db:"status"`
	ClosedAt        *time.Time `json:"closed_at,omitempty" db:"closed_at"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
}

type SystemConfig struct {
	ID          uuid.UUID `json:"id" db:"id"`
	Key         string    `json:"key" db:"key"`
	Value       string    `json:"value" db:"value"`
	Description string    `json:"description,omitempty" db:"description"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type Notification struct {
	ID        uuid.UUID              `json:"id" db:"id"`
	CoupleID  uuid.UUID              `json:"couple_id" db:"couple_id"`
	UserID    uuid.UUID              `json:"user_id" db:"user_id"`
	Type      string                 `json:"type" db:"type"`
	Title     string                 `json:"title" db:"title"`
	Body      string                 `json:"body" db:"body"`
	Metadata  map[string]interface{} `json:"metadata,omitempty" db:"metadata"`
	IsRead    bool                   `json:"is_read" db:"is_read"`
	CreatedAt time.Time              `json:"created_at" db:"created_at"`
}

type LocationShare struct {
	ID          uuid.UUID `json:"id" db:"id"`
	CoupleID    uuid.UUID `json:"couple_id" db:"couple_id"`
	UserID      uuid.UUID `json:"user_id" db:"user_id"`
	Latitude    float64   `json:"latitude" db:"latitude"`
	Longitude   float64   `json:"longitude" db:"longitude"`
	BatteryLevel int      `json:"battery_level" db:"battery_level"`
	IsMoving    bool      `json:"is_moving" db:"is_moving"`
	SharedAt    time.Time `json:"shared_at" db:"shared_at"`
}

// API request/response types

type RegisterRequest struct {
	Email           string `json:"email" binding:"required,email"`
	Password        string `json:"password" binding:"required,min=6"`
	Nickname        string `json:"nickname"`
	VerificationCode string `json:"verification_code" binding:"required,len=6"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password"`
	Code     string `json:"code"`
}

type SendCodeRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type ResetPasswordRequest struct {
	Email           string `json:"email" binding:"required,email"`
	Code            string `json:"code" binding:"required,len=6"`
	NewPassword     string `json:"new_password" binding:"required,min=6"`
}

type CreateCoupleRequest struct {
	Nickname string `json:"nickname"`
}

type JoinCoupleRequest struct {
	InvitationCode string `json:"invitation_code" binding:"required"`
	Nickname       string `json:"nickname"`
}

type CreateMomentRequest struct {
	Content  string                 `json:"content"`
	ImageURLs []string              `json:"image_urls"`
	Location map[string]interface{} `json:"location,omitempty"`
	MoodTag  string                 `json:"mood_tag,omitempty"`
}

type CreateAnniversaryRequest struct {
	Title       map[string]string `json:"title" binding:"required"`
	Date        string            `json:"date" binding:"required"`
	IsRecurring bool              `json:"is_recurring"`
	RemindBefore int              `json:"remind_before"`
	Icon        string            `json:"icon"`
}

type CreateWishlistRequest struct {
	Title       map[string]string `json:"title" binding:"required"`
	Description string            `json:"description"`
	ImageURL    string            `json:"image_url"`
	Price       *float64          `json:"price"`
}

type SendSecretMessageRequest struct {
	Content string `json:"content" binding:"required"`
}

type CreateAlarmRequest struct {
	AlarmTime       string `json:"alarm_time" binding:"required"`
	TaskType        string `json:"task_type"`
	TaskDescription string `json:"task_description"`
}

type APIResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

type PaginatedResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
	Total   int         `json:"total"`
	Page    int         `json:"page"`
	Size    int         `json:"size"`
}
