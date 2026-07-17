package redis

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisClient struct {
	client redis.UniversalClient
}

func Initialize(addr []string, username, password string, dbStr string) (*RedisClient, error) {
	db, err := strconv.Atoi(dbStr)
	if err != nil {
		err = fmt.Errorf("[REDIS::INFO] :: Redis db parse error: %w", err)
		return nil, err
	}

	rdb := redis.NewUniversalClient(&redis.UniversalOptions{
		Addrs:        addr,
		Username:     username,
		Password:     password,
		DB:           db,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if _, err := rdb.Ping(ctx).Result(); err != nil {
		err = fmt.Errorf("[REDIS::INFO] :: Redis connection failed: %w", err)
		return nil, err
	}

	instance := &RedisClient{client: rdb}

	return instance, nil
}
