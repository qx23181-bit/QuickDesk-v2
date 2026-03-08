package database

import (
	"context"
	"log"
	"quickdesk/signaling/internal/config"
	"time"

	"github.com/redis/go-redis/v9"
)

// InitRedis initializes the Redis client
func InitRedis(cfg *config.Config) *redis.Client {
	client := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr(),
		Password: cfg.Redis.Password,
		DB:       0, // use default DB
	})

	// Test connection with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	if err := client.Ping(ctx).Err(); err != nil {
		log.Printf("Warning: Failed to connect to Redis: %v", err)
		log.Println("Continuing without Redis...")
		return nil
	}

	log.Printf("Successfully connected to Redis at %s", cfg.Redis.Addr())

	return client
}
