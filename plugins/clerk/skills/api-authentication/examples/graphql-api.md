# GraphQL API with Clerk Authentication

Complete Apollo Server implementation with Clerk authentication context.

## Overview

This example demonstrates:
- GraphQL type definitions for authenticated queries
- Context-based authentication
- Public vs protected queries
- Role-based mutations
- Error handling with GraphQL errors

## Implementation

### 1. Type Definitions

```graphql
type User {
  id: ID!
  email: String!
  firstName: String
  lastName: String
  role: String
  createdAt: String!
}

type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
  createdAt: String!
}

type Query {
  # Public
  publicPosts: [Post!]!

  # Authenticated
  me: User!
  myPosts: [Post!]!

  # Admin
  users: [User!]!
  allPosts: [Post!]!
}

type Mutation {
  createPost(title: String!, content: String!): Post!
  updatePost(id: ID!, title: String, content: String): Post!
  deletePost(id: ID!): Boolean!

  # Admin mutations
  updateUserRole(userId: ID!, role: String!): User!
}
```

### 2. Server Setup with Authentication Context

```typescript
import { ApolloServer } from '@apollo/server'
import { expressMiddleware } from '@apollo/server/express4'
import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node'
import { getUserById } from './lib/clerk-backend'

const server = new ApolloServer({
  typeDefs,
  resolvers,
})

await server.start()

app.use(
  '/graphql',
  cors({ origin: process.env.FRONTEND_URL, credentials: true }),
  express.json(),
  ClerkExpressRequireAuth({
    onError: () => undefined, // Allow through to resolvers
  }),
  expressMiddleware(server, {
    context: async ({ req }) => {
      const userId = req.auth?.userId

      return {
        userId,
        user: userId ? await getUserById(userId) : null,
      }
    },
  })
)
```

### 3. Public Queries

```typescript
const resolvers = {
  Query: {
    // No authentication required
    publicPosts: async () => {
      return await getAllPublicPosts()
    },
  },
}
```

### 4. Authenticated Queries

```typescript
const resolvers = {
  Query: {
    me: async (_, __, context) => {
      if (!context.userId) {
        throw new GraphQLError('Not authenticated', {
          extensions: { code: 'UNAUTHENTICATED' },
        })
      }

      const user = await getUserById(context.userId)

      return {
        id: user.id,
        email: user.emailAddresses[0]?.emailAddress,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.publicMetadata?.role || 'user',
      }
    },

    myPosts: async (_, __, context) => {
      if (!context.userId) {
        throw new GraphQLError('Not authenticated')
      }

      return await getPostsByUserId(context.userId)
    },
  },
}
```

### 5. Protected Mutations

```typescript
const resolvers = {
  Mutation: {
    createPost: async (_, { title, content }, context) => {
      if (!context.userId) {
        throw new GraphQLError('Not authenticated')
      }

      return await createPost({
        userId: context.userId,
        title,
        content,
      })
    },

    deletePost: async (_, { id }, context) => {
      if (!context.userId) {
        throw new GraphQLError('Not authenticated')
      }

      const post = await getPost(id)

      if (post.authorId !== context.userId) {
        throw new GraphQLError('Forbidden - not your post', {
          extensions: { code: 'FORBIDDEN' },
        })
      }

      await deletePost(id)
      return true
    },
  },
}
```

### 6. Admin-Only Queries

```typescript
const resolvers = {
  Query: {
    users: async (_, __, context) => {
      if (!context.userId) {
        throw new GraphQLError('Not authenticated')
      }

      const currentUser = await getUserById(context.userId)

      if (currentUser.publicMetadata?.role !== 'admin') {
        throw new GraphQLError('Forbidden - admin only', {
          extensions: { code: 'FORBIDDEN' },
        })
      }

      return await getAllUsers()
    },
  },

  Mutation: {
    updateUserRole: async (_, { userId, role }, context) => {
      if (!context.userId) {
        throw new GraphQLError('Not authenticated')
      }

      const currentUser = await getUserById(context.userId)

      if (currentUser.publicMetadata?.role !== 'admin') {
        throw new GraphQLError('Forbidden - admin only')
      }

      return await updateUserRole(userId, role)
    },
  },
}
```

## GraphQL Client Setup

### Apollo Client with Authentication

```typescript
import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client'
import { setContext } from '@apollo/client/link/context'
import { useAuth } from '@clerk/nextjs'

export function createAuthenticatedGraphQLClient() {
  const { getToken } = useAuth()

  const httpLink = createHttpLink({
    uri: '/api/graphql',
  })

  const authLink = setContext(async (_, { headers }) => {
    const token = await getToken()

    return {
      headers: {
        ...headers,
        authorization: token ? `Bearer ${token}` : '',
      },
    }
  })

  return new ApolloClient({
    link: authLink.concat(httpLink),
    cache: new InMemoryCache(),
  })
}
```

## Testing Queries

### 1. Public Query

```graphql
query GetPublicPosts {
  publicPosts {
    id
    title
    createdAt
  }
}
```

### 2. Authenticated Query

```graphql
query GetMyProfile {
  me {
    id
    email
    firstName
    lastName
    role
  }
}
```

### 3. Protected Mutation

```graphql
mutation CreatePost($title: String!, $content: String!) {
  createPost(title: $title, content: $content) {
    id
    title
    content
    author {
      firstName
      lastName
    }
  }
}
```

### 4. Admin Query

```graphql
query GetAllUsers {
  users {
    id
    email
    role
    createdAt
  }
}
```

## Error Handling

GraphQL errors are returned with specific codes:

```json
{
  "errors": [
    {
      "message": "Not authenticated",
      "extensions": {
        "code": "UNAUTHENTICATED"
      }
    }
  ]
}
```

Error codes:
- `UNAUTHENTICATED` - No valid token
- `FORBIDDEN` - Insufficient permissions
- `NOT_FOUND` - Resource not found
- `BAD_REQUEST` - Invalid input

## Full Code

See `examples/graphql-clerk.ts.bak` for complete implementation.
