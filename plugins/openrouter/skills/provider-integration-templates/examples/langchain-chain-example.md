# LangChain LCEL Chain Example

Complete example of building LCEL chains with LangChain and OpenRouter.

## What is LCEL?

LangChain Expression Language (LCEL) is a declarative way to compose chains using the `|` operator. Benefits:

- **Streaming**: Built-in streaming support
- **Batch**: Process multiple inputs efficiently
- **Async**: Native async/await support
- **Composition**: Chain components together easily

## Setup

### Python

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install langchain langchain-openai python-dotenv
```

### TypeScript

```bash
npm install langchain @langchain/openai dotenv
```

## Environment Variables

Create `.env`:

```bash
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_SITE_URL=https://yourapp.com
OPENROUTER_SITE_NAME=YourApp
```

## Example 1: Simple Chat Chain

### Python

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_openai import ChatOpenAI
import os
from dotenv import load_dotenv

load_dotenv()

# Configure OpenRouter
llm = ChatOpenAI(
    model=os.getenv("OPENROUTER_MODEL"),
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base=os.getenv("OPENROUTER_BASE_URL"),
    temperature=0.7,
    default_headers={
        "HTTP-Referer": os.getenv("OPENROUTER_SITE_URL"),
        "X-Title": os.getenv("OPENROUTER_SITE_NAME"),
    },
)

# Create prompt template
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    ("human", "{input}"),
])

# Create chain using LCEL
chain = prompt | llm | StrOutputParser()

# Invoke chain
response = chain.invoke({"input": "What is the capital of France?"})
print(response)
```

### TypeScript

```typescript
import { ChatPromptTemplate } from '@langchain/core/prompts';
import { StringOutputParser } from '@langchain/core/output_parsers';
import { ChatOpenAI } from '@langchain/openai';
import 'dotenv/config';

// Configure OpenRouter
const llm = new ChatOpenAI({
  modelName: process.env.OPENROUTER_MODEL!,
  openAIApiKey: process.env.OPENROUTER_API_KEY!,
  configuration: {
    baseURL: process.env.OPENROUTER_BASE_URL!,
    defaultHeaders: {
      'HTTP-Referer': process.env.OPENROUTER_SITE_URL!,
      'X-Title': process.env.OPENROUTER_SITE_NAME!,
    },
  },
  temperature: 0.7,
});

// Create prompt template
const prompt = ChatPromptTemplate.fromMessages([
  ['system', 'You are a helpful assistant.'],
  ['human', '{input}'],
]);

// Create chain using LCEL
const chain = prompt.pipe(llm).pipe(new StringOutputParser());

// Invoke chain
const response = await chain.invoke({ input: 'What is the capital of France?' });
console.log(response);
```

## Example 2: Streaming Chain

### Python

```python
# Using the same chain from Example 1

print("Streaming response:")
for chunk in chain.stream({"input": "Count from 1 to 10"}):
    print(chunk, end="", flush=True)
print()
```

### TypeScript

```typescript
// Using the same chain from Example 1

console.log('Streaming response:');
const stream = await chain.stream({ input: 'Count from 1 to 10' });

for await (const chunk of stream) {
  process.stdout.write(chunk);
}
console.log();
```

## Example 3: Batch Processing

### Python

```python
# Process multiple inputs efficiently
questions = [
    {"input": "What is 2+2?"},
    {"input": "What is the capital of Spain?"},
    {"input": "Who wrote Hamlet?"},
]

responses = chain.batch(questions)

for q, r in zip(questions, responses):
    print(f"Q: {q['input']}")
    print(f"A: {r}\n")
```

## Example 4: Chain with Multiple Steps

### Python

```python
from langchain_core.runnables import RunnableLambda

# Step 1: Extract keywords
def extract_keywords(text: str) -> dict:
    # Simple keyword extraction (in production, use NLP library)
    words = text.lower().split()
    keywords = [w for w in words if len(w) > 4]
    return {"keywords": ", ".join(keywords[:3]), "original": text}

# Step 2: Create summary prompt
summary_prompt = ChatPromptTemplate.from_messages([
    ("system", "Create a brief summary focusing on these keywords: {keywords}"),
    ("human", "{original}"),
])

# Step 3: Build multi-step chain
multi_chain = (
    RunnableLambda(extract_keywords)
    | summary_prompt
    | llm
    | StrOutputParser()
)

# Use the chain
text = "Artificial intelligence and machine learning are revolutionizing technology"
summary = multi_chain.invoke(text)
print(summary)
```

## Example 5: Parallel Chain Execution

### Python

```python
from langchain_core.runnables import RunnableParallel

# Create multiple analysis chains
sentiment_prompt = ChatPromptTemplate.from_template(
    "Analyze the sentiment (positive/negative/neutral): {text}"
)
sentiment_chain = sentiment_prompt | llm | StrOutputParser()

summary_prompt = ChatPromptTemplate.from_template(
    "Summarize in one sentence: {text}"
)
summary_chain = summary_prompt | llm | StrOutputParser()

# Run chains in parallel
parallel_chain = RunnableParallel(
    sentiment=sentiment_chain,
    summary=summary_chain,
)

result = parallel_chain.invoke({
    "text": "I absolutely love this product! It exceeded all my expectations."
})

print(f"Sentiment: {result['sentiment']}")
print(f"Summary: {result['summary']}")
```

## Example 6: Conditional Chain

### Python

```python
from langchain_core.runnables import RunnableBranch

# Define different response strategies
formal_prompt = ChatPromptTemplate.from_template(
    "Respond formally and professionally: {question}"
)
casual_prompt = ChatPromptTemplate.from_template(
    "Respond casually and friendly: {question}"
)

formal_chain = formal_prompt | llm | StrOutputParser()
casual_chain = casual_prompt | llm | StrOutputParser()

# Create branching logic
def is_formal(data: dict) -> bool:
    return "formal" in data.get("tone", "").lower()

conditional_chain = RunnableBranch(
    (is_formal, formal_chain),
    casual_chain,  # Default
)

# Test both paths
print("Formal:")
print(conditional_chain.invoke({
    "tone": "formal",
    "question": "How are you?"
}))

print("\nCasual:")
print(conditional_chain.invoke({
    "tone": "casual",
    "question": "How are you?"
}))
```

## Advanced: Chain with Fallback

### Python

```python
# Configure primary and fallback models
primary_llm = ChatOpenAI(
    model="anthropic/claude-4.5-sonnet",
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base=os.getenv("OPENROUTER_BASE_URL"),
)

fallback_llm = ChatOpenAI(
    model="meta-llama/llama-3.1-70b-instruct",
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base=os.getenv("OPENROUTER_BASE_URL"),
)

# Chain with fallback
chain_with_fallback = (
    prompt
    | primary_llm.with_fallbacks([fallback_llm])
    | StrOutputParser()
)

response = chain_with_fallback.invoke({"input": "Hello!"})
print(response)
```

## Best Practices

1. **Use LCEL for Composition**: Cleaner than manual function chaining
2. **Enable Streaming**: Better UX for long responses
3. **Batch When Possible**: More efficient than sequential processing
4. **Add Error Handling**: Use fallbacks and retries
5. **Cache Expensive Calls**: Reduce API costs
6. **Monitor Token Usage**: Track costs with OpenRouter dashboard

## Next Steps

- Add memory to chains (see LangChain memory docs)
- Implement RAG with vector stores
- Build agents with tools (see `langchain-agent-example.md`)
- Deploy chains as REST APIs
