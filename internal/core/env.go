package core

import (
	"os"
	"strconv"
)

func GetEnvString(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}

	return defaultValue
}

func GetEnvInt(key string, defaultValue int) int {
	valueStr, exists := os.LookupEnv(key)

	if !exists {
		return defaultValue
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil {
		return defaultValue
	}

	return value
}

func GetEnvBool(key string, defaultValue bool) bool {
	valueStr, exists := os.LookupEnv(key)

	if !exists {
		return defaultValue
	}

	value, err := strconv.ParseBool(valueStr)
	if err != nil {
		return defaultValue
	}

	return value
}
