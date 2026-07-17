package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/okanay/yup-backend/internal/utils"
)

func GenerateAccessToken(userID uuid.UUID, role string) (string, error) {
	secret := utils.GetEnv("JWT_ACCESS_SECRET", "")
	if secret == "" {
		return "", errors.New("JWT_ACCESS_SECRET environment variable is not set")
	}

	now := time.Now().UTC()

	claims := Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(AccessTokenDuration)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    utils.GetEnv("TOKEN_ISSUER", "MY_JWT_ISSUER_NAME"),
			Subject:   userID.String(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func ValidateToken(tokenString string) (*Claims, error) {
	secret := utils.GetEnv("JWT_ACCESS_SECRET", "")

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token claims")
}

func ShouldRefreshToken(claims *Claims) bool {
	if claims.ExpiresAt == nil || claims.IssuedAt == nil {
		return false
	}

	expiresAt := claims.ExpiresAt.Time
	issuedAt := claims.IssuedAt.Time

	totalDuration := expiresAt.Sub(issuedAt)
	remainingDuration := time.Until(expiresAt)

	return remainingDuration < (totalDuration / 4)
}

func GenerateTokens(userID uuid.UUID, role string) (accessToken string, refreshToken string, err error) {
	accessToken, err = GenerateAccessToken(userID, role)
	if err != nil {
		return "", "", err
	}

	refreshTokenUuid, err := uuid.NewV7()
	if err != nil {
		return "", "", err
	}

	refreshToken = refreshTokenUuid.String()
	return accessToken, refreshToken, nil
}
