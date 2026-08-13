package auth

import (
	"context"
	"database/sql"
)

type Repository interface {
	CreateUser(ctx context.Context, email, password string) (*User, error)
}

type authRepository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &authRepository{db: db}
}

func (r *authRepository) CreateUser(ctx context.Context, email, password string) (*User, error) {
	user := User{Email: email, Password: password}

	return &user, nil
}
