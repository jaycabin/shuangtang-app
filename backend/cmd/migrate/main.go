package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
	"github.com/shuangtang-app/backend/internal/config"
)

func main() {
	_ = godotenv.Load()

	var db config.DBConfig
	if err := envconfig.Process("", &db); err != nil {
		log.Fatalf("Failed to load DB config: %v", err)
	}

	migrationsPath := filepath.Join(".", "migrations")
	if len(os.Args) > 2 && os.Args[1] == "create" {
		fmt.Println("Create migration not implemented in binary mode")
		return
	}

	m, err := migrate.New(
		"file://"+migrationsPath,
		db.DSN(),
	)
	if err != nil {
		log.Fatalf("Failed to create migrator: %v", err)
	}

	cmd := "up"
	if len(os.Args) > 1 {
		cmd = os.Args[1]
	}

	switch cmd {
	case "up":
		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("Migration up failed: %v", err)
		}
		fmt.Println("Migrations applied successfully")
	case "down":
		if err := m.Down(); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("Migration down failed: %v", err)
		}
		fmt.Println("Migrations rolled back successfully")
	case "force":
		if len(os.Args) < 3 {
			log.Fatal("force requires version argument")
		}
		version := 0
		fmt.Sscanf(os.Args[2], "%d", &version)
		if err := m.Force(version); err != nil {
			log.Fatalf("Force version failed: %v", err)
		}
		fmt.Printf("Forced migration version to %d\n", version)
	default:
		fmt.Printf("Unknown command: %s (use up, down, force)\n", cmd)
		os.Exit(1)
	}
}
