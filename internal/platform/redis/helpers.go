package redis

import (
	"context"
)

func (r *Client) ClearAll() error {
	return r.client.FlushDB(context.Background()).Err()
}
