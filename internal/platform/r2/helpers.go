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
			// crypto/rand hatası kritik bir OS sorunudur, panic makuldür.
			log.Panicf("crypto/rand failed: %v", err)
		}
		b[i] = Alphabet[num.Int64()]
	}
	return string(b)
}

// GenerateRandomInt: [min, max] aralığında güvenli rastgele sayı üretir.
func GenerateRandomInt(min, max int) int {
	if max <= min {
		return min // Hata yerine min dönerek akışı bozmuyoruz, log basılabilir.
	}
	diff := max - min
	nBig, err := rand.Int(rand.Reader, big.NewInt(int64(diff)))
	if err != nil {
		log.Panicf("crypto/rand failed: %v", err)
	}
	return int(nBig.Int64()) + min
}

// SanitizeFilename: Dosya adını güvenli hale getirir.
func SanitizeFilename(filename string) string {
	// 1. Uzantıyı ayır (varsa korumak için) ama biz tamamını sanitize edeceğiz.
	// 2. Boşlukları tire yap
	filename = strings.ReplaceAll(filename, " ", "-")

	// 3. Sadece izin verilen karakterleri tut
	filename = strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '.' || r == '-' || r == '_' {
			return r
		}
		return -1 // Geçersiz karakteri sil
	}, filename)

	// 4. Çift noktaları (..) engelle (Path traversal koruması)
	return strings.ReplaceAll(filename, "..", "")
}
