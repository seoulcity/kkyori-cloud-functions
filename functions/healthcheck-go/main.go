// Package healthcheck provides a health check Cloud Function.
package healthcheck

import (
	"encoding/json"
	"net/http"
	"os"
	"time"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

func init() {
	functions.HTTP("HealthCheck", HealthCheck)
}

// HealthCheckResponse represents the health check response structure
type HealthCheckResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
	Service   string `json:"service"`
	Version   string `json:"version"`
	Region    string `json:"region"`
	Uptime    string `json:"uptime"`
}

var startTime = time.Now()

// HealthCheck handles the HTTP request for health checking
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers
	setCORSHeaders(w)

	// Handle preflight requests
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	// Calculate uptime
	uptime := time.Since(startTime).Round(time.Second)

	// Get environment variables with defaults
	region := getEnvWithDefault("GOOGLE_CLOUD_REGION", "asia-northeast3")
	version := getEnvWithDefault("SERVICE_VERSION", "1.0.0")

	// Create health check response
	response := HealthCheckResponse{
		Status:    "healthy",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Service:   "kkyori-voca-api",
		Version:   version,
		Region:    region,
		Uptime:    uptime.String(),
	}

	// Set content type and write response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// setCORSHeaders sets CORS headers for the response
func setCORSHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

// getEnvWithDefault returns environment variable value or default if not set
func getEnvWithDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
} 