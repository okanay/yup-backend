package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/okanay/yup-backend/internal/core"
)

func NotFound(c *gin.Context) {
	core.ErrorResponse(c, nil, http.StatusNotFound, "route_not_found", "The requested route does not exist.")
}
