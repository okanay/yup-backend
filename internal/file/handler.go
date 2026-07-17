package file

import (
	"github.com/gin-gonic/gin"
	api "github.com/okanay/yup-backend/internal/httpapi"
	"github.com/okanay/yup-backend/internal/platform/r2"
)

type Handler interface {
	CreatePresignedURL(c *gin.Context)
}

type fileHandler struct {
	validator *api.Validator
	r2Client  *r2.Client
}

func NewHandler(v *api.Validator, r2 *r2.Client) Handler {
	return &fileHandler{
		validator: v,
		r2Client:  r2,
	}
}
