import { embed, embedMany, generateText } from 'ai'
import { openai } from '@ai-sdk/openai'
import { z } from 'zod'

/**
 * Complete RAG Pipeline Template
 *
 * This template provides a production-ready RAG implementation
 * with document chunking, embedding generation, vector storage,
 * retrieval, and answer generation.
 *
 * Customize:
 * - Vector database client (Pinecone, Chroma, pgvector, etc.)
 * - Chunking strategy
 * - Embedding model
 * - Retrieval parameters
 */

// ============================================================================
// 1. DOCUMENT INGESTION & CHUNKING
// ============================================================================

interface Document {
  id: string
  content: string
  metadata: {
    source: string
    title?: string
    author?: string
    date?: string
    [key: string]: any
  }
}

interface Chunk {
  id: string
  documentId: string
  text: string
  embedding?: number[]
  metadata: Document['metadata'] & {
    chunkIndex: number
    totalChunks: number
  }
}

async function chunkDocument(
  document: Document,
  options: {
    chunkSize: number
    overlap: number
    strategy: 'fixed' | 'semantic' | 'recursive'
  }
): Promise<Chunk[]> {
  const { chunkSize, overlap, strategy } = options

  let textChunks: string[]

  switch (strategy) {
    case 'fixed':
      textChunks = chunkByFixedSize(document.content, chunkSize, overlap)
      break
    case 'semantic':
      textChunks = chunkBySemantic(document.content, chunkSize)
      break
    case 'recursive':
      textChunks = chunkByRecursive(document.content, chunkSize, overlap)
      break
  }

  return textChunks.map((text, index) => ({
    id: `${document.id}-chunk-${index}`,
    documentId: document.id,
    text,
    metadata: {
      ...document.metadata,
      chunkIndex: index,
      totalChunks: textChunks.length
    }
  }))
}

function chunkByFixedSize(
  text: string,
  chunkSize: number,
  overlap: number
): string[] {
  const chunks: string[] = []
  const words = text.split(/\s+/)

  for (let i = 0; i < words.length; i += chunkSize - overlap) {
    const chunk = words.slice(i, i + chunkSize).join(' ')
    if (chunk.trim()) {
      chunks.push(chunk)
    }
  }

  return chunks
}

function chunkBySemantic(text: string, maxSize: number): string[] {
  // Split on paragraph boundaries
  const sections = text.split(/\n\n+/)
  const chunks: string[] = []
  let currentChunk = ''

  for (const section of sections) {
    const words = section.split(/\s+/)
    if ((currentChunk + ' ' + section).split(/\s+/).length > maxSize) {
      if (currentChunk.trim()) {
        chunks.push(currentChunk.trim())
      }
      currentChunk = section
    } else {
      currentChunk += (currentChunk ? '\n\n' : '') + section
    }
  }

  if (currentChunk.trim()) {
    chunks.push(currentChunk.trim())
  }

  return chunks
}

