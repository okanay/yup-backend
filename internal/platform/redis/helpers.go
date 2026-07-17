package redis

import (
	"context"

	"github.com/redis/go-redis/v9"
)

// Scan - Key pattern araması için (stats endpoint'inde kullanılıyor)
func (r *RedisClient) Scan(ctx context.Context, cursor uint64, match string, count int64) *redis.ScanCmd {
	return r.client.Scan(ctx, cursor, match, count)
}

// SMembers - Set içeriğini almak için (dependency görüntüleme)
func (r *RedisClient) SMembers(ctx context.Context, key string) *redis.StringSliceCmd {
	return r.client.SMembers(ctx, key)
}

// DBSize - Toplam key sayısı
func (r *RedisClient) DBSize(ctx context.Context) *redis.IntCmd {
	return r.client.DBSize(ctx)
}

// Seçili olan DB'deki (örneğin DB 0) TÜM veriyi siler.
// DİKKAT: Production ortamında asla çağrılmamalıdır.
func (r *RedisClient) ClearAll() error {
	return r.client.FlushDB(context.Background()).Err()
}
