package auth

import "context"

type Service interface {
	CreateUser(ctx context.Context, email, password string) (*User, error)
}

type authService struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &authService{repo: repo}
}

func (s *authService) CreateUser(ctx context.Context, email, password string) (*User, error) {
	user, err := s.repo.CreateUser(ctx, email, password)
	if err != nil {
		return nil, err
	}
	return user, nil
}
