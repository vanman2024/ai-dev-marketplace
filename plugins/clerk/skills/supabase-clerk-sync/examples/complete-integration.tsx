/**
 * Complete Clerk + Supabase Integration Example
 *
 * This example demonstrates a full Next.js application with:
 * - Clerk authentication
 * - Supabase database with RLS
 * - User synchronization via webhooks
 * - Protected routes and data access
 */

'use client'

import { ClerkProvider, SignInButton, SignOutButton, useUser, useAuth } from '@clerk/nextjs'
import { createClient, SupabaseClient } from '@supabase/supabase-js'
import { useEffect, useState } from 'react'

// ============================================================================
// CONFIGURATION
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

// ============================================================================
// TYPES
// ============================================================================

interface User {
  id: string
  clerk_id: string
  email: string
  first_name: string
  last_name: string
  avatar_url: string
  username: string
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

interface Post {
  id: string
  clerk_id: string
  title: string
  content: string
  is_published: boolean
  created_at: string
  updated_at: string
}

// ============================================================================
// CUSTOM HOOKS
// ============================================================================

/**
 * Hook to get Supabase client with Clerk authentication
 */
function useSupabaseClient() {
  const { getToken } = useAuth()
  const [supabase, setSupabase] = useState<SupabaseClient | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    async function initSupabase() {
      try {
        const token = await getToken({ template: 'supabase' })

        if (!token) {
          setSupabase(null)
          return
        }

        const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
          global: {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          },
        })

        setSupabase(client)
      } catch (error) {
        console.error('Failed to initialize Supabase:', error)
        setSupabase(null)
      } finally {
        setIsLoading(false)
      }
    }

    initSupabase()
  }, [getToken])

  return { supabase, isLoading }
}

/**
 * Hook to fetch user profile from Supabase
 */
function useUserProfile() {
  const { user } = useUser()
  const { supabase, isLoading: supabaseLoading } = useSupabaseClient()
  const [profile, setProfile] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    async function fetchProfile() {
      if (!user || !supabase) {
        setIsLoading(false)
        return
      }

      try {
        const { data, error } = await supabase
          .from('users')
          .select('*')
          .eq('clerk_id', user.id)
          .single()

        if (error) throw error

        setProfile(data)
      } catch (err) {
        console.error('Error fetching profile:', err)
        setError(err as Error)
      } finally {
        setIsLoading(false)
      }
    }

    if (!supabaseLoading) {
      fetchProfile()
    }
  }, [user, supabase, supabaseLoading])

  return { profile, isLoading: isLoading || supabaseLoading, error }
}

/**
 * Hook to fetch user's posts with real-time updates
 */
function useUserPosts() {
  const { user } = useUser()
  const { supabase } = useSupabaseClient()
  const [posts, setPosts] = useState<Post[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    async function fetchPosts() {
      if (!user || !supabase) {
        setIsLoading(false)
        return
      }

      try {
        const { data, error } = await supabase
          .from('posts')
          .select('*')
          .eq('clerk_id', user.id)
          .order('created_at', { ascending: false })

        if (error) throw error

        setPosts(data || [])
      } catch (error) {
        console.error('Error fetching posts:', error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchPosts()

    // Subscribe to real-time changes
    if (user && supabase) {
      const channel = supabase
        .channel('user_posts')
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'posts',
            filter: `clerk_id=eq.${user.id}`,
          },
          (payload) => {
            console.log('Real-time update:', payload)
            fetchPosts()
          }
        )
        .subscribe()

      return () => {
        supabase.removeChannel(channel)
      }
    }
  }, [user, supabase])

  return { posts, isLoading }
}

// ============================================================================
// COMPONENTS
// ============================================================================

/**
 * User Profile Display
 */
function UserProfile() {
  const { profile, isLoading, error } = useUserProfile()

  if (isLoading) {
    return <div className="animate-pulse">Loading profile...</div>
  }

  if (error) {
    return (
      <div className="text-red-600">
        Error loading profile: {error.message}
      </div>
    )
  }

  if (!profile) {
    return <div>No profile found</div>
  }

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <div className="flex items-center space-x-4">
        <img
          src={profile.avatar_url}
          alt={profile.username}
          className="w-16 h-16 rounded-full"
        />
        <div>
          <h2 className="text-xl font-semibold">
            {profile.first_name} {profile.last_name}
          </h2>
          <p className="text-gray-600">@{profile.username}</p>
          <p className="text-gray-500 text-sm">{profile.email}</p>
        </div>
      </div>

      {profile.metadata && Object.keys(profile.metadata).length > 0 && (
        <div className="mt-4">
          <h3 className="font-medium">Metadata:</h3>
          <pre className="bg-gray-100 p-2 rounded text-sm">
            {JSON.stringify(profile.metadata, null, 2)}
          </pre>
        </div>
      )}
    </div>
  )
}

/**
 * Create Post Form
 */
