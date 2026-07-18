package httpapi

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

type ErrorBody struct {
	Status     int         `json:"status"`
	Key        string      `json:"errorKey"`
	Message    string      `json:"message"`
	Violations []Violation `json:"violations,omitempty"`
}

type Violation struct {
	Field   string `json:"field"`
	Tag     string `json:"tag"`
	Message string `json:"message"`
}

func ErrorResponse(c *gin.Context, status int, key string, msg string) {
	keyFallback := key

	if keyFallback == "" {
		keyFallback = http.StatusText(status)
	}

	c.AbortWithStatusJSON(status, ErrorBody{
		Status:  status,
		Key:     keyFallback,
		Message: msg,
	})
}

func ValidationError(c *gin.Context, violations []Violation) {
	c.AbortWithStatusJSON(http.StatusBadRequest, ErrorBody{
		Status:     http.StatusBadRequest,
		Key:        "ValidationError",
		Message:    "Validation failed. Please check your input.",
		Violations: violations,
	})
}

func BindingError(c *gin.Context, err error) {
	c.AbortWithStatusJSON(http.StatusBadRequest, ErrorBody{
		Status:  http.StatusBadRequest,
		Key:     "BindingError",
		Message: fmt.Sprintf("Invalid data format: %v", err),
	})
}
