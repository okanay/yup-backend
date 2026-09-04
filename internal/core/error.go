package core

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

type Error struct {
	Status      int          `json:"status"`
	Key         string       `json:"key"`
	Message     string       `json:"message"`
	Validations []Validation `json:"validations"`
}

type Validation struct {
	Field   string `json:"field"`
	Tag     string `json:"tag"`
	Message string `json:"message"`
}

func ErrorResponse(c *gin.Context, err error, status int, key string, msg string) {
	if err == nil {
		err = errors.New("error not declared")
	}

	if status == 0 {
		status = http.StatusInternalServerError
	}

	if key == "" {
		key = "internalServerError"
	}

	if msg == "" {
		msg = "Something went wrong."
	}

	_ = c.Error(fmt.Errorf("err=%w key=%s message=%s", err, key, msg))

	c.AbortWithStatusJSON(status, Error{
		Status:      status,
		Key:         key,
		Message:     msg,
		Validations: []Validation{},
	})
}

func ValidationError(c *gin.Context, validationErrors []Validation) {
	for index, v := range validationErrors {
		_ = c.Error(fmt.Errorf("validation %d: field=%s, tag=%s, msg=%s", index, v.Field, v.Tag, v.Message))
	}

	c.AbortWithStatusJSON(http.StatusBadRequest, Error{
		Status:      http.StatusBadRequest,
		Key:         "validationError",
		Message:     "Validation failed. Please check your input.",
		Validations: validationErrors,
	})
}

func BindingError(c *gin.Context, err error) {
	_ = c.Error(fmt.Errorf("binding: %w", err))

	c.AbortWithStatusJSON(http.StatusBadRequest, Error{
		Status:      http.StatusBadRequest,
		Key:         "bindingError",
		Message:     fmt.Sprintf("Invalid data format: %v", err),
		Validations: []Validation{},
	})
}

func ServerError(c *gin.Context, err error) {
	ErrorResponse(c, err, http.StatusInternalServerError, "internalServerError", "Something went wrong.")
}
