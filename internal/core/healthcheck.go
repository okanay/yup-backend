package core

import (
	"fmt"
	"net/http"
	"os"
)

func HealthCheckProbe(port string, healthPath string) {
	if len(os.Args) <= 1 || os.Args[1] != "health" {
		return
	}

	targetURL := fmt.Sprintf("http://127.0.0.1:%s%s", port, healthPath)
	client := http.Client{}

	resp, err := client.Get(targetURL)
	if err != nil || resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}

	os.Exit(0)
}
