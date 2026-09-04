package middleware

import (
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/okanay/yup-backend/internal/core"
)

func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		status := c.Writer.Status()
		duration := time.Since(start)

		logger(c, status, duration)
	}
}

func logger(c *gin.Context, status int, duration time.Duration) {
	attrs := make([]slog.Attr, 0, 10)

	// 1. HTTP Metadata
	attrs = append(attrs,
		slog.Int("status", status),
		slog.String("latency", duration.String()),
		slog.String("client_ip", core.GetClientIP(c)),
	)

	val, exists := core.GetUserID(c)
	if exists {
		attrs = append(attrs, slog.String("user_id", val))
	}

	// 3. Errors
	if len(c.Errors) > 0 {
		errMsgs := make([]string, 0, len(c.Errors))

		for i := range c.Errors {
			errMsgs = append(errMsgs, c.Errors[i].Err.Error())
		}

		attrs = append(attrs, slog.String("error", strings.Join(errMsgs, "; ")))
	}

	var level slog.Level
	var path string = c.FullPath()
	var msg string = fmt.Sprintf("%s %s", c.Request.Method, path)

	switch {
	case status >= 500:
		level = slog.LevelError
	case status >= 400:
		level = slog.LevelWarn
	default:
		level = slog.LevelInfo
	}

	slog.LogAttrs(c.Request.Context(), level, msg, attrs...)
}
