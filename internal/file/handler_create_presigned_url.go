package file

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/okanay/yup-backend/internal/api"
	"github.com/okanay/yup-backend/internal/platform/r2"
)

func (h *Handler) CreatePresignedURL(c *gin.Context) {
	var input r2.UploadInput

	if err := c.ShouldBindJSON(&input); err != nil {
		api.ValidationError(c, []api.Violation{api.BindingViolation(err)})
		return
	}

	if violations := h.validator.Validate(&input); violations != nil {
		api.ValidationError(c, violations)
		return
	}

	output, err := h.r2Client.GeneratePresignedURL(c.Request.Context(), input)
	if err != nil {
		api.Error(c, http.StatusInternalServerError, "invalid_file_type", "Invalid file type.")
		return
	}

	// TODO :: Create Database Record Here.

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    output,
	})
}
