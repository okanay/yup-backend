package r2

import (
	"crypto/rand"
	"log"
	"math/big"
	"strings"
)

const Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

// GenerateRandomString: Belirtilen uzunlukta güvenli rastgele string üretir.
func GenerateRandomString(length int) string {
	b := make([]byte, length)
	for i := range b {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(Alphabet))))
		if err != nil {
			log.Panicf("crypto/rand failed: %v", err)
		}
		b[i] = Alphabet[num.Int64()]
	}
	return string(b)
}

// SanitizeFilename: Dosya adını güvenli hale getirir.
func SanitizeFilename(filename string) string {
	filename = strings.ReplaceAll(filename, " ", "-")

	filename = strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '.' || r == '-' || r == '_' {
			return r
		}
		return -1
	}, filename)

	return strings.ReplaceAll(filename, "..", "")
}
