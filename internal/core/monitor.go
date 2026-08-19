package core

import (
	"log/slog"
	"runtime"
	"time"
)

func StartMemoryMonitor() {
	go func() {
		for {
			time.Sleep(60 * time.Second)

			var m runtime.MemStats
			runtime.ReadMemStats(&m)

			slog.Info("[SYSTEM::STATS]",
				"heap_alloc_mb", m.Alloc/(1024*1024),
				"total_sys_mb", m.Sys/(1024*1024),
				"gc_count", m.NumGC,
			)
		}
	}()
}
