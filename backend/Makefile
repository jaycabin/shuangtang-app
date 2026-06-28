.PHONY: dev build up down migrate-up migrate-down test lint clean

APP_NAME = shuangtang-backend

dev:
	air

build:
	go build -o tmp/$(APP_NAME) ./cmd/server

up:
	docker-compose up -d

down:
	docker-compose down

migrate-up:
	go run ./cmd/migrate up

migrate-down:
	go run ./cmd/migrate down

migrate-create:
	@read -p "Enter migration name: " name; \
	migrate create -ext sql -dir migrations -seq $$name

test:
	go test ./... -v -cover

lint:
	golangci-lint run ./...

clean:
	rm -rf tmp/
	rm -f $(APP_NAME)
