# Next.js Frontend Plugin

Next.js 15 App Router with AI SDK, Supabase, shadcn/ui integration for building modern AI-powered applications.

## Overview

This plugin provides comprehensive Next.js frontend development capabilities with first-class support for:

- **Next.js 15 App Router** - Modern React framework with Server Components
- **Vercel AI SDK** - AI streaming and model integration
- **Supabase** - Database, authentication, and storage
- **shadcn/ui** - High-quality UI component library
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first styling

## Commands

### `/nextjs-frontend:init`

Initialize a new Next.js 15 application with AI and Supabase integration.

**Usage:**
```bash
/nextjs-frontend:init my-app
```

Creates a complete Next.js project with:
- App Router structure
- TypeScript configuration
- Tailwind CSS setup
- shadcn/ui components
- AI SDK integration
- Supabase client setup

### `/nextjs-frontend:add-page`

Add a new page to your Next.js application.

**Usage:**
```bash
/nextjs-frontend:add-page dashboard
```

### `/nextjs-frontend:add-component`

Add a new component with shadcn/ui integration.

**Usage:**
```bash
/nextjs-frontend:add-component chat-interface
```

### `/nextjs-frontend:integrate-supabase`

Integrate Supabase into an existing Next.js project.

**Usage:**
```bash
/nextjs-frontend:integrate-supabase
```

### `/nextjs-frontend:integrate-ai-sdk`

Integrate Vercel AI SDK for AI streaming capabilities.

**Usage:**
```bash
/nextjs-frontend:integrate-ai-sdk
```

### `/nextjs-frontend:search-components`

Search and add shadcn/ui components to your project.

**Usage:**
```bash
/nextjs-frontend:search-components button
```

## MCP Servers Used

- **supabase-mcp**: Database operations, auth, storage
- **shadcn-mcp**: shadcn/ui components and design system
- **tailwind-ui-mcp**: Tailwind CSS design system from Supabase
- **figma-mcp-application**: Application UI components from Figma
- **context7**: Documentation for Next.js, React, and AI SDK

## Features

- **App Router Architecture** - Modern Next.js 15 with Server Components
- **AI Streaming** - Real-time AI responses with Vercel AI SDK
- **Type Safety** - Full TypeScript support throughout
- **Component Library** - shadcn/ui integration with customization
- **Database Integration** - Supabase client with TypeScript types
- **Authentication** - Supabase Auth integration
- **Deployment Ready** - Optimized for Vercel deployment

## Integration Points

- Supabase (database, auth, design system)
- Vercel AI SDK (streaming, models)
- Tailwind CSS (with shadcn/ui + design system components)
- shadcn/ui + Figma MCP servers for component integration
- MCP servers for tool integration

## Development Workflow

1. **Initialize Project**: `/nextjs-frontend:init my-app`
2. **Add Pages**: `/nextjs-frontend:add-page dashboard`
3. **Add Components**: `/nextjs-frontend:add-component chat`
4. **Integrate Services**: `/nextjs-frontend:integrate-supabase`
5. **Add AI Features**: `/nextjs-frontend:integrate-ai-sdk`
6. **Search Components**: `/nextjs-frontend:search-components card`

## Best Practices

- Use Server Components by default for better performance
- Add 'use client' only when needed (state, effects, events)
- Leverage shadcn/ui for consistent UI
- Use TypeScript for type safety
- Follow Next.js App Router conventions
- Implement proper error handling
- Optimize for Core Web Vitals

## Documentation

See `/docs` folder for detailed documentation on:
- Architecture patterns
- Component structure
- API integration
- Deployment strategies
- Testing approaches

## Version

1.0.0

## License

MIT