function chunkByRecursive(
  text: string,
  chunkSize: number,
  overlap: number
): string[] {
  // Implement hierarchical chunking based on headings
  const sections = text.split(/(?=^#{1,6}\s)/m)
  const chunks: string[] = []

  for (const section of sections) {
    const words = section.split(/\s+/)
    if (words.length > chunkSize) {
      // Further split large sections
      chunks.push(...chunkByFixedSize(section, chunkSize, overlap))
    } else {
      chunks.push(section)
    }
  }

  return chunks
}

// ============================================================================
// 2. EMBEDDING GENERATION
// ============================================================================

async function generateEmbeddings(chunks: Chunk[]): Promise<Chunk[]> {
  // Batch process for efficiency
  const batchSize = 100
  const chunksWithEmbeddings: Chunk[] = []

  for (let i = 0; i < chunks.length; i += batchSize) {
    const batch = chunks.slice(i, i + batchSize)

    const { embeddings } = await embedMany({
      model: openai.embedding('text-embedding-3-small'),
      values: batch.map(chunk => chunk.text)
    })

    chunksWithEmbeddings.push(
      ...batch.map((chunk, index) => ({
        ...chunk,
        embedding: embeddings[index]
      }))
    )

    // Rate limiting (if needed)
    if (i + batchSize < chunks.length) {
      await new Promise(resolve => setTimeout(resolve, 100))
    }
  }

  return chunksWithEmbeddings
}

// ============================================================================
// 3. VECTOR DATABASE STORAGE
// ============================================================================

interface VectorDB {
  upsert(chunks: Chunk[]): Promise<void>
  query(params: {
    vector: number[]
    topK: number
    filter?: Record<string, any>
  }): Promise<Array<Chunk & { score: number }>>
  delete(ids: string[]): Promise<void>
}

// Example: Pinecone implementation
class PineconeDB implements VectorDB {
  private index: any // Pinecone Index type

  constructor(indexName: string) {
    // Initialize Pinecone client
    const { Pinecone } = require('@pinecone-database/pinecone')
    const pinecone = new Pinecone({
      apiKey: process.env.PINECONE_API_KEY!
    })
    this.index = pinecone.index(indexName)
  }

  async upsert(chunks: Chunk[]): Promise<void> {
    await this.index.upsert(
      chunks.map(chunk => ({
        id: chunk.id,
        values: chunk.embedding!,
        metadata: {
          text: chunk.text,
          documentId: chunk.documentId,
          ...chunk.metadata
        }
      }))
    )
  }

  async query(params: {
    vector: number[]
    topK: number
    filter?: Record<string, any>
  }): Promise<Array<Chunk & { score: number }>> {
    const results = await this.index.query({
      vector: params.vector,
      topK: params.topK,
      includeMetadata: true,
      filter: params.filter
    })

    return results.matches.map((match: any) => ({
      id: match.id,
      documentId: match.metadata.documentId,
      text: match.metadata.text,
      metadata: match.metadata,
      score: match.score
    }))
  }

  async delete(ids: string[]): Promise<void> {
    await this.index.deleteMany(ids)
  }
}

// ============================================================================
// 4. RETRIEVAL
// ============================================================================

async function retrieveRelevantChunks(
  query: string,
  vectorDB: VectorDB,
  options: {
    topK?: number
    filter?: Record<string, any>
    rerankModel?: boolean
  } = {}
): Promise<Array<Chunk & { score: number }>> {
  const { topK = 5, filter, rerankModel = false } = options

  // Generate query embedding
  const { embedding } = await embed({
    model: openai.embedding('text-embedding-3-small'),
    value: query
  })

  // Vector search
  const results = await vectorDB.query({
    vector: embedding,
    topK: rerankModel ? topK * 2 : topK, // Get more if re-ranking
    filter
  })

  // Optional: Re-rank results using LLM
  if (rerankModel) {
    return await rerankResults(query, results, topK)
  }

  return results
}

async function rerankResults(
  query: string,
  results: Array<Chunk & { score: number }>,
  topK: number
): Promise<Array<Chunk & { score: number }>> {
  // Use LLM to re-rank results based on relevance
  const { object } = await generateText({
    model: openai('gpt-4o'),
    messages: [
      {
        role: 'system',
        content: 'Rank these documents by relevance to the query. Return indices in order from most to least relevant.'
      },
      {
        role: 'user',
        content: `Query: ${query}\n\nDocuments:\n${results.map((r, i) => `${i}: ${r.text.slice(0, 200)}...`).join('\n\n')}`
      }
    ]
  })

  // Parse ranked indices from response
  const rankedIndices = object // Implement parsing logic
  return rankedIndices.slice(0, topK).map((i: number) => results[i])
}

// ============================================================================
// 5. ANSWER GENERATION
// ============================================================================

async function generateAnswer(
  query: string,
  context: Array<Chunk & { score: number }>,
  options: {
    model?: string
    includeSources?: boolean
    temperature?: number
  } = {}
): Promise<{
  answer: string
  sources?: Array<{ documentId: string; title?: string; score: number }>
}> {
  const {
    model = 'gpt-4o',
    includeSources = true,
    temperature = 0.3
  } = options

  const contextText = context
    .map(
      (chunk, i) =>
        `[Source ${i + 1}]\n${chunk.metadata.title || chunk.documentId}\n\n${chunk.text}`
    )
    .join('\n\n---\n\n')

  const { text } = await generateText({
    model: openai(model),
    temperature,
    messages: [
      {
        role: 'system',
        content: `You are a helpful assistant that answers questions based on the provided context.

Rules:
1. Only use information from the provided context
2. If the answer is not in the context, say "I don't have enough information to answer that question."
3. Cite sources using [Source N] notation
4. Be concise and accurate`
      },
      {
        role: 'user',
        content: `Context:\n\n${contextText}\n\nQuestion: ${query}`
      }
    ]
  })

  const result: any = { answer: text }

  if (includeSources) {
    result.sources = context.map(chunk => ({
      documentId: chunk.documentId,
      title: chunk.metadata.title,
      score: chunk.score
    }))
  }

  return result
}

// ============================================================================
// 6. COMPLETE RAG PIPELINE
// ============================================================================

export async function ragPipeline(
  query: string,
  vectorDB: VectorDB,
  options: {
    topK?: number
    filter?: Record<string, any>
    rerankModel?: boolean
    model?: string
    includeSources?: boolean
  } = {}
) {
  // Retrieve relevant chunks
  const relevantChunks = await retrieveRelevantChunks(query, vectorDB, {
    topK: options.topK,
    filter: options.filter,
    rerankModel: options.rerankModel
  })

  // Generate answer
  const result = await generateAnswer(query, relevantChunks, {
    model: options.model,
    includeSources: options.includeSources
  })

  return result
}

// ============================================================================
// 7. DOCUMENT INDEXING PIPELINE
// ============================================================================

export async function indexDocuments(
  documents: Document[],
  vectorDB: VectorDB,
  options: {
    chunkSize?: number
    overlap?: number
    strategy?: 'fixed' | 'semantic' | 'recursive'
  } = {}
) {
  const {
    chunkSize = 500,
    overlap = 50,
    strategy = 'semantic'
  } = options

  console.log(`Indexing ${documents.length} documents...`)

  for (const doc of documents) {
    // Chunk document
    const chunks = await chunkDocument(doc, { chunkSize, overlap, strategy })
    console.log(`  ${doc.id}: ${chunks.length} chunks`)

    // Generate embeddings
    const chunksWithEmbeddings = await generateEmbeddings(chunks)

    // Store in vector DB
    await vectorDB.upsert(chunksWithEmbeddings)
  }

  console.log('Indexing complete!')
}

// ============================================================================
// 8. USAGE EXAMPLE
// ============================================================================

/*
// Initialize vector database
const vectorDB = new PineconeDB('knowledge-base')

// Index documents
await indexDocuments([
  {
    id: 'doc-1',
    content: 'Your document content...',
    metadata: {
      source: 'example.pdf',
      title: 'Example Document'
    }
  }
], vectorDB)

// Query
const result = await ragPipeline(
  'What is the main topic?',
  vectorDB,
  {
    topK: 5,
    rerankModel: true,
    includeSources: true
  }
)

console.log(result.answer)
console.log(result.sources)
*/
