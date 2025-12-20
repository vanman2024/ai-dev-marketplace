/**
 * A2A Protocol C# SDK - Basic Usage Example
 * Demonstrates basic client setup and API operations
 */

using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using A2A.Protocol;
using A2A.Protocol.Models;
using A2A.Protocol.Exceptions;

namespace A2AExample
{
    class BasicExample
    {
        static async Task<int> Main(string[] args)
        {
            // Load API key from environment
            var apiKey = Environment.GetEnvironmentVariable("A2A_API_KEY");
            if (string.IsNullOrEmpty(apiKey))
            {
                Console.Error.WriteLine("A2A_API_KEY environment variable is required");
                return 1;
            }

            // Initialize client
            var client = new A2AClient(new A2AClientOptions
            {
                ApiKey = apiKey,
                BaseUrl = Environment.GetEnvironmentVariable("A2A_BASE_URL")
                    ?? "https://api.a2a.example.com",
                Timeout = TimeSpan.FromSeconds(30),
                RetryAttempts = 3
            });

            try
            {
                // Example: Send a message to another agent
                var message = new Dictionary<string, object>
                {
                    ["type"] = "request",
                    ["action"] = "process_data",
                    ["data"] = new Dictionary<string, object>
                    {
                        ["input"] = "sample data"
                    }
                };

                var response = await client.SendMessageAsync(
                    recipientId: "agent-123",
                    message: message
                );

                Console.WriteLine("Message sent successfully!");
                Console.WriteLine($"Response: {response}");

                // Example: Get agent status
                var status = await client.GetAgentStatusAsync("agent-123");
                Console.WriteLine($"\nAgent status: {status}");

                // Example: List available agents
                var agents = await client.ListAgentsAsync(limit: 10);
                Console.WriteLine("\nAvailable agents:");
                foreach (var agent in agents)
                {
                    Console.WriteLine($"  - {agent.Id}: {agent.Name} ({agent.Status})");
                }

                return 0;
            }
            catch (A2AException ex)
            {
                Console.Error.WriteLine($"A2A Error: {ex.Message}");
                Console.Error.WriteLine($"Error code: {ex.ErrorCode}");
                return 1;
            }
            finally
            {
                // Clean up resources
                client.Dispose();
            }
        }
    }
}
