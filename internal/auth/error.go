package auth

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/okanay/yup-backend/internal/httpapi"
)

var (
	ErrUnauthorized       = errors.New("auth: unauthorized")
	ErrEmailAlreadyExists = errors.New("auth: email already exists")
	ErrUserNotFound       = errors.New("auth: user not found")
	ErrInvalidCredentials = errors.New("auth: invalid credentials")
)

func writeAuthError(c *gin.Context, err error) {
	status := http.StatusInternalServerError
	key := "InternalServerError"
	message := "Something went wrong on our end."

	switch {
	case errors.Is(err, ErrUnauthorized):
		status = http.StatusUnauthorized
		key = http.StatusText(http.StatusUnauthorized)
		message = "You are not authorized to access this resource."

	case errors.Is(err, ErrInvalidCredentials):
		status = http.StatusUnauthorized
		key = http.StatusText(http.StatusUnauthorized)
		message = "Invalid credentials."

	case errors.Is(err, ErrUserNotFound):
		status = http.StatusNotFound
		key = http.StatusText(http.StatusNotFound)
		message = "User not found."

	case errors.Is(err, ErrEmailAlreadyExists):
		status = http.StatusConflict
		key = "EmailAlreadyExists"
		message = "Email already exists."

	default:
		slog.ErrorContext(
			c.Request.Context(),
			"unexpected authentication error",
			"error", err,
			"route", c.FullPath(),
			"method", c.Request.Method,
		)
	}

	httpapi.ErrorResponse(c, status, key, message)
}
