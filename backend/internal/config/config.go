package config

import (
	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
	"github.com/rs/zerolog"
)

type Config struct {
	Server   ServerConfig
	DB       DBConfig
	Redis    RedisConfig
	MinIO    MinIOConfig
	JWT      JWTConfig
	SMTP     SMTPConfig
	Admin    AdminConfig
	I18n     I18nConfig
	LogLevel string `envconfig:"LOG_LEVEL" default:"debug"`
	FileStorage string `envconfig:"FILE_STORAGE" default:"local"`
	LocalStoragePath string `envconfig:"LOCAL_STORAGE_PATH" default:"./uploads"`
}

type ServerConfig struct {
	Port            string `envconfig:"SERVER_PORT" default:"10080"`
	Mode            string `envconfig:"SERVER_MODE" default:"debug"`
	AllowedOrigins  string `envconfig:"SERVER_ALLOWED_ORIGINS" default:"*"`
}

type DBConfig struct {
	Host     string `envconfig:"DB_HOST" default:"localhost"`
	Port     string `envconfig:"DB_PORT" default:"15432"`
	User     string `envconfig:"DB_USER" default:"shuangtang"`
	Password string `envconfig:"DB_PASSWORD" default:"shuangtang_secret"`
	Name     string `envconfig:"DB_NAME" default:"shuangtang"`
	SSLMode  string `envconfig:"DB_SSLMODE" default:"disable"`
}

func (d DBConfig) DSN() string {
	return "postgres://" + d.User + ":" + d.Password + "@" + d.Host + ":" + d.Port + "/" + d.Name + "?sslmode=" + d.SSLMode
}

type RedisConfig struct {
	Host     string `envconfig:"REDIS_HOST" default:"localhost"`
	Port     string `envconfig:"REDIS_PORT" default:"16379"`
	Password string `envconfig:"REDIS_PASSWORD" default:""`
	DB       int    `envconfig:"REDIS_DB" default:"0"`
}

func (r RedisConfig) Addr() string {
	return r.Host + ":" + r.Port
}

type MinIOConfig struct {
	Endpoint  string `envconfig:"MINIO_ENDPOINT" default:"localhost:19000"`
	AccessKey string `envconfig:"MINIO_ACCESS_KEY" default:"shuangtang"`
	SecretKey string `envconfig:"MINIO_SECRET_KEY" default:"shuangtang_secret"`
	Bucket    string `envconfig:"MINIO_BUCKET" default:"shuangtang"`
	UseSSL    bool   `envconfig:"MINIO_USE_SSL" default:"false"`
}

type JWTConfig struct {
	Secret      string `envconfig:"JWT_SECRET" required:"true"`
	ExpiryHours int    `envconfig:"JWT_EXPIRY_HOURS" default:"72"`
}

type SMTPConfig struct {
	Host string `envconfig:"SMTP_HOST"`
	Port int    `envconfig:"SMTP_PORT" default:"587"`
	User string `envconfig:"SMTP_USER"`
	Pass string `envconfig:"SMTP_PASS"`
	From string `envconfig:"SMTP_FROM" default:"noreply@shuangtang.app"`
}

type AdminConfig struct {
	Email    string `envconfig:"ADMIN_EMAIL" default:"admin@shuangtang.app"`
	Password string `envconfig:"ADMIN_PASSWORD" default:"admin123456"`
}

type I18nConfig struct {
	DefaultLang string `envconfig:"DEFAULT_LANG" default:"zh"`
}

func Load() (*Config, error) {
	_ = godotenv.Load()

	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

func (c *Config) Logger() zerolog.Level {
	level, err := zerolog.ParseLevel(c.LogLevel)
	if err != nil {
		return zerolog.DebugLevel
	}
	return level
}
