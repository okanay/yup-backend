package file

import (
	"github.com/gin-gonic/gin"
	"github.com/okanay/yup-backend/internal/httpapi"
	"github.com/okanay/yup-backend/internal/platform/r2"
)

type Handler interface {
	CreatePresignedURL(c *gin.Context)
}

type fileHandler struct {
	validator *httpapi.Validator
	r2Client  *r2.Client
}

func NewHandler(v *httpapi.Validator, r2 *r2.Client) Handler {
	return &fileHandler{
		validator: v,
		r2Client:  r2,
	}
}
