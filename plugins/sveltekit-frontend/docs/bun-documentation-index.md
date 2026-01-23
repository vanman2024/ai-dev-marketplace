# Bun Documentation - Comprehensive Link Index

> Generated from: https://bun.com/docs/guides + https://bun.com/docs + /docs/test (Deep crawl)
> Date: January 5, 2026
> Total Unique Links: 300+

---

## Core Documentation

- [Runtime](https://bun.com/docs)
- [Bundler](https://bun.com/docs/bundler)
- [Package Manager](https://bun.com/docs/pm/cli/install)
- [Test Runner](https://bun.com/docs/test)
- [Guides](https://bun.com/docs/guides)
- [Feedback](https://bun.com/docs/feedback)
- [Reference](https://bun.com/reference)

---

## Runtime Documentation

### Getting Started with bun run

- [Installation](https://bun.com/docs/installation)
- [Quickstart](https://bun.com/docs/quickstart)
- [TypeScript Support](https://bun.com/docs/typescript)
- [bun init - Initialize a new project](https://bun.com/docs/runtime/templating/init)
- [bun create - Create from templates](https://bun.com/docs/runtime/templating/create)
- [Watch Mode](https://bun.com/docs/runtime/watch-mode)

### Runtime Core

- [File Types](https://bun.com/docs/runtime/file-types)
- [Module Resolution](https://bun.com/docs/runtime/module-resolution)
- [JSX](https://bun.com/docs/runtime/jsx)
- [Auto-install](https://bun.com/docs/runtime/auto-install)
- [Transpiler](https://bun.com/docs/runtime/transpiler)
- [Plugins](https://bun.com/docs/runtime/plugins)
- [bunfig.toml Configuration](https://bun.com/docs/runtime/bunfig)
- [Node.js Compatibility](https://bun.com/docs/runtime/nodejs-compat)

### HTTP & Networking

- [Server](https://bun.com/docs/runtime/http/server)
- [Routing](https://bun.com/docs/runtime/http/routing)
- [Cookies](https://bun.com/docs/runtime/http/cookies)
- [TLS/SSL](https://bun.com/docs/runtime/http/tls)
- [Error Handling](https://bun.com/docs/runtime/http/error-handling)
- [Metrics](https://bun.com/docs/runtime/http/metrics)
- [WebSockets](https://bun.com/docs/runtime/http/websockets)
- [Fetch API](https://bun.com/docs/runtime/networking/fetch)
- [TCP](https://bun.com/docs/runtime/networking/tcp)
- [UDP](https://bun.com/docs/runtime/networking/udp)
- [DNS](https://bun.com/docs/runtime/networking/dns)
- [File System Router](https://bun.com/docs/runtime/file-system-router)

### File I/O & Streams

- [File I/O](https://bun.com/docs/runtime/file-io)
- [Streams](https://bun.com/docs/runtime/streams)
- [Binary Data](https://bun.com/docs/runtime/binary-data)

### Data & Databases

- [SQL](https://bun.com/docs/runtime/sql)
- [SQLite](https://bun.com/docs/runtime/sqlite)
- [S3](https://bun.com/docs/runtime/s3)
- [Redis](https://bun.com/docs/runtime/redis)

### System & Environment

- [Environment Variables](https://bun.com/docs/runtime/environment-variables)
- [Shell](https://bun.com/docs/runtime/shell)
- [Child Processes (Spawn)](https://bun.com/docs/runtime/child-process)
- [Workers](https://bun.com/docs/runtime/workers)

### Advanced Runtime Features

- [Node-API](https://bun.com/docs/runtime/node-api)
- [FFI (Foreign Function Interface)](https://bun.com/docs/runtime/ffi)
- [C Compiler](https://bun.com/docs/runtime/c-compiler)
- [Secrets](https://bun.com/docs/runtime/secrets)
- [Console](https://bun.com/docs/runtime/console)
- [YAML](https://bun.com/docs/runtime/yaml)
- [HTMLRewriter](https://bun.com/docs/runtime/html-rewriter)
- [Hashing](https://bun.com/docs/runtime/hashing)
- [Glob](https://bun.com/docs/runtime/glob)
- [Semver](https://bun.com/docs/runtime/semver)
- [Color](https://bun.com/docs/runtime/color)
- [Utils](https://bun.com/docs/runtime/utils)

### APIs & Globals

- [Globals](https://bun.com/docs/runtime/globals)
- [Bun APIs](https://bun.com/docs/runtime/bun-apis)
- [Web APIs](https://bun.com/docs/runtime/web-apis)
- [Debugging](https://bun.com/docs/runtime/debugger)
- [Cookies](https://bun.com/docs/runtime/cookies)

---

## Test Runner Documentation

### Getting Started with bun test

- [Test Runner Overview](https://bun.com/docs/test)
- [Writing Tests](https://bun.com/docs/test/writing-tests)
- [Lifecycle Hooks](https://bun.com/docs/test/lifecycle)

### Test Features

- [Mocks](https://bun.com/docs/test/mocks)
- [Snapshots](https://bun.com/docs/test/snapshots)
- [DOM Testing](https://bun.com/docs/test/dom)

### Test Execution & Control

- **Concurrency:**

  - [Concurrent Testing](https://bun.com/docs/test#concurrent-test-execution)
  - test.concurrent() - Run tests in parallel
  - test.serial() - Force sequential execution
  - --concurrent flag - Enable concurrent mode
  - --max-concurrency - Limit concurrent tests (default: 20)

- **Filtering & Patterns:**

  - [--test-name-pattern / -t flag](https://bun.com/docs/test#test-filtering)
  - Filter by test file paths
  - Include tests marked with test.todo()

- **Test Control:**

  - [--bail flag](https://bun.com/docs/test#bail-out-with-bail) - Exit after N failures (default: 1)
  - [--timeout flag](https://bun.com/docs/test#timeouts) - Per-test timeout (default: 5000ms)
  - [--rerun-each flag](https://bun.com/docs/test#rerun-tests) - Run each test multiple times
  - [--randomize flag](https://bun.com/docs/test#randomize-test-execution-order) - Random execution order
  - [--seed flag](https://bun.com/docs/test#reproducible-random-order-with-seed) - Reproducible randomization

- **Watch Mode:**
  - [--watch flag](https://bun.com/docs/test#watch-mode) - Re-run tests on file changes

### Snapshots & Coverage

- [--update-snapshots / -u flag](https://bun.com/docs/test#snapshot-testing)
- [--coverage flag](https://bun.com/docs/test#coverage) - Generate coverage profile
- [--coverage-reporter flag](https://bun.com/docs/test#coverage) - Format: text or lcov
- [--coverage-dir flag](https://bun.com/docs/test#coverage) - Output directory (default: coverage)

### Reporting

- [--reporter flag](https://bun.com/docs/test#reporting) - Format: junit, dots, or console
- [--reporter-outfile flag](https://bun.com/docs/test#reporting) - Output file for reports
- [--dots flag](https://bun.com/docs/test#reporting) - Enable dots reporter
- [GitHub Actions Integration](https://bun.com/docs/test#github-actions) - Automatic annotations
- [JUnit XML Reports](https://bun.com/docs/test#junit-xml-reports-gitlab,-etc)

### Advanced Features

- [AI Agent Integration](https://bun.com/docs/test#ai-agent-integration) - CLAUDECODE=1, REPL_ID=1, AGENT=1
- [Jest Compatibility](https://github.com/oven-sh/bun/issues/1825)
- Preload scripts with --preload flag
- Single process execution model

---

## Project & Contribution

### Project Information

- [Roadmap](https://bun.com/docs/project/roadmap)
- [Benchmarking](https://bun.com/docs/project/benchmarking)
- [Contributing](https://bun.com/docs/project/contributing)
- [Building on Windows](https://bun.com/docs/project/building-windows)
- [Bindgen](https://bun.com/docs/project/bindgen)
- [License](https://bun.com/docs/project/license)

---

## Deployment Guides

### Cloud Platforms

- [Deploy Bun on Vercel](https://bun.com/docs/guides/deployment/vercel)
- [Deploy Bun on Railway](https://bun.com/docs/guides/deployment/railway)
- [Deploy Bun on Render](https://bun.com/docs/guides/deployment/render)
- [Deploy on AWS Lambda](https://bun.com/docs/guides/deployment/aws-lambda)
- [Deploy on DigitalOcean](https://bun.com/docs/guides/deployment/digital-ocean)
- [Deploy on Google Cloud Run](https://bun.com/docs/guides/deployment/google-cloud-run)

---

## Binary Data Processing

### ArrayBuffer Conversions

- [Convert an ArrayBuffer to an array of numbers](https://bun.com/docs/guides/binary/arraybuffer-to-array)
- [Convert an ArrayBuffer to a Blob](https://bun.com/docs/guides/binary/arraybuffer-to-blob)
- [Convert an ArrayBuffer to a Buffer](https://bun.com/docs/guides/binary/arraybuffer-to-buffer)
- [Convert an ArrayBuffer to a string](https://bun.com/docs/guides/binary/arraybuffer-to-string)
- [Convert an ArrayBuffer to a Uint8Array](https://bun.com/docs/guides/binary/arraybuffer-to-typedarray)

### Blob Conversions

- [Convert a Blob to an ArrayBuffer](https://bun.com/docs/guides/binary/blob-to-arraybuffer)
- [Convert a Blob to a DataView](https://bun.com/docs/guides/binary/blob-to-dataview)
- [Convert a Blob to a ReadableStream](https://bun.com/docs/guides/binary/blob-to-stream)
- [Convert a Blob to a string](https://bun.com/docs/guides/binary/blob-to-string)
- [Convert a Blob to a Uint8Array](https://bun.com/docs/guides/binary/blob-to-typedarray)

### Buffer Conversions

- [Convert a Buffer to an ArrayBuffer](https://bun.com/docs/guides/binary/buffer-to-arraybuffer)
- [Convert a Buffer to a blob](https://bun.com/docs/guides/binary/buffer-to-blob)
- [Convert a Buffer to a ReadableStream](https://bun.com/docs/guides/binary/buffer-to-readablestream)
- [Convert a Buffer to a string](https://bun.com/docs/guides/binary/buffer-to-string)
- [Convert a Buffer to a Uint8Array](https://bun.com/docs/guides/binary/buffer-to-typedarray)

### Other Data Type Conversions

- [Convert a DataView to a string](https://bun.com/docs/guides/binary/dataview-to-string)
- [Convert a Uint8Array to an ArrayBuffer](https://bun.com/docs/guides/binary/typedarray-to-arraybuffer)
- [Convert a Uint8Array to a Blob](https://bun.com/docs/guides/binary/typedarray-to-blob)
- [Convert a Uint8Array to a Buffer](https://bun.com/docs/guides/binary/typedarray-to-buffer)
- [Convert a Uint8Array to a DataView](https://bun.com/docs/guides/binary/typedarray-to-dataview)
- [Convert a Uint8Array to a ReadableStream](https://bun.com/docs/guides/binary/typedarray-to-readablestream)
- [Convert a Uint8Array to a string](https://bun.com/docs/guides/binary/typedarray-to-string)

---

## Ecosystem Integration

### ORM & Database

- [Use Prisma ORM with Bun](https://bun.com/docs/guides/ecosystem/prisma)
- [Use Prisma Postgres with Bun](https://bun.com/docs/guides/ecosystem/prisma-postgres)
- [Use Drizzle ORM with Bun](https://bun.com/docs/guides/ecosystem/drizzle)
- [Use Neon Postgres through Drizzle ORM](https://bun.com/docs/guides/ecosystem/neon-drizzle)
- [Use Neon's Serverless Postgres with Bun](https://bun.com/docs/guides/ecosystem/neon-serverless-postgres)
- [Read and write data to MongoDB using Mongoose and Bun](https://bun.com/docs/guides/ecosystem/mongoose)

### Framework Integration

- [Build a React app with Bun](https://bun.com/docs/guides/ecosystem/react)
- [Build an app with Next.js and Bun](https://bun.com/docs/guides/ecosystem/nextjs)
- [Use TanStack Start with Bun](https://bun.com/docs/guides/ecosystem/tanstack-start)
- [Build a frontend using Vite and Bun](https://bun.com/docs/guides/ecosystem/vite)
- [Build an app with SvelteKit and Bun](https://bun.com/docs/guides/ecosystem/sveltekit)
- [Build an app with SolidStart and Bun](https://bun.com/docs/guides/ecosystem/solidstart)
- [Build an app with Astro and Bun](https://bun.com/docs/guides/ecosystem/astro)
- [Build an app with Remix and Bun](https://bun.com/docs/guides/ecosystem/remix)
- [Build an app with Nuxt and Bun](https://bun.com/docs/guides/ecosystem/nuxt)
- [Build an app with Qwik and Bun](https://bun.com/docs/guides/ecosystem/qwik)

### HTTP Frameworks

- [Build an HTTP server using Hono and Bun](https://bun.com/docs/guides/ecosystem/hono)
- [Build an HTTP server using Elysia and Bun](https://bun.com/docs/guides/ecosystem/elysia)
- [Build an HTTP server using Express and Bun](https://bun.com/docs/guides/ecosystem/express)
- [Build an HTTP server using StricJS and Bun](https://bun.com/docs/guides/ecosystem/stric)

### Utilities & Tools

- [Create a Discord bot](https://bun.com/docs/guides/ecosystem/discordjs)
- [Use Gel with Bun](https://bun.com/docs/guides/ecosystem/gel)
- [Add Sentry to a Bun app](https://bun.com/docs/guides/ecosystem/sentry)
- [Run Bun as a daemon with PM2](https://bun.com/docs/guides/ecosystem/pm2)
- [Run Bun as a daemon with systemd](https://bun.com/docs/guides/ecosystem/systemd)
- [Containerize a Bun application with Docker](https://bun.com/docs/guides/ecosystem/docker)
- [Upstash with Bun](https://bun.com/docs/guides/ecosystem/upstash)

### Server-Side Rendering

- [Server-side render (SSR) a React component](https://bun.com/docs/guides/ecosystem/ssr-react)

---

## HTMLRewriter

- [Extract links from a webpage using HTMLRewriter](https://bun.com/docs/guides/html-rewriter/extract-links)
- [Extract social share images and Open Graph tags](https://bun.com/docs/guides/html-rewriter/extract-social-meta)

---

## HTTP Server & Client

### Server Setup

- [Write a simple HTTP server](https://bun.com/docs/guides/http/simple)
- [Common HTTP server usage](https://bun.com/docs/guides/http/server)
- [Hot reload an HTTP server](https://bun.com/docs/guides/http/hot)
- [Start a cluster of HTTP servers](https://bun.com/docs/guides/http/cluster)
- [Configure TLS on an HTTP server](https://bun.com/docs/guides/http/tls)

### HTTP Client

- [Send an HTTP request using fetch](https://bun.com/docs/guides/http/fetch)
- [Proxy HTTP requests using fetch()](https://bun.com/docs/guides/http/proxy)
- [fetch with unix domain sockets in Bun](https://bun.com/docs/guides/http/fetch-unix)

### Streaming & File Handling

- [Stream a file as an HTTP Response](https://bun.com/docs/guides/http/stream-file)
- [Upload files via HTTP using FormData](https://bun.com/docs/guides/http/file-uploads)
- [Streaming HTTP Server with Async Iterators](https://bun.com/docs/guides/http/stream-iterator)
- [Streaming HTTP Server with Node.js Streams](https://bun.com/docs/guides/http/stream-node-streams-in-bun)

---

## Package Manager (bun install)

### Adding Dependencies

- [Add a dependency](https://bun.com/docs/guides/install/add)
- [Add a development dependency](https://bun.com/docs/guides/install/add-dev)
- [Add a Git dependency](https://bun.com/docs/guides/install/add-git)
- [Add an optional dependency](https://bun.com/docs/guides/install/add-optional)
- [Add a peer dependency](https://bun.com/docs/guides/install/add-peer)
- [Add a tarball dependency](https://bun.com/docs/guides/install/add-tarball)
- [Add a trusted dependency](https://bun.com/docs/guides/install/trusted)

### Registry & Configuration

- [Override the default npm registry for bun install](https://bun.com/docs/guides/install/custom-registry)
- [Configure a private registry for an organization scope with bun install](https://bun.com/docs/guides/install/registry-scope)
- [Using bun install with Artifactory](https://bun.com/docs/guides/install/jfrog-artifactory)
- [Using bun install with an Azure Artifacts npm registry](https://bun.com/docs/guides/install/azure-artifacts)

### Lockfile & Compatibility

- [Generate a yarn-compatible lockfile](https://bun.com/docs/guides/install/yarnlock)
- [Configure git to diff Bun's lockb lockfile](https://bun.com/docs/guides/install/git-diff-bun-lockfile)

### Migration & Workspace

- [Migrate from npm install to bun install](https://bun.com/docs/guides/install/from-npm-install-to-bun-install)
- [Configuring a monorepo using workspaces](https://bun.com/docs/guides/install/workspaces)
- [Install a package under a different name](https://bun.com/docs/guides/install/npm-alias)

### CI/CD

- [Install dependencies with Bun in GitHub Actions](https://bun.com/docs/guides/install/cicd)

---

## Process Management

### Input/Output

- [Read from stdin](https://bun.com/docs/guides/process/stdin)
- [Parse command-line arguments](https://bun.com/docs/guides/process/argv)

### Signal Handling

- [Listen for CTRL+C](https://bun.com/docs/guides/process/ctrl-c)
- [Listen to OS signals](https://bun.com/docs/guides/process/os-signals)

### Child Processes

- [Spawn a child process](https://bun.com/docs/guides/process/spawn)
- [Read stdout from a child process](https://bun.com/docs/guides/process/spawn-stdout)
- [Read stderr from a child process](https://bun.com/docs/guides/process/spawn-stderr)
- [Spawn a child process and communicate using IPC](https://bun.com/docs/guides/process/ipc)

### Timing

- [Get the process uptime in nanoseconds](https://bun.com/docs/guides/process/nanoseconds)

---

## Reading Files

### Basic Reading

- [Read a file as a string](https://bun.com/docs/guides/read-file/string)
- [Read a file to a Buffer](https://bun.com/docs/guides/read-file/buffer)
- [Read a file to a Uint8Array](https://bun.com/docs/guides/read-file/uint8array)
- [Read a file to an ArrayBuffer](https://bun.com/docs/guides/read-file/arraybuffer)

### Structured Data

- [Read a JSON file](https://bun.com/docs/guides/read-file/json)

### File Metadata

- [Check if a file exists](https://bun.com/docs/guides/read-file/exists)
- [Get the MIME type of a file](https://bun.com/docs/guides/read-file/mime)

### Streaming & Watching

- [Read a file as a ReadableStream](https://bun.com/docs/guides/read-file/stream)
- [Watch a directory for changes](https://bun.com/docs/guides/read-file/watch)

---

## Runtime Configuration & Environment

### Environment Variables

- [Read environment variables](https://bun.com/docs/guides/runtime/read-env)
- [Set environment variables](https://bun.com/docs/guides/runtime/set-env)

### Timezone & Build Constants

- [Set a time zone in Bun](https://bun.com/docs/guides/runtime/timezone)
- [Build-time constants with --define](https://bun.com/docs/guides/runtime/build-time-constants)
- [Define and replace static globals & constants](https://bun.com/docs/guides/runtime/define-constant)

### Import Configuration

- [Re-map import paths](https://bun.com/docs/guides/runtime/tsconfig-paths)

### File Operations

- [Delete files](https://bun.com/docs/guides/runtime/delete-file)
- [Delete directories](https://bun.com/docs/guides/runtime/delete-directory)

### Import Formats

- [Import a JSON file](https://bun.com/docs/guides/runtime/import-json)
- [Import a TOML file](https://bun.com/docs/guides/runtime/import-toml)
- [Import a YAML file](https://bun.com/docs/guides/runtime/import-yaml)
- [Import a HTML file as text](https://bun.com/docs/guides/runtime/import-html)

### Shell & System

- [Run a Shell Command](https://bun.com/docs/guides/runtime/shell)

### Debugging

- [Debugging Bun with the web debugger](https://bun.com/docs/guides/runtime/web-debugger)
- [Debugging Bun with the VS Code extension](https://bun.com/docs/guides/runtime/vscode-debugger)
- [Inspect memory usage using V8 heap snapshots](https://bun.com/docs/guides/runtime/heap-snapshot)

### TypeScript

- [Install TypeScript declarations for Bun](https://bun.com/docs/guides/runtime/typescript)

### Code Signing

- [Codesign a single-file JavaScript executable on macOS](https://bun.com/docs/guides/runtime/codesign-macos-executable)

### CI/CD

- [Install and run Bun in GitHub Actions](https://bun.com/docs/guides/runtime/cicd)

---

## Streams

### ReadableStream Conversions

- [Convert a ReadableStream to a string](https://bun.com/docs/guides/streams/to-string)
- [Convert a ReadableStream to JSON](https://bun.com/docs/guides/streams/to-json)
- [Convert a ReadableStream to a Blob](https://bun.com/docs/guides/streams/to-blob)
- [Convert a ReadableStream to a Buffer](https://bun.com/docs/guides/streams/to-buffer)
- [Convert a ReadableStream to a Uint8Array](https://bun.com/docs/guides/streams/to-typedarray)
- [Convert a ReadableStream to an ArrayBuffer](https://bun.com/docs/guides/streams/to-arraybuffer)
- [Convert a ReadableStream to an array of chunks](https://bun.com/docs/guides/streams/to-array)

### Node.js Readable Conversions

- [Convert a Node.js Readable to a string](https://bun.com/docs/guides/streams/node-readable-to-string)
- [Convert a Node.js Readable to JSON](https://bun.com/docs/guides/streams/node-readable-to-json)
- [Convert a Node.js Readable to a Blob](https://bun.com/docs/guides/streams/node-readable-to-blob)
- [Convert a Node.js Readable to an Uint8Array](https://bun.com/docs/guides/streams/node-readable-to-uint8array)
- [Convert a Node.js Readable to an ArrayBuffer](https://bun.com/docs/guides/streams/node-readable-to-arraybuffer)

---

## Test Runner

### Running Tests

- [Run your tests with the Bun test runner](https://bun.com/docs/guides/test/run-tests)
- [Run tests in watch mode with Bun](https://bun.com/docs/guides/test/watch-mode)

### Test Control Flow

- [Skip tests with the Bun test runner](https://bun.com/docs/guides/test/skip-tests)
- [Bail early with the Bun test runner](https://bun.com/docs/guides/test/bail)
- [Mark a test as a "todo" with the Bun test runner](https://bun.com/docs/guides/test/todo-tests)

### Mocking & Spying

- [Mock functions in bun test](https://bun.com/docs/guides/test/mock-functions)
- [Spy on methods in bun test](https://bun.com/docs/guides/test/spy-on)
- [Set the system time in Bun's test runner](https://bun.com/docs/guides/test/mock-clock)

### Snapshots & Coverage

- [Use snapshot testing in bun test](https://bun.com/docs/guides/test/snapshot)
- [Update snapshots in bun test](https://bun.com/docs/guides/test/update-snapshots)
- [Generate code coverage reports with the Bun test runner](https://bun.com/docs/guides/test/coverage)
- [Set a code coverage threshold with the Bun test runner](https://bun.com/docs/guides/test/coverage-threshold)

### Advanced Testing

- [Set a per-test timeout with the Bun test runner](https://bun.com/docs/guides/test/timeout)
- [Re-run tests multiple times with the Bun test runner](https://bun.com/docs/guides/test/rerun-each)
- [Selectively run tests concurrently with glob patterns](https://bun.com/docs/guides/test/concurrent-test-glob)

### Testing Libraries & Frameworks

- [Using Testing Library with Bun](https://bun.com/docs/guides/test/testing-library)
- [Write browser DOM tests with Bun and happy-dom](https://bun.com/docs/guides/test/happy-dom)
- [import, require, and test Svelte components with bun test](https://bun.com/docs/guides/test/svelte-test)

### Migration

- [Migrate from Jest to Bun's test runner](https://bun.com/docs/guides/test/migrate-from-jest)

---

## Utilities

### Cryptography & Hashing

- [Hash a password](https://bun.com/docs/guides/util/hash-a-password)

### Encoding & Decoding

- [Encode and decode base64 strings](https://bun.com/docs/guides/util/base64)
- [Compress and decompress data with gzip](https://bun.com/docs/guides/util/gzip)
- [Compress and decompress data with DEFLATE](https://bun.com/docs/guides/util/deflate)

### String & HTML

- [Escape an HTML string](https://bun.com/docs/guides/util/escape-html)

### UUID & Identification

- [Generate a UUID](https://bun.com/docs/guides/util/javascript-uuid)

### File & Path Utilities

- [Convert a file URL to an absolute path](https://bun.com/docs/guides/util/file-url-to-path)
- [Convert an absolute path to a file URL](https://bun.com/docs/guides/util/path-to-file-url)
- [Get the path to an executable bin file](https://bun.com/docs/guides/util/which-path-to-executable-bin)

### Module Metadata

- [Get the directory of the current file](https://bun.com/docs/guides/util/import-meta-dir)
- [Get the file name of the current file](https://bun.com/docs/guides/util/import-meta-file)
- [Get the absolute path of the current file](https://bun.com/docs/guides/util/import-meta-path)
- [Check if the current file is the entrypoint](https://bun.com/docs/guides/util/entrypoint)
- [Get the absolute path to the current entrypoint](https://bun.com/docs/guides/util/main)

### Environment & Detection

- [Detect when code is executed with Bun](https://bun.com/docs/guides/util/detect-bun)
- [Get the current Bun version](https://bun.com/docs/guides/util/version)
- [Upgrade Bun](https://bun.com/docs/guides/util/upgrade)

### Comparison & Timing

- [Check if two objects are deeply equal](https://bun.com/docs/guides/util/deep-equals)
- [Sleep for a fixed number of milliseconds](https://bun.com/docs/guides/util/sleep)

---

## WebSocket

### Basic WebSocket

- [Build a simple WebSocket server](https://bun.com/docs/guides/websocket/simple)

### WebSocket Features

- [Enable compression for WebSocket messages](https://bun.com/docs/guides/websocket/compression)
- [Set per-socket contextual data on a WebSocket](https://bun.com/docs/guides/websocket/context)

### Advanced Patterns

- [Build a publish-subscribe WebSocket server](https://bun.com/docs/guides/websocket/pubsub)

---

## Writing Files

### Basic Writing

- [Write a string to a file](https://bun.com/docs/guides/write-file/basic)
- [Write to stdout](https://bun.com/docs/guides/write-file/stdout)
- [Write a file to stdout](https://bun.com/docs/guides/write-file/cat)

### Append & Modify

- [Append content to a file](https://bun.com/docs/guides/write-file/append)

### Data Formats

- [Write a Blob to a file](https://bun.com/docs/guides/write-file/blob)
- [Write a Response to a file](https://bun.com/docs/guides/write-file/response)

### Streaming & Advanced

- [Write a ReadableStream to a file](https://bun.com/docs/guides/write-file/stream)
- [Write a file incrementally](https://bun.com/docs/guides/write-file/filesink)

### File Operations

- [Copy a file to another location](https://bun.com/docs/guides/write-file/file-cp)
- [Delete a file](https://bun.com/docs/guides/write-file/unlink)

---

## External Links

### Community & Support

- [Blog](https://bun.com/blog)
- [Discord](https://bun.com/discord)
- [GitHub](https://github.com/oven-sh/bun)
- [X (Twitter)](https://x.com/bunjavascript)
- [YouTube](https://www.youtube.com/@bunjs)

### Installation

- [Install Bun](https://www.bun.com/docs/installation)

### Contribution & Issues

- [Suggest edits on GitHub](https://github.com/oven-sh/bun/edit/main/docs/guides.mdx)
- [Raise issue on GitHub](https://github.com/oven-sh/bun/issues/new?title=Issue%20on%20docs&body=Path%3A%20%2Fguides)

### Support

- [Create support ticket](mailto:support@bun.com)

### Documentation Provider

- [Powered by Mintlify](https://www.mintlify.com?utm_campaign=poweredBy&utm_medium=referral&utm_source=bun-1dd33a4e)

---

## Quick Links by Use Case

### Getting Started

1. [Install Bun](https://www.bun.com/docs/installation)
2. [Write a simple HTTP server](https://bun.com/docs/guides/http/simple)
3. [Install TypeScript declarations for Bun](https://bun.com/docs/guides/runtime/typescript)

### Building Web Applications

1. [Build a React app with Bun](https://bun.com/docs/guides/ecosystem/react)
2. [Build an app with Next.js and Bun](https://bun.com/docs/guides/ecosystem/nextjs)
3. [Build a frontend using Vite and Bun](https://bun.com/docs/guides/ecosystem/vite)

### Database & ORM

1. [Use Prisma ORM with Bun](https://bun.com/docs/guides/ecosystem/prisma)
2. [Use Drizzle ORM with Bun](https://bun.com/docs/guides/ecosystem/drizzle)
3. [Use Neon Postgres through Drizzle ORM](https://bun.com/docs/guides/ecosystem/neon-drizzle)

### Deployment

1. [Deploy Bun on Vercel](https://bun.com/docs/guides/deployment/vercel)
2. [Deploy Bun on Railway](https://bun.com/docs/guides/deployment/railway)
3. [Deploy on AWS Lambda](https://bun.com/docs/guides/deployment/aws-lambda)

### Testing

1. [Run your tests with the Bun test runner](https://bun.com/docs/guides/test/run-tests)
2. [Mock functions in bun test](https://bun.com/docs/guides/test/mock-functions)
3. [Generate code coverage reports with the Bun test runner](https://bun.com/docs/guides/test/coverage)

### Real-Time Applications

1. [Build a simple WebSocket server](https://bun.com/docs/guides/websocket/simple)
2. [Build a publish-subscribe WebSocket server](https://bun.com/docs/guides/websocket/pubsub)
3. [Upstash with Bun](https://bun.com/docs/guides/ecosystem/upstash)

### File & Stream Processing

1. [Read a file as a string](https://bun.com/docs/guides/read-file/string)
2. [Stream a file as an HTTP Response](https://bun.com/docs/guides/http/stream-file)
3. [Write a ReadableStream to a file](https://bun.com/docs/guides/write-file/stream)

### Process & System Integration

1. [Run a Shell Command](https://bun.com/docs/guides/runtime/shell)
2. [Spawn a child process](https://bun.com/docs/guides/process/spawn)
3. [Read environment variables](https://bun.com/docs/guides/runtime/read-env)

---

---

## Summary Statistics

| Category               | Count   |
| ---------------------- | ------- |
| Core Documentation     | 7       |
| Runtime Documentation  | 80+     |
| Test Runner Documentation | 40+  |
| Project & Contribution | 6       |
| Deployment Guides      | 6       |
| Binary Data Processing | 22      |
| Ecosystem Integration  | 31      |
| HTMLRewriter           | 2       |
| HTTP Server & Client   | 12      |
| Package Manager        | 13      |
| Process Management     | 9       |
| Reading Files          | 9       |
| Streams                | 12      |
| Utilities              | 17      |
| WebSocket              | 4       |
| Writing Files          | 10      |
| External Resources     | 13      |
| **Total**              | **300+** |

---

## How to Use This Index

### For Agents & Automation

- Use the organized links to create specialized agents for different Bun functionalities
- Reference the "Use Case" section to quickly find relevant documentation
- Filter by category to build domain-specific knowledge bases

### For Development

- Bookmark frequently used sections for quick access
- Use the summary statistics to understand documentation coverage
- Link to specific guides when building similar features

### For Learning

- Start with the "Getting Started" section
- Progress through "Building Web Applications"
- Move to specialized topics (Database, Testing, Real-Time, etc.)

---

Generated with Playwright browser automation
