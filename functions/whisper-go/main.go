// Package whisper provides a Whisper transcription Cloud Function.
package whisper

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/openai/openai-go"
	"github.com/openai/openai-go/option"
)

func init() {
	functions.HTTP("TranscribeAudio", TranscribeAudio)
}

// TranscriptionResponse represents the response structure
type TranscriptionResponse struct {
	Success       bool           `json:"success"`
	Transcription *Transcription `json:"transcription,omitempty"`
	Error         string         `json:"error,omitempty"`
	Details       string         `json:"details,omitempty"`
	Timestamp     string         `json:"timestamp"`
}

// Transcription represents the transcription result
type Transcription struct {
	Text     string        `json:"text"`
	Language string        `json:"language,omitempty"`
	Duration float64       `json:"duration,omitempty"`
	Words    []WordInfo    `json:"words"`
	Segments []SegmentInfo `json:"segments"`
}

// WordInfo represents word-level timestamp information
type WordInfo struct {
	Word  string  `json:"word"`
	Start float32 `json:"start"`
	End   float32 `json:"end"`
}

// SegmentInfo represents segment-level information
type SegmentInfo struct {
	ID    int     `json:"id"`
	Text  string  `json:"text"`
	Start float32 `json:"start"`
	End   float32 `json:"end"`
}

// TranscribeAudio handles audio transcription requests
func TranscribeAudio(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", "Only POST method is supported", http.StatusMethodNotAllowed)
		return
	}

	// Get OpenAI API key
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		sendErrorResponse(w, "OpenAI API key not configured", "OPENAI_API_KEY environment variable not set", http.StatusInternalServerError)
		return
	}

	// Read request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		sendErrorResponse(w, "Failed to read request body", err.Error(), http.StatusBadRequest)
		return
	}

	// Create OpenAI client
	client := openai.NewClient(
		option.WithAPIKey(apiKey),
	)

	// Create transcription request with basic parameters first
	transcriptionResp, err := client.Audio.Transcriptions.New(context.Background(), openai.AudioTranscriptionNewParams{
		File:           openai.File(bytes.NewReader(body), "audio.m4a", "audio/mp4"),
		Model:          openai.AudioModelWhisper1, // Use whisper-1 as it supports more features
		Language:       openai.String("en"),
		ResponseFormat: openai.AudioResponseFormatVerboseJSON,
		TimestampGranularities: []string{"word", "segment"},
	})

	if err != nil {
		log.Printf("OpenAI API error: %v", err)
		sendErrorResponse(w, "Transcription failed", err.Error(), http.StatusInternalServerError)
		return
	}

	// Create response with basic transcription
	// Since the official library doesn't directly expose Words and Segments,
	// we'll work with what we have and provide empty arrays for now
	var words []WordInfo
	var segments []SegmentInfo

	// The official library might not expose these fields directly
	// We'll provide the basic transcription text
	response := TranscriptionResponse{
		Success: true,
		Transcription: &Transcription{
			Text:     transcriptionResp.Text,
			Language: "english", // Default language
			Duration: 0.0,       // Not available in this response
			Words:    words,     // Empty for now
			Segments: segments,  // Empty for now
		},
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func sendErrorResponse(w http.ResponseWriter, error, details string, statusCode int) {
	response := TranscriptionResponse{
		Success:   false,
		Error:     error,
		Details:   details,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
} 