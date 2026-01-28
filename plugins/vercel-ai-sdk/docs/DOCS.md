# AI SDK Documentation - Complete Reference

> **Source**: https://ai-sdk.dev/docs
> **Version**: AI SDK 6 (Latest)
> **Generated**: January 2026

---

## 📚 Table of Contents

1. [Introduction](#introduction)
2. [Foundations](#foundations)
3. [Getting Started](#getting-started)
4. [Agents](#agents)
5. [AI SDK Core](#ai-sdk-core)
6. [AI SDK UI](#ai-sdk-ui)
7. [AI SDK RSC](#ai-sdk-rsc)
8. [Advanced Topics](#advanced-topics)
9. [API Reference - Core](#api-reference---core)
10. [API Reference - UI](#api-reference---ui)
11. [API Reference - RSC](#api-reference---rsc)
12. [API Reference - Errors](#api-reference---errors)
13. [Migration Guides](#migration-guides)
14. [Troubleshooting](#troubleshooting)

---

## Introduction

| Page                          | URL                                  |
| ----------------------------- | ------------------------------------ |
| Introduction                  | https://ai-sdk.dev/docs/introduction |
| llms.txt (Full docs for LLMs) | https://ai-sdk.dev/llms.txt          |

---

## Foundations

| Page                 | URL                                                      | Description             |
| -------------------- | -------------------------------------------------------- | ----------------------- |
| Foundations Overview | https://ai-sdk.dev/docs/foundations                      | Core concepts           |
| Overview             | https://ai-sdk.dev/docs/foundations/overview             | High-level overview     |
| Providers and Models | https://ai-sdk.dev/docs/foundations/providers-and-models | Understanding providers |
| Prompts              | https://ai-sdk.dev/docs/foundations/prompts              | Prompt formats          |
| Tools                | https://ai-sdk.dev/docs/foundations/tools                | Tool calling concepts   |
| Streaming            | https://ai-sdk.dev/docs/foundations/streaming            | Streaming responses     |

---

## Getting Started

| Page                     | URL                                                            | Description          |
| ------------------------ | -------------------------------------------------------------- | -------------------- |
| Getting Started Overview | https://ai-sdk.dev/docs/getting-started                        | Quick start guide    |
| Choosing a Provider      | https://ai-sdk.dev/docs/getting-started/choosing-a-provider    | Provider selection   |
| Navigating the Library   | https://ai-sdk.dev/docs/getting-started/navigating-the-library | Library structure    |
| Next.js App Router       | https://ai-sdk.dev/docs/getting-started/nextjs-app-router      | App Router setup     |
| Next.js Pages Router     | https://ai-sdk.dev/docs/getting-started/nextjs-pages-router    | Pages Router setup   |
| Svelte                   | https://ai-sdk.dev/docs/getting-started/svelte                 | Svelte integration   |
| Vue.js (Nuxt)            | https://ai-sdk.dev/docs/getting-started/nuxt                   | Nuxt integration     |
| Node.js                  | https://ai-sdk.dev/docs/getting-started/nodejs                 | Node.js setup        |
| Expo                     | https://ai-sdk.dev/docs/getting-started/expo                   | React Native Expo    |
| TanStack Start           | https://ai-sdk.dev/docs/getting-started/tanstack-start         | TanStack integration |

---

## Agents

| Page                     | URL                                                     | Description         |
| ------------------------ | ------------------------------------------------------- | ------------------- |
| Agents Overview          | https://ai-sdk.dev/docs/agents                          | Agents introduction |
| Overview                 | https://ai-sdk.dev/docs/agents/overview                 | Agent concepts      |
| Building Agents          | https://ai-sdk.dev/docs/agents/building-agents          | Building agents     |
| Workflow Patterns        | https://ai-sdk.dev/docs/agents/workflows                | Agent workflows     |
| Loop Control             | https://ai-sdk.dev/docs/agents/loop-control             | Controlling loops   |
| Configuring Call Options | https://ai-sdk.dev/docs/agents/configuring-call-options | Call configuration  |

---

## AI SDK Core

| Page                         | URL                                                            | Description            |
| ---------------------------- | -------------------------------------------------------------- | ---------------------- |
| AI SDK Core Overview         | https://ai-sdk.dev/docs/ai-sdk-core                            | Core package overview  |
| Overview                     | https://ai-sdk.dev/docs/ai-sdk-core/overview                   | Core concepts          |
| Generating Text              | https://ai-sdk.dev/docs/ai-sdk-core/generating-text            | generateText()         |
| Generating Structured Data   | https://ai-sdk.dev/docs/ai-sdk-core/generating-structured-data | generateObject()       |
| Tool Calling                 | https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling     | Tools and tool calling |
| Model Context Protocol (MCP) | https://ai-sdk.dev/docs/ai-sdk-core/mcp-tools                  | MCP integration        |
| Prompt Engineering           | https://ai-sdk.dev/docs/ai-sdk-core/prompt-engineering         | Prompt tips            |
| Settings                     | https://ai-sdk.dev/docs/ai-sdk-core/settings                   | Configuration settings |
| Embeddings                   | https://ai-sdk.dev/docs/ai-sdk-core/embeddings                 | Vector embeddings      |
| Reranking                    | https://ai-sdk.dev/docs/ai-sdk-core/reranking                  | Reranking results      |
| Image Generation             | https://ai-sdk.dev/docs/ai-sdk-core/image-generation           | generateImage()        |
| Transcription                | https://ai-sdk.dev/docs/ai-sdk-core/transcription              | Audio transcription    |
| Speech                       | https://ai-sdk.dev/docs/ai-sdk-core/speech                     | Text-to-speech         |
| Language Model Middleware    | https://ai-sdk.dev/docs/ai-sdk-core/middleware                 | Middleware patterns    |
| Provider & Model Management  | https://ai-sdk.dev/docs/ai-sdk-core/provider-management        | Managing providers     |
| Error Handling               | https://ai-sdk.dev/docs/ai-sdk-core/error-handling             | Error handling         |
| Testing                      | https://ai-sdk.dev/docs/ai-sdk-core/testing                    | Testing strategies     |
| Telemetry                    | https://ai-sdk.dev/docs/ai-sdk-core/telemetry                  | Observability          |
| DevTools                     | https://ai-sdk.dev/docs/ai-sdk-core/devtools                   | Developer tools        |

---

## AI SDK UI

| Page                        | URL                                                           | Description           |
| --------------------------- | ------------------------------------------------------------- | --------------------- |
| AI SDK UI Overview          | https://ai-sdk.dev/docs/ai-sdk-ui                             | UI package overview   |
| Overview                    | https://ai-sdk.dev/docs/ai-sdk-ui/overview                    | UI concepts           |
| Chatbot                     | https://ai-sdk.dev/docs/ai-sdk-ui/chatbot                     | Building chatbots     |
| Chatbot Message Persistence | https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-message-persistence | Message storage       |
| Chatbot Resume Streams      | https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams      | Resumable streams     |
| Chatbot Tool Usage          | https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-tool-usage          | Tools in chatbots     |
| Generative User Interfaces  | https://ai-sdk.dev/docs/ai-sdk-ui/generative-user-interfaces  | Generative UI         |
| Completion                  | https://ai-sdk.dev/docs/ai-sdk-ui/completion                  | useCompletion()       |
| Object Generation           | https://ai-sdk.dev/docs/ai-sdk-ui/object-generation           | useObject()           |
| Streaming Custom Data       | https://ai-sdk.dev/docs/ai-sdk-ui/streaming-data              | Custom data streaming |
| Error Handling              | https://ai-sdk.dev/docs/ai-sdk-ui/error-handling              | UI error handling     |
| Transport                   | https://ai-sdk.dev/docs/ai-sdk-ui/transport                   | Transport layer       |
| Reading UIMessage Streams   | https://ai-sdk.dev/docs/ai-sdk-ui/reading-ui-message-streams  | Reading streams       |
| Message Metadata            | https://ai-sdk.dev/docs/ai-sdk-ui/message-metadata            | Message metadata      |
| Stream Protocols            | https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol             | Stream protocols      |

---

## AI SDK RSC

| Page                          | URL                                                            | Description          |
| ----------------------------- | -------------------------------------------------------------- | -------------------- |
| AI SDK RSC Overview           | https://ai-sdk.dev/docs/ai-sdk-rsc                             | RSC package overview |
| Overview                      | https://ai-sdk.dev/docs/ai-sdk-rsc/overview                    | RSC concepts         |
| Streaming React Components    | https://ai-sdk.dev/docs/ai-sdk-rsc/streaming-react-components  | Component streaming  |
| Generative UI                 | https://ai-sdk.dev/docs/ai-sdk-rsc/generative-ui               | Gen UI with RSC      |
| Multistep Interfaces          | https://ai-sdk.dev/docs/ai-sdk-rsc/multistep-interfaces        | Multi-step flows     |
| Saving and Restoring States   | https://ai-sdk.dev/docs/ai-sdk-rsc/saving-and-restoring-states | State management     |
| AI/UI States                  | https://ai-sdk.dev/docs/ai-sdk-rsc/ai-ui-states                | AI and UI states     |
| AI SDK RSC Utilities          | https://ai-sdk.dev/docs/ai-sdk-rsc/ai-sdk-rsc-utilities        | Utility functions    |
| Nested Streamable UIs         | https://ai-sdk.dev/docs/ai-sdk-rsc/nested-streamable-uis       | Nested UIs           |
| Server Actions Best Practices | https://ai-sdk.dev/docs/ai-sdk-rsc/server-actions              | Server actions       |
| Error Handling                | https://ai-sdk.dev/docs/ai-sdk-rsc/error-handling              | RSC error handling   |

---

## Advanced Topics

| Page                           | URL                                                             | Description            |
| ------------------------------ | --------------------------------------------------------------- | ---------------------- |
| Advanced Overview              | https://ai-sdk.dev/docs/advanced                                | Advanced topics        |
| Custom Provider                | https://ai-sdk.dev/docs/advanced/custom-provider                | Build custom providers |
| Custom Router                  | https://ai-sdk.dev/docs/advanced/custom-router                  | Custom model routing   |
| Streaming Files                | https://ai-sdk.dev/docs/advanced/streaming-files                | File streaming         |
| RAG with Sources               | https://ai-sdk.dev/docs/advanced/rag-with-sources               | RAG implementation     |
| Retrieval Augmented Generation | https://ai-sdk.dev/docs/advanced/retrieval-augmented-generation | RAG patterns           |
| Prompt Caching                 | https://ai-sdk.dev/docs/advanced/prompt-caching                 | Caching strategies     |
| Tool Policies                  | https://ai-sdk.dev/docs/advanced/tool-policies                  | Tool access control    |
| Computer Use Agent             | https://ai-sdk.dev/docs/advanced/computer-use-agent             | Computer use           |
| Content Moderation             | https://ai-sdk.dev/docs/advanced/content-moderation             | Safety filters         |
| Response Interception          | https://ai-sdk.dev/docs/advanced/response-interception          | Intercepting responses |
| Best Practices                 | https://ai-sdk.dev/docs/advanced/best-practices                 | Best practices         |

---

## API Reference - Core

| Function                       | URL                                                                              | Description        |
| ------------------------------ | -------------------------------------------------------------------------------- | ------------------ |
| generateText                   | https://ai-sdk.dev/docs/reference/ai-sdk-core/generate-text                      | Generate text      |
| streamText                     | https://ai-sdk.dev/docs/reference/ai-sdk-core/stream-text                        | Stream text        |
| generateObject                 | https://ai-sdk.dev/docs/reference/ai-sdk-core/generate-object                    | Generate object    |
| streamObject                   | https://ai-sdk.dev/docs/reference/ai-sdk-core/stream-object                      | Stream object      |
| embed                          | https://ai-sdk.dev/docs/reference/ai-sdk-core/embed                              | Create embeddings  |
| embedMany                      | https://ai-sdk.dev/docs/reference/ai-sdk-core/embed-many                         | Batch embeddings   |
| rerank                         | https://ai-sdk.dev/docs/reference/ai-sdk-core/rerank                             | Rerank documents   |
| generateImage                  | https://ai-sdk.dev/docs/reference/ai-sdk-core/generate-image                     | Generate images    |
| transcribe                     | https://ai-sdk.dev/docs/reference/ai-sdk-core/transcribe                         | Transcribe audio   |
| generateSpeech                 | https://ai-sdk.dev/docs/reference/ai-sdk-core/generate-speech                    | Generate speech    |
| tool                           | https://ai-sdk.dev/docs/reference/ai-sdk-core/tool                               | Define tools       |
| mcpClient                      | https://ai-sdk.dev/docs/reference/ai-sdk-core/mcp-client                         | MCP client         |
| mcpServer                      | https://ai-sdk.dev/docs/reference/ai-sdk-core/mcp-server                         | MCP server         |
| CoreTool                       | https://ai-sdk.dev/docs/reference/ai-sdk-core/core-tool                          | Tool type          |
| DataStream                     | https://ai-sdk.dev/docs/reference/ai-sdk-core/data-stream                        | Data streaming     |
| createDataStream               | https://ai-sdk.dev/docs/reference/ai-sdk-core/create-data-stream                 | Create stream      |
| createDataStreamResponse       | https://ai-sdk.dev/docs/reference/ai-sdk-core/create-data-stream-response        | Stream response    |
| pipeDataStreamToResponse       | https://ai-sdk.dev/docs/reference/ai-sdk-core/pipe-data-stream-to-response       | Pipe to response   |
| mergeStreams                   | https://ai-sdk.dev/docs/reference/ai-sdk-core/merge-streams                      | Merge streams      |
| appendResponseMessages         | https://ai-sdk.dev/docs/reference/ai-sdk-core/append-response-messages           | Append messages    |
| ToolExecutionOptions           | https://ai-sdk.dev/docs/reference/ai-sdk-core/tool-execution-options             | Tool options       |
| Output                         | https://ai-sdk.dev/docs/reference/ai-sdk-core/output                             | Output type        |
| ModelMessage                   | https://ai-sdk.dev/docs/reference/ai-sdk-core/model-message                      | Message type       |
| UIMessage                      | https://ai-sdk.dev/docs/reference/ai-sdk-core/ui-message                         | UI message type    |
| validateUIMessages             | https://ai-sdk.dev/docs/reference/ai-sdk-core/validate-ui-messages               | Validate messages  |
| safeValidateUIMessages         | https://ai-sdk.dev/docs/reference/ai-sdk-core/safe-validate-ui-messages          | Safe validation    |
| createProviderRegistry         | https://ai-sdk.dev/docs/reference/ai-sdk-core/provider-registry                  | Provider registry  |
| customProvider                 | https://ai-sdk.dev/docs/reference/ai-sdk-core/custom-provider                    | Custom provider    |
| cosineSimilarity               | https://ai-sdk.dev/docs/reference/ai-sdk-core/cosine-similarity                  | Cosine similarity  |
| wrapLanguageModel              | https://ai-sdk.dev/docs/reference/ai-sdk-core/wrap-language-model                | Wrap model         |
| wrapImageModel                 | https://ai-sdk.dev/docs/reference/ai-sdk-core/wrap-image-model                   | Wrap image model   |
| LanguageModelV3Middleware      | https://ai-sdk.dev/docs/reference/ai-sdk-core/language-model-v2-middleware       | Middleware         |
| extractReasoningMiddleware     | https://ai-sdk.dev/docs/reference/ai-sdk-core/extract-reasoning-middleware       | Extract reasoning  |
| simulateStreamingMiddleware    | https://ai-sdk.dev/docs/reference/ai-sdk-core/simulate-streaming-middleware      | Simulate streaming |
| defaultSettingsMiddleware      | https://ai-sdk.dev/docs/reference/ai-sdk-core/default-settings-middleware        | Default settings   |
| addToolInputExamplesMiddleware | https://ai-sdk.dev/docs/reference/ai-sdk-core/add-tool-input-examples-middleware | Tool examples      |
| extractJsonMiddleware          | https://ai-sdk.dev/docs/reference/ai-sdk-core/extract-json-middleware            | Extract JSON       |
| stepCountIs                    | https://ai-sdk.dev/docs/reference/ai-sdk-core/step-count-is                      | Step count         |
| hasToolCall                    | https://ai-sdk.dev/docs/reference/ai-sdk-core/has-tool-call                      | Check tool call    |
| simulateReadableStream         | https://ai-sdk.dev/docs/reference/ai-sdk-core/simulate-readable-stream           | Simulate stream    |
| smoothStream                   | https://ai-sdk.dev/docs/reference/ai-sdk-core/smooth-stream                      | Smooth stream      |
| generateId                     | https://ai-sdk.dev/docs/reference/ai-sdk-core/generate-id                        | Generate ID        |
| createIdGenerator              | https://ai-sdk.dev/docs/reference/ai-sdk-core/create-id-generator                | ID generator       |

---

## API Reference - UI

| Hook/Function                 | URL                                                                            | Description      |
| ----------------------------- | ------------------------------------------------------------------------------ | ---------------- |
| useChat                       | https://ai-sdk.dev/docs/reference/ai-sdk-ui/use-chat                           | Chat hook        |
| useCompletion                 | https://ai-sdk.dev/docs/reference/ai-sdk-ui/use-completion                     | Completion hook  |
| useObject                     | https://ai-sdk.dev/docs/reference/ai-sdk-ui/use-object                         | Object hook      |
| convertToModelMessages        | https://ai-sdk.dev/docs/reference/ai-sdk-ui/convert-to-model-messages          | Convert messages |
| pruneMessages                 | https://ai-sdk.dev/docs/reference/ai-sdk-ui/prune-messages                     | Prune messages   |
| createUIMessageStream         | https://ai-sdk.dev/docs/reference/ai-sdk-ui/create-ui-message-stream           | Create UI stream |
| createUIMessageStreamResponse | https://ai-sdk.dev/docs/reference/ai-sdk-ui/create-ui-message-stream-response  | Stream response  |
| pipeUIMessageStreamToResponse | https://ai-sdk.dev/docs/reference/ai-sdk-ui/pipe-ui-message-stream-to-response | Pipe to response |
| readUIMessageStream           | https://ai-sdk.dev/docs/reference/ai-sdk-ui/read-ui-message-stream             | Read stream      |
| InferUITools                  | https://ai-sdk.dev/docs/reference/ai-sdk-ui/infer-ui-tools                     | Infer tools      |
| InferUITool                   | https://ai-sdk.dev/docs/reference/ai-sdk-ui/infer-ui-tool                      | Infer tool       |
| DirectChatTransport           | https://ai-sdk.dev/docs/reference/ai-sdk-ui/direct-chat-transport              | Direct transport |

---

## API Reference - RSC

| Function/Hook         | URL                                                                  | Description       |
| --------------------- | -------------------------------------------------------------------- | ----------------- |
| streamUI              | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/stream-ui               | Stream UI         |
| createAI              | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/create-ai               | Create AI context |
| createStreamableUI    | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/create-streamable-ui    | Streamable UI     |
| createStreamableValue | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/create-streamable-value | Streamable value  |
| readStreamableValue   | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/read-streamable-value   | Read value        |
| getAIState            | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/get-ai-state            | Get AI state      |
| getMutableAIState     | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/get-mutable-ai-state    | Mutable state     |
| useAIState            | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/use-ai-state            | AI state hook     |
| useActions            | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/use-actions             | Actions hook      |
| useUIState            | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/use-ui-state            | UI state hook     |
| useStreamableValue    | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/use-streamable-value    | Streamable hook   |
| render (Removed)      | https://ai-sdk.dev/docs/reference/ai-sdk-rsc/render                  | Legacy render     |

---

## API Reference - Errors

| Error Type                            | URL                                                                                         |
| ------------------------------------- | ------------------------------------------------------------------------------------------- |
| AI_APICallError                       | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-api-call-error                           |
| AI_DownloadError                      | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-download-error                           |
| AI_EmptyResponseBodyError             | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-empty-response-body-error                |
| AI_InvalidArgumentError               | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-invalid-argument-error                   |
| AI_InvalidDataContentError            | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-invalid-data-content-error               |
| AI_InvalidMessageRoleError            | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-invalid-message-role-error               |
| AI_InvalidPromptError                 | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-invalid-prompt-error                     |
| AI_InvalidResponseDataError           | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-invalid-response-data-error              |
| AI_InvalidToolApprovalError           | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-invalid-tool-approval-error              |
| AI_InvalidToolInputError              | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-invalid-tool-input-error                 |
| AI_JSONParseError                     | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-json-parse-error                         |
| AI_LoadAPIKeyError                    | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-load-api-key-error                       |
| AI_LoadSettingError                   | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-load-setting-error                       |
| AI_MessageConversionError             | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-message-conversion-error                 |
| AI_NoContentGeneratedError            | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-content-generated-error               |
| AI_NoImageGeneratedError              | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-image-generated-error                 |
| AI_NoObjectGeneratedError             | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-object-generated-error                |
| AI_NoOutputGeneratedError             | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-output-generated-error                |
| AI_NoSpeechGeneratedError             | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-speech-generated-error                |
| AI_NoSuchModelError                   | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-such-model-error                      |
| AI_NoSuchProviderError                | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-such-provider-error                   |
| AI_NoSuchToolError                    | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-such-tool-error                       |
| AI_NoTranscriptGeneratedError         | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-no-transcript-generated-error            |
| AI_RetryError                         | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-retry-error                              |
| AI_TooManyEmbeddingValuesForCallError | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-too-many-embedding-values-for-call-error |
| AI_ToolCallNotFoundForApprovalError   | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-tool-call-not-found-for-approval-error   |
| ToolCallRepairError                   | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-tool-call-repair-error                   |
| AI_TypeValidationError                | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-type-validation-error                    |
| AI_UIMessageStreamError               | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-ui-message-stream-error                  |
| AI_UnsupportedFunctionalityError      | https://ai-sdk.dev/docs/reference/ai-sdk-errors/ai-unsupported-functionality-error          |

---

## Migration Guides

| Page                            | URL                                                               | Description        |
| ------------------------------- | ----------------------------------------------------------------- | ------------------ |
| Migration Guides Overview       | https://ai-sdk.dev/docs/migration-guides                          | Migration overview |
| Versioning                      | https://ai-sdk.dev/docs/migration-guides/versioning               | Version policy     |
| Migrate AI SDK 5.x to 6.0       | https://ai-sdk.dev/docs/migration-guides/migration-guide-6-0      | v5 → v6            |
| Migrate Your Data to AI SDK 5.0 | https://ai-sdk.dev/docs/migration-guides/migration-guide-5-0-data | Data migration     |
| Migrate AI SDK 4.x to 5.0       | https://ai-sdk.dev/docs/migration-guides/migration-guide-5-0      | v4 → v5            |
| Migrate AI SDK 4.1 to 4.2       | https://ai-sdk.dev/docs/migration-guides/migration-guide-4-2      | v4.1 → v4.2        |
| Migrate AI SDK 4.0 to 4.1       | https://ai-sdk.dev/docs/migration-guides/migration-guide-4-1      | v4.0 → v4.1        |
| Migrate AI SDK 3.4 to 4.0       | https://ai-sdk.dev/docs/migration-guides/migration-guide-4-0      | v3.4 → v4.0        |
| Migrate AI SDK 3.3 to 3.4       | https://ai-sdk.dev/docs/migration-guides/migration-guide-3-4      | v3.3 → v3.4        |
| Migrate AI SDK 3.2 to 3.3       | https://ai-sdk.dev/docs/migration-guides/migration-guide-3-3      | v3.2 → v3.3        |
| Migrate AI SDK 3.1 to 3.2       | https://ai-sdk.dev/docs/migration-guides/migration-guide-3-2      | v3.1 → v3.2        |
| Migrate AI SDK 3.0 to 3.1       | https://ai-sdk.dev/docs/migration-guides/migration-guide-3-1      | v3.0 → v3.1        |

---

## Troubleshooting

| Issue                                              | URL                                                                          |
| -------------------------------------------------- | ---------------------------------------------------------------------------- |
| Troubleshooting Overview                           | https://ai-sdk.dev/docs/troubleshooting                                      |
| Azure OpenAI Slow to Stream                        | https://ai-sdk.dev/docs/troubleshooting/azure-stream-slow                    |
| Server Actions in Client Components                | https://ai-sdk.dev/docs/troubleshooting/server-actions-in-client-components  |
| useChat/useCompletion stream output contains 0:... | https://ai-sdk.dev/docs/troubleshooting/strange-stream-output                |
| Streamable UI Errors                               | https://ai-sdk.dev/docs/troubleshooting/streamable-ui-errors                 |
| Tool Invocation Missing Result Error               | https://ai-sdk.dev/docs/troubleshooting/tool-invocation-missing-result       |
| Streaming Not Working When Deployed                | https://ai-sdk.dev/docs/troubleshooting/streaming-not-working-when-deployed  |
| Streaming Not Working When Proxied                 | https://ai-sdk.dev/docs/troubleshooting/streaming-not-working-when-proxied   |
| Getting Timeouts When Deploying on Vercel          | https://ai-sdk.dev/docs/troubleshooting/timeout-on-vercel                    |
| Unclosed Streams                                   | https://ai-sdk.dev/docs/troubleshooting/unclosed-streams                     |
| useChat Failed to Parse Stream                     | https://ai-sdk.dev/docs/troubleshooting/use-chat-failed-to-parse-stream      |
| Server Action Plain Objects Error                  | https://ai-sdk.dev/docs/troubleshooting/client-stream-error                  |
| useChat No Response                                | https://ai-sdk.dev/docs/troubleshooting/use-chat-tools-no-response           |
| Custom headers, body, credentials not working      | https://ai-sdk.dev/docs/troubleshooting/use-chat-custom-request-options      |
| TypeScript performance issues with Zod             | https://ai-sdk.dev/docs/troubleshooting/typescript-performance-zod           |
| useChat "An error occurred"                        | https://ai-sdk.dev/docs/troubleshooting/use-chat-an-error-occurred           |
| Repeated assistant messages in useChat             | https://ai-sdk.dev/docs/troubleshooting/repeated-assistant-messages          |
| onFinish not called when stream is aborted         | https://ai-sdk.dev/docs/troubleshooting/stream-abort-handling                |
| Tool calling with generateObject/streamObject      | https://ai-sdk.dev/docs/troubleshooting/tool-calling-with-structured-outputs |
| Abort breaks resumable streams                     | https://ai-sdk.dev/docs/troubleshooting/abort-breaks-resumable-streams       |
| streamText fails silently                          | https://ai-sdk.dev/docs/troubleshooting/stream-text-not-working              |
| Streaming Status Shows But No Text Appears         | https://ai-sdk.dev/docs/troubleshooting/streaming-status-delay               |
| Stale body values with useChat                     | https://ai-sdk.dev/docs/troubleshooting/use-chat-stale-body-data             |
| Type Error with onToolCall                         | https://ai-sdk.dev/docs/troubleshooting/ontoolcall-type-narrowing            |
| Unsupported model version error                    | https://ai-sdk.dev/docs/troubleshooting/unsupported-model-version            |
| Object generation failed with OpenAI               | https://ai-sdk.dev/docs/troubleshooting/no-object-generated-content-filter   |
| Missing Tool Results Error                         | https://ai-sdk.dev/docs/troubleshooting/missing-tool-results-error           |
| Model is not assignable to type "LanguageModelV1"  | https://ai-sdk.dev/docs/troubleshooting/model-is-not-assignable-to-type      |
| TypeScript error "Cannot find namespace 'JSX'"     | https://ai-sdk.dev/docs/troubleshooting/typescript-cannot-find-namespace-jsx |
| React error "Maximum update depth exceeded"        | https://ai-sdk.dev/docs/troubleshooting/react-maximum-update-depth-exceeded  |
| Jest: cannot find module '@ai-sdk/rsc'             | https://ai-sdk.dev/docs/troubleshooting/jest-cannot-find-module-ai-rsc       |

---

## Summary

| Section                | Count   |
| ---------------------- | ------- |
| Foundations            | 6       |
| Getting Started        | 10      |
| Agents                 | 6       |
| AI SDK Core            | 19      |
| AI SDK UI              | 15      |
| AI SDK RSC             | 11      |
| Advanced Topics        | 12      |
| API Reference - Core   | 43      |
| API Reference - UI     | 12      |
| API Reference - RSC    | 12      |
| API Reference - Errors | 30      |
| Migration Guides       | 12      |
| Troubleshooting        | 31      |
| **Total**              | **219** |

---

_This document was auto-generated by scraping AI SDK Documentation at https://ai-sdk.dev/docs_
