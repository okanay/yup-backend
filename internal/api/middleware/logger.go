package middleware

import "github.com/gin-gonic/gin"

func (m *Manager) LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}
