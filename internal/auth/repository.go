package auth

import (
	"context"
	"database/sql"
)

type Repository struct {
	db *sql.DB
}

type IRepository interface {
	CreateNewUser(ctx context.Context, email, password string) error
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}
