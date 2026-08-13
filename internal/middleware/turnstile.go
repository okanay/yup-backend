package middleware

import "github.com/gin-gonic/gin"

func TurnstileMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}
