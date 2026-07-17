package file

import "database/sql"

type Repository interface {
}

type fileRepository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &fileRepository{db: db}
}
