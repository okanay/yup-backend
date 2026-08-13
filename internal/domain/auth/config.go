package auth

import "time"

const (
	AccessTokenDuration  = 5 * time.Minute
	RefreshTokenDuration = 7 * 24 * time.Hour
)
