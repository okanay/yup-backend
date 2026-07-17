package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/okanay/yup-backend/internal/auth"
)

func AuthMiddleware(authService auth.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}
