# langchain-config.py
# OpenRouter configuration for LangChain (Python)

import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

# Load environment variables
load_dotenv()

def get_openrouter_chat(
    model: str = None,
    temperature: float = 0.7,
    max_tokens: int = 2000,
    streaming: bool = False,
) -> ChatOpenAI:
    """
    Create a ChatOpenAI instance configured for OpenRouter.

    Args:
        model: Model ID (e.g., "anthropic/claude-4.5-sonnet")
               Defaults to OPENROUTER_MODEL env var
        temperature: Sampling temperature (0.0 to 1.0)
        max_tokens: Maximum tokens to generate
        streaming: Enable streaming responses

    Returns:
        ChatOpenAI instance configured for OpenRouter

    Common models:
        - anthropic/claude-4.5-sonnet - Best reasoning, long context
        - anthropic/claude-4.5-sonnet - Most capable, highest quality
        - meta-llama/llama-3.1-70b-instruct - Fast, cost-effective
        - openai/gpt-4-turbo - Strong general purpose
        - google/gemini-pro-1.5 - Long context, multimodal
    """
    # Get configuration from environment
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise ValueError("OPENROUTER_API_KEY environment variable not set")

    model = model or os.getenv("OPENROUTER_MODEL", "anthropic/claude-4.5-sonnet")
    base_url = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")

    # Optional: Site info for OpenRouter rankings
    site_url = os.getenv("OPENROUTER_SITE_URL", "http://localhost:3000")
    site_name = os.getenv("OPENROUTER_SITE_NAME", "My App")

    # Create ChatOpenAI instance
    llm = ChatOpenAI(
        model=model,
        openai_api_key=api_key,
        openai_api_base=base_url,
        temperature=temperature,
        max_tokens=max_tokens,
        streaming=streaming,
        # Add custom headers for OpenRouter
        default_headers={
            "HTTP-Referer": site_url,
            "X-Title": site_name,
        },
    )

    return llm


# Pre-configured instances for common models
claude_35_sonnet = get_openrouter_chat(model="anthropic/claude-4.5-sonnet")
claude_3_opus = get_openrouter_chat(model="anthropic/claude-4.5-sonnet")
gpt_4_turbo = get_openrouter_chat(model="openai/gpt-4-turbo")
llama_70b = get_openrouter_chat(model="meta-llama/llama-3.1-70b-instruct")

# Example usage:
if __name__ == "__main__":
    # Simple chat
    llm = get_openrouter_chat()
    response = llm.invoke("Say 'Hello from OpenRouter!'")
    print(response.content)

    # Streaming chat
    llm_streaming = get_openrouter_chat(streaming=True)
    for chunk in llm_streaming.stream("Count from 1 to 5"):
        print(chunk.content, end="", flush=True)
    print()
