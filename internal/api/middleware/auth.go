package middleware

import (
	"github.com/gin-gonic/gin"
)

func (m *Manager) AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}
