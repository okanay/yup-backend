package core

import (
	"github.com/okanay/yup-backend/internal/platform/postgres"
)

type Config struct {
	Port       string
	HealthPath string
	Postgres   postgres.Config
}

const HealthPath = "/health"

func LoadConfig() Config {
	return Config{
		Port:       GetEnvString("PORT", "8080"),
		HealthPath: HealthPath,
		Postgres: postgres.Config{
			Host:     GetEnvString("DB_HOST", "localhost"),
			Port:     GetEnvString("DB_PORT", "5432"),
			User:     GetEnvString("DB_USER", "postgres"),
			Password: GetEnvString("DB_PASSWORD", "postgres"),
			Database: GetEnvString("DB_NAME", "db_name"),
			SSLMode:  GetEnvString("DB_SSLMODE", "disable"),
		},
	}
}