function CreatePostForm({ onPostCreated }: { onPostCreated: () => void }) {
  const { user } = useUser()
  const { supabase } = useSupabaseClient()
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()

    if (!user || !supabase) return

    setIsSubmitting(true)

    try {
      const { error } = await supabase.from('posts').insert({
        clerk_id: user.id,
        title,
        content,
        is_published: false,
      })

      if (error) throw error

      setTitle('')
      setContent('')
      onPostCreated()
    } catch (error) {
      console.error('Error creating post:', error)
      alert('Failed to create post')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium mb-1">Title</label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="w-full border rounded px-3 py-2"
          required
        />
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">Content</label>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          className="w-full border rounded px-3 py-2 h-32"
          required
        />
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
      >
        {isSubmitting ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  )
}

/**
 * Posts List with Real-time Updates
 */
function PostsList() {
  const { posts, isLoading } = useUserPosts()
  const { supabase } = useSupabaseClient()

  async function handleTogglePublish(post: Post) {
    if (!supabase) return

    try {
      const { error } = await supabase
        .from('posts')
        .update({ is_published: !post.is_published })
        .eq('id', post.id)

      if (error) throw error
    } catch (error) {
      console.error('Error updating post:', error)
      alert('Failed to update post')
    }
  }

  async function handleDelete(postId: string) {
    if (!supabase || !confirm('Delete this post?')) return

    try {
      const { error } = await supabase.from('posts').delete().eq('id', postId)

      if (error) throw error
    } catch (error) {
      console.error('Error deleting post:', error)
      alert('Failed to delete post')
    }
  }

  if (isLoading) {
    return <div className="animate-pulse">Loading posts...</div>
  }

  if (posts.length === 0) {
    return <div className="text-gray-500">No posts yet</div>
  }

  return (
    <div className="space-y-4">
      {posts.map((post) => (
        <div key={post.id} className="bg-white shadow rounded-lg p-4">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <h3 className="font-semibold text-lg">{post.title}</h3>
              <p className="text-gray-600 mt-1">{post.content}</p>
              <div className="flex items-center gap-2 mt-2">
                <span
                  className={`px-2 py-1 text-xs rounded ${
                    post.is_published
                      ? 'bg-green-100 text-green-800'
                      : 'bg-gray-100 text-gray-800'
                  }`}
                >
                  {post.is_published ? 'Published' : 'Draft'}
                </span>
                <span className="text-xs text-gray-500">
                  {new Date(post.created_at).toLocaleDateString()}
                </span>
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => handleTogglePublish(post)}
                className="text-blue-600 hover:text-blue-800 text-sm"
              >
                {post.is_published ? 'Unpublish' : 'Publish'}
              </button>
              <button
                onClick={() => handleDelete(post.id)}
                className="text-red-600 hover:text-red-800 text-sm"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}

/**
 * Dashboard Page (Protected Route)
 */
function Dashboard() {
  const { user, isLoaded } = useUser()
  const [refreshKey, setRefreshKey] = useState(0)

  if (!isLoaded) {
    return <div>Loading...</div>
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Welcome</h1>
          <p className="mb-4">Please sign in to continue</p>
          <SignInButton mode="modal">
            <button className="bg-blue-600 text-white px-6 py-2 rounded">
              Sign In
            </button>
          </SignInButton>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <SignOutButton>
            <button className="bg-gray-200 px-4 py-2 rounded hover:bg-gray-300">
              Sign Out
            </button>
          </SignOutButton>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Profile Section */}
          <div className="lg:col-span-1">
            <UserProfile />
          </div>

          {/* Posts Section */}
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-white shadow rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">Create New Post</h2>
              <CreatePostForm
                onPostCreated={() => setRefreshKey((k) => k + 1)}
              />
            </div>

            <div className="bg-white shadow rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">Your Posts</h2>
              <PostsList key={refreshKey} />
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}

/**
 * Root App Component
 */
export default function App() {
  return (
    <ClerkProvider>
      <Dashboard />
    </ClerkProvider>
  )
}

// ============================================================================
// SERVER COMPONENTS EXAMPLE (Next.js App Router)
// ============================================================================

/**
 * Server-side data fetching with Clerk auth
 */
export async function getServerSideProfile(userId: string) {
  const { auth } = await import('@clerk/nextjs/server')
  const { getToken } = auth()

  const token = await getToken({ template: 'supabase' })

  if (!token) {
    throw new Error('Not authenticated')
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  })

  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('clerk_id', userId)
    .single()

  if (error) throw error

  return data
}

// ============================================================================
// API ROUTE EXAMPLE
// ============================================================================

/**
 * API route with Clerk authentication and Supabase access
 *
 * File: app/api/posts/route.ts
 */
export async function GET(request: Request) {
  const { auth } = await import('@clerk/nextjs/server')
  const { userId, getToken } = auth()

  if (!userId) {
    return new Response('Unauthorized', { status: 401 })
  }

  const token = await getToken({ template: 'supabase' })

  if (!token) {
    return new Response('No token', { status: 401 })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  })

  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('clerk_id', userId)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    })
  }

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  })
}
