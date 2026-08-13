package core

import (
	"fmt"

	"github.com/gin-gonic/gin"
)

const (
	UserIDKey = "user_id"
)

func SetUserID(c *gin.Context, id string) {
	c.Set(UserIDKey, id)
}

func GetUserID(c *gin.Context) (string, bool) {
	value, exists := c.Get(UserIDKey)
	if !exists {
		return "", false
	}

	userID, ok := value.(string)
	return userID, ok
}

func MustGetUserID(c *gin.Context) string {
	value, exists := c.Get(UserIDKey)
	if !exists {
		panic(fmt.Sprintf("core: %s context içerisinde bulunamadı", UserIDKey))
	}

	userID, ok := value.(string)
	if !ok {
		panic(fmt.Sprintf("core: %s beklenen tip olan string değil (%T)", UserIDKey, value))
	}

	return userID
}
