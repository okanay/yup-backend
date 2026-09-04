package core

import "github.com/gin-gonic/gin"

func GetClientIP(c *gin.Context) string {
	if ip := c.GetHeader("CF-Connecting-IP"); ip != "" {
		return ip
	}

	if ip := c.GetHeader("X-Real-IP"); ip != "" {
		return ip
	}

	return c.ClientIP()
}
