#!/bin/bash

# generate-api-client.sh - Generate authenticated API client
# Usage: bash generate-api-client.sh <api-type> <output-path>

set -e

API_TYPE=$1
OUTPUT_PATH=$2

if [ -z "$API_TYPE" ] || [ -z "$OUTPUT_PATH" ]; then
    echo "Usage: bash generate-api-client.sh <api-type> <output-path>"
    echo "API Types: rest, graphql, axios, trpc"
    exit 1
fi

echo "🔧 Generating $API_TYPE API client with Clerk authentication..."

# Create output directory
mkdir -p "$(dirname "$OUTPUT_PATH")"

case $API_TYPE in
    rest)
        cat > "$OUTPUT_PATH" << 'EOF'
// REST API Client with Clerk Authentication
import { useAuth } from '@clerk/nextjs'

interface RequestOptions extends RequestInit {
  body?: any
}

export function createAuthenticatedClient() {
  const { getToken } = useAuth()

  async function request<T>(
    endpoint: string,
    options: RequestOptions = {}
  ): Promise<T> {
    const token = await getToken()

    const config: RequestInit = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        ...options.headers,
      },
    }

    if (options.body) {
      config.body = JSON.stringify(options.body)
    }

    const response = await fetch(endpoint, config)

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('Unauthorized - please sign in')
      }
      throw new Error(`API error: ${response.statusText}`)
    }

    return response.json()
  }

  return {
    get: <T>(url: string) => request<T>(url, { method: 'GET' }),
    post: <T>(url: string, body: any) =>
      request<T>(url, { method: 'POST', body }),
    put: <T>(url: string, body: any) =>
      request<T>(url, { method: 'PUT', body }),
    delete: <T>(url: string) => request<T>(url, { method: 'DELETE' }),
    patch: <T>(url: string, body: any) =>
      request<T>(url, { method: 'PATCH', body }),
  }
}

// Usage:
// const api = createAuthenticatedClient()
// const data = await api.get<User>('/api/user')
// await api.post('/api/posts', { title: 'New Post' })
EOF
        echo "✅ Created REST API client: $OUTPUT_PATH"
        ;;

    graphql)
        cat > "$OUTPUT_PATH" << 'EOF'
// GraphQL Client with Clerk Authentication
import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client'
import { setContext } from '@apollo/client/link/context'
import { useAuth } from '@clerk/nextjs'

export function createAuthenticatedGraphQLClient() {
  const { getToken } = useAuth()

  const httpLink = createHttpLink({
    uri: process.env.NEXT_PUBLIC_GRAPHQL_ENDPOINT || '/api/graphql',
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

// Usage with Apollo Client hooks:
// const client = createAuthenticatedGraphQLClient()
//
// function MyComponent() {
//   const { data } = useQuery(GET_USER, { client })
//   return <div>{data?.user?.name}</div>
// }
EOF
        echo "✅ Created GraphQL client: $OUTPUT_PATH"
        npm install @apollo/client graphql 2>/dev/null || true
        ;;

    axios)
        cat > "$OUTPUT_PATH" << 'EOF'
// Axios Client with Clerk Authentication
import axios, { AxiosInstance } from 'axios'
import { useAuth } from '@clerk/nextjs'

export function createAuthenticatedAxiosClient(
  baseURL: string = '/api'
): AxiosInstance {
  const { getToken } = useAuth()

  const client = axios.create({
    baseURL,
    headers: {
      'Content-Type': 'application/json',
    },
  })

  // Request interceptor to add JWT token
  client.interceptors.request.use(
    async (config) => {
      const token = await getToken()

      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }

      return config
    },
    (error) => Promise.reject(error)
  )

  // Response interceptor for error handling
  client.interceptors.response.use(
    (response) => response,
    async (error) => {
      if (error.response?.status === 401) {
        // Token expired or invalid
        console.error('Unauthorized - please sign in again')
      }
      return Promise.reject(error)
    }
  )

  return client
}

// Usage:
// const api = createAuthenticatedAxiosClient()
// const { data } = await api.get('/users')
// await api.post('/posts', { title: 'New Post' })
EOF
        echo "✅ Created Axios client: $OUTPUT_PATH"
        npm install axios 2>/dev/null || true
        ;;

    trpc)
        cat > "$OUTPUT_PATH" << 'EOF'
// tRPC Client with Clerk Authentication
import { createTRPCReact } from '@trpc/react-query'
import { httpBatchLink } from '@trpc/client'
import { useAuth } from '@clerk/nextjs'
import type { AppRouter } from '@/server/routers/_app'

export const trpc = createTRPCReact<AppRouter>()

export function createAuthenticatedTRPCClient() {
  const { getToken } = useAuth()

  return trpc.createClient({
    links: [
      httpBatchLink({
        url: '/api/trpc',
        async headers() {
          const token = await getToken()
          return {
            authorization: token ? `Bearer ${token}` : '',
          }
        },
      }),
    ],
  })
}

// Usage in _app.tsx:
// import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
// import { createAuthenticatedTRPCClient, trpc } from '@/lib/trpc'
//
// function MyApp({ Component, pageProps }: AppProps) {
//   const [queryClient] = useState(() => new QueryClient())
//   const [trpcClient] = useState(() => createAuthenticatedTRPCClient())
//
//   return (
//     <trpc.Provider client={trpcClient} queryClient={queryClient}>
//       <QueryClientProvider client={queryClient}>
//         <Component {...pageProps} />
//       </QueryClientProvider>
//     </trpc.Provider>
//   )
// }
EOF
        echo "✅ Created tRPC client: $OUTPUT_PATH"
        npm install @trpc/client @trpc/server @trpc/react-query @tanstack/react-query 2>/dev/null || true
        ;;

    *)
        echo "Error: Unsupported API type: $API_TYPE"
        echo "Supported: rest, graphql, axios, trpc"
        exit 1
        ;;
esac

echo ""
echo "📝 Next steps:"
echo "1. Import the generated client in your components"
echo "2. Use the authenticated methods to make API calls"
echo "3. Handle authentication errors appropriately"
echo ""
echo "Example import:"
echo "  import { createAuthenticatedClient } from '$OUTPUT_PATH'"
