---
description: Implement session management and state persistence in Claude Agent SDK project
argument-hint: [storage-type]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Add session management and state persistence to your Claude Agent SDK application.

## Step 1: Verify SDK Project

Ensure Agent SDK is installed. If not, direct to `/claude-agent-sdk:new-app`.

## Step 2: Fetch Session Documentation

Use Context7 to get documentation on "sessions" topic.

## Step 3: Determine Storage Strategy

Ask user:
1. "Where should sessions be stored?" (memory, file, database, redis)
2. "Do you need session persistence across restarts?"
3. "How long should sessions be retained?"

## Step 4: Implement Session Storage

**For In-Memory:**
- Create session store class
- Implement session CRUD operations
- Add session cleanup

**For File Storage:**
- Set up session file directory
- Implement file-based persistence
- Add file locking if needed

**For Database:**
- Set up database connection
- Create session schema
- Implement DB storage layer

## Step 5: Integrate with SDK

- Add session initialization
- Implement session retrieval
- Add session state management
- Handle session expiration

## Step 6: Add Session Examples

Create examples showing:
- Creating new sessions
- Retrieving existing sessions
- Updating session state
- Session cleanup

Update documentation with session management guide.
