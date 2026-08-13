package auth

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/okanay/yup-backend/internal/core"
)

var (
	ErrUnauthorized       = errors.New("unauthorized")
	ErrInvalidCredentials = errors.New("invalidCredentials")
	ErrUserNotFound       = errors.New("userNotFound")
	ErrEmailAlreadyExists = errors.New("emailAlreadyExists")
)

func WriteAuthError(c *gin.Context, err error) {
	var status int
	var key string
	var msg string

	switch {
	case errors.Is(err, ErrUnauthorized):
		status = http.StatusUnauthorized
		key = err.Error()
		msg = "You are not authorized to access this resource."

	case errors.Is(err, ErrInvalidCredentials):
		status = http.StatusUnauthorized
		key = err.Error()
		msg = "Email or password is incorrect."

	case errors.Is(err, ErrUserNotFound):
		status = http.StatusNotFound
		key = err.Error()
		msg = "Requested user was not found."

	case errors.Is(err, ErrEmailAlreadyExists):
		status = http.StatusConflict
		key = err.Error()
		msg = "Email address is already in use."
	}

	core.ErrorResponse(c, err, status, key, msg)
}
