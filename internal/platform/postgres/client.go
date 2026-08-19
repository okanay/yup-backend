package postgres

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
	"github.com/okanay/yup-backend/internal/core"
)

func Initialize() (*sql.DB, error) {
	host := core.GetEnvString("DB_HOST", "localhost")
	port := core.GetEnvString("DB_PORT", "5432")
	username := core.GetEnvString("DB_USER", "postgres")
	password := core.GetEnvString("DB_PASSWORD", "postgres")
	database := core.GetEnvString("DB_NAME", "yup_db")
	sslmode := core.GetEnvString("DB_SSLMODE", "disable")

	connectionString := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s", host, port, username, password, database, sslmode)

	db, err := sql.Open("postgres", connectionString)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(25)                 // Aynı anda en fazla 25 eşzamanlı sorgu
	db.SetMaxIdleConns(20)                 // Minimum 2 dakika boyunca trafik geleceği varsayılarak 20 bağlantı bekler.
	db.SetConnMaxIdleTime(2 * time.Minute) // 2 dakika boyunca hiç istek gelmezse bağlantıyı kapat
	db.SetConnMaxLifetime(5 * time.Minute) // Yoğunlukta bile 5 dakikada bir bağlantıyı tazele

	if err := db.Ping(); err != nil {
		return nil, err
	}

	return db, nil
}
