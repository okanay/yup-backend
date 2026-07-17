package auth

import "github.com/gin-gonic/gin"

type Handler interface {
	CreateUser(c *gin.Context)
}

type authHandler struct {
	service Service
}

func NewHandler(service Service) Handler {
	return &authHandler{service: service}
}

func (h *authHandler) CreateUser(c *gin.Context) {

}
