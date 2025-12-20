/**
 * A2A Protocol Go SDK - Basic Usage Example
 * Demonstrates basic client setup and API operations
 */

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/a2a/protocol-go"
)

func main() {
	// Load API key from environment
	apiKey := os.Getenv("A2A_API_KEY")
	if apiKey == "" {
		log.Fatal("A2A_API_KEY environment variable is required")
	}

	baseURL := os.Getenv("A2A_BASE_URL")
	if baseURL == "" {
		baseURL = "https://api.a2a.example.com"
	}

	// Initialize client
	client, err := a2a.NewClient(&a2a.ClientOptions{
		APIKey:        apiKey,
		BaseURL:       baseURL,
		Timeout:       30 * time.Second,
		RetryAttempts: 3,
	})
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Example: Send a message to another agent
	message := map[string]interface{}{
		"type":   "request",
		"action": "process_data",
		"data": map[string]interface{}{
			"input": "sample data",
		},
	}

	response, err := client.SendMessage(ctx, &a2a.SendMessageRequest{
		RecipientID: "agent-123",
		Message:     message,
	})
	if err != nil {
		log.Fatalf("Failed to send message: %v", err)
	}

	fmt.Println("Message sent successfully!")
	fmt.Printf("Response: %+v\n", response)

	// Example: Get agent status
	status, err := client.GetAgentStatus(ctx, "agent-123")
	if err != nil {
		log.Fatalf("Failed to get agent status: %v", err)
	}
	fmt.Printf("\nAgent status: %+v\n", status)

	// Example: List available agents
	agents, err := client.ListAgents(ctx, &a2a.ListAgentsRequest{
		Limit: 10,
	})
	if err != nil {
		log.Fatalf("Failed to list agents: %v", err)
	}

	fmt.Println("\nAvailable agents:")
	for _, agent := range agents {
		fmt.Printf("  - %s: %s (%s)\n", agent.ID, agent.Name, agent.Status)
	}
}
