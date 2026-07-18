package file

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/okanay/yup-backend/internal/httpapi"
	"github.com/okanay/yup-backend/internal/platform/r2"
)

func (h *fileHandler) CreatePresignedURL(c *gin.Context) {
	var input r2.UploadInput

	if err := c.ShouldBindJSON(&input); err != nil {
		httpapi.BindingError(c, err)
		return
	}

	if violations := h.validator.Validate(&input); violations != nil {
		httpapi.ValidationError(c, violations)
		return
	}

	output, err := h.r2Client.GeneratePresignedURL(c.Request.Context(), input)
	if err != nil {
		httpapi.ErrorResponse(c, http.StatusBadRequest, "PresignedURLGenerationError", err.Error())
		return
	}

	// TODO :: Create Database Record Here.

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    output,
	})
}
