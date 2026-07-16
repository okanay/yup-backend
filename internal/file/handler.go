package file

import (
	"github.com/okanay/yup-backend/internal/api"
	"github.com/okanay/yup-backend/internal/platform/r2"
)

type Handler struct {
	validator *api.Validator
	r2Client  *r2.R2
}

func NewHandler(v *api.Validator, r2 *r2.R2) *Handler {
	return &Handler{
		validator: v,
		r2Client:  r2,
	}
}
