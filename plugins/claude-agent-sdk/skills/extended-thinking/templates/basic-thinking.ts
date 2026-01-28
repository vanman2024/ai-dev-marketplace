/**
 * Extended Thinking - TypeScript Implementation
 * Enable Claude to reason deeply before responding
 */
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

interface ThinkingBlock {
  type: "thinking";
  thinking: string;
  signature?: string;
}

interface TextBlock {
  type: "text";
  text: string;
}

type ContentBlock = ThinkingBlock | TextBlock;

/**
 * Basic extended thinking request
 */
export async function basicExtendedThinking(prompt: string) {
  const response = await client.messages.create({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 16000,
    thinking: {
      type: "enabled",
      budget_tokens: 10000, // How much "thinking" to allow
    },
    messages: [{ role: "user", content: prompt }],
  });

  // Parse response - includes thinking blocks
  const thinking: string[] = [];
  let finalResponse = "";

  for (const block of response.content as ContentBlock[]) {
    if (block.type === "thinking") {
      thinking.push(block.thinking);
    } else if (block.type === "text") {
      finalResponse = block.text;
    }
  }

  return {
    thinking,
    response: finalResponse,
    usage: response.usage,
  };
}

/**
 * Extended thinking with tools (interleaved)
 */
export async function extendedThinkingWithTools(
  prompt: string,
  tools: Anthropic.Tool[]
) {
  const response = await client.messages.create(
    {
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 16000,
      thinking: {
        type: "enabled",
        budget_tokens: 10000,
      },
      tools,
      messages: [{ role: "user", content: prompt }],
    },
    {
      headers: {
        "anthropic-beta": "interleaved-thinking-2025-05-14",
      },
    }
  );

  return response;
}

/**
 * Streaming extended thinking for real-time visibility
 */
export async function streamExtendedThinking(prompt: string) {
  const stream = client.messages.stream({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 16000,
    thinking: {
      type: "enabled",
      budget_tokens: 10000,
    },
    messages: [{ role: "user", content: prompt }],
  });

  for await (const event of stream) {
    if (event.type === "content_block_start") {
      if (event.content_block.type === "thinking") {
        console.log("🧠 Thinking started...");
      }
    } else if (event.type === "content_block_delta") {
      if (event.delta.type === "thinking_delta") {
        process.stdout.write(event.delta.thinking);
      } else if (event.delta.type === "text_delta") {
        process.stdout.write(event.delta.text);
      }
    }
  }

  return stream.finalMessage();
}

// Example usage
async function main() {
  const result = await basicExtendedThinking(
    "Analyze the time complexity of merge sort and explain why it's O(n log n)"
  );

  console.log("=== Thinking Process ===");
  result.thinking.forEach((t, i) => console.log(`Step ${i + 1}:`, t));

  console.log("\n=== Final Response ===");
  console.log(result.response);
}

main().catch(console.error);
