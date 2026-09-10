package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/okanay/yup-backend/internal/core"
)

func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "API is running!",
		"ip":      core.GetClientIP(c),
	})
}
