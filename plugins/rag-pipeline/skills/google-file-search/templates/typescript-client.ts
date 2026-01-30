/**
 * Google File Search TypeScript Client Template
 *
 * Complete TypeScript implementation for Google File Search API with store management,
 * document upload, semantic search, and citation extraction.
 *
 * Security Note:
 *    NEVER hardcode API keys in this file. Always use environment variables:
 *    GOOGLE_API_KEY=your_google_api_key_here
 *
 * Installation:
 *    npm install @google/genai
 *
 * Usage:
 *    npx ts-node typescript-client.ts
 */

import { GoogleGenAI } from '@google/genai';

// =============================================================================
// TYPES
// =============================================================================

export interface FileSearchStore {
  name: string;
  displayName: string;
  createTime?: string;
  updateTime?: string;
}

export interface UploadConfig {
  displayName?: string;
  chunkingConfig?: {
    whiteSpaceConfig?: {
      maxTokensPerChunk?: number;
      maxOverlapTokens?: number;
    };
  };
  customMetadata?: Array<{
    key: string;
    stringValue?: string;
    numericValue?: number;
  }>;
}

export interface SearchResult {
  answer: string;
  sources: Array<{
    uri: string;
    title: string;
  }>;
}

// =============================================================================
// CLIENT CLASS
// =============================================================================

export class GoogleFileSearchClient {
  private ai: GoogleGenAI;
  private currentStore: string | null = null;

  /**
   * Initialize the File Search client.
   * @param apiKey - Google AI API key. If not provided, reads from GOOGLE_API_KEY env var.
   */
  constructor(apiKey?: string) {
    const key = apiKey || process.env.GOOGLE_API_KEY;
    if (!key) {
      throw new Error(
        'API key required. Set GOOGLE_API_KEY environment variable or pass apiKey parameter.\n' +
        'Get your key from: https://aistudio.google.com/apikey'
      );
    }
    this.ai = new GoogleGenAI({ apiKey: key });
  }

  // ---------------------------------------------------------------------------
  // Store Management
  // ---------------------------------------------------------------------------

  /**
   * Create a new file search store.
   * @param displayName - Human-readable name for the store
   * @returns Store name (ID) for use in other operations
   */
  async createStore(displayName: string): Promise<string> {
    const store = await this.ai.fileSearchStores.create({
      config: { displayName }
    });

    this.currentStore = store.name || null;
    console.log(`✅ Store created: ${displayName}`);
    console.log(`   Store ID: ${store.name}`);

    return store.name || '';
  }

  /**
   * List all file search stores.
   * @returns Array of store objects
   */
  async listStores(): Promise<FileSearchStore[]> {
    const response = await this.ai.fileSearchStores.list();
    const stores: FileSearchStore[] = [];

    if (response && typeof response[Symbol.asyncIterator] === 'function') {
      for await (const store of response) {
        stores.push({
          name: store.name || '',
          displayName: store.displayName || '',
          createTime: store.createTime,
          updateTime: store.updateTime
        });
      }
    }

    console.log(`📚 Found ${stores.length} store(s):`);
    for (const store of stores) {
      console.log(`   • ${store.displayName} (${store.name})`);
    }

    return stores;
  }

  /**
   * Get a specific store by ID.
   * @param storeName - Store identifier
   */
  async getStore(storeName: string): Promise<FileSearchStore> {
    const store = await this.ai.fileSearchStores.get({ name: storeName });
    this.currentStore = store.name || null;
    return {
      name: store.name || '',
      displayName: store.displayName || '',
      createTime: store.createTime,
      updateTime: store.updateTime
    };
  }

  /**
   * Delete a file search store.
   * @param storeName - Store ID to delete
   */
  async deleteStore(storeName: string): Promise<void> {
    await this.ai.fileSearchStores.delete({ name: storeName });
    console.log(`🗑️  Store deleted: ${storeName}`);

    if (this.currentStore === storeName) {
      this.currentStore = null;
    }
  }

  // ---------------------------------------------------------------------------
  // File Upload
  // ---------------------------------------------------------------------------

  /**
   * Upload and index a file to a file search store.
   *
   * Uses uploadToFileSearchStore() which uploads AND indexes in one operation.
   *
   * @param storeName - Target store ID
   * @param file - File path (string) or content (Buffer/Blob)
   * @param filename - Display name for the file
   * @param config - Optional upload configuration
   * @param waitForCompletion - Whether to wait for indexing (default: true)
   */
  async uploadFile(
    storeName: string,
    file: string | Buffer | Blob,
    filename: string,
    config?: UploadConfig,
    waitForCompletion: boolean = true
  ): Promise<void> {
    // Convert Buffer to Blob if needed
    let fileContent: string | Blob;
    if (Buffer.isBuffer(file)) {
      fileContent = new Blob([new Uint8Array(file)]);
    } else {
      fileContent = file;
    }

    console.log(`📤 Uploading: ${filename}`);

    let operation = await this.ai.fileSearchStores.uploadToFileSearchStore({
      file: fileContent,
      fileSearchStoreName: storeName,
      config: {
        displayName: config?.displayName || filename,
        ...(config?.chunkingConfig && {
          chunkingConfig: config.chunkingConfig
        }),
        ...(config?.customMetadata && {
          customMetadata: config.customMetadata
        })
      }
    });

    if (waitForCompletion) {
      console.log(`   ⏳ Indexing...`);
      const maxWait = 120000; // 2 minutes
      const start = Date.now();

      while (!operation.done) {
        if (Date.now() - start > maxWait) {
          throw new Error(`Upload timed out for: ${filename}`);
        }
        await new Promise(resolve => setTimeout(resolve, 2000));
        operation = await this.ai.operations.get({ operation });
      }

      console.log(`   ✅ Indexed: ${filename}`);
    }
  }

  /**
   * Upload multiple files to a store.
   * @param storeName - Target store ID
   * @param files - Array of file objects with path/content and filename
   */
  async uploadFiles(
    storeName: string,
    files: Array<{ file: string | Buffer | Blob; filename: string; config?: UploadConfig }>
  ): Promise<{ successful: string[]; failed: Array<{ filename: string; error: string }> }> {
    const successful: string[] = [];
    const failed: Array<{ filename: string; error: string }> = [];

    for (const { file, filename, config } of files) {
      try {
        await this.uploadFile(storeName, file, filename, config);
        successful.push(filename);
      } catch (error: any) {
        failed.push({ filename, error: error.message || 'Unknown error' });
      }
    }

    console.log(`📦 Batch upload complete: ${successful.length} succeeded, ${failed.length} failed`);
    return { successful, failed };
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /**
   * Execute semantic search using File Search tool.
   *
   * @param storeName - Target store ID
   * @param query - Natural language search query
   * @param options - Search options
   * @returns Search result with answer and sources
   */
  async search(
    storeName: string,
    query: string,
    options?: {
      model?: string;
      systemInstruction?: string;
    }
  ): Promise<SearchResult> {
    const model = options?.model || 'gemini-2.5-flash';

    console.log(`🔍 Searching: ${query}`);

    const response = await this.ai.models.generateContent({
      model,
      contents: query,
      config: {
        tools: [{
          fileSearch: {
            fileSearchStoreNames: [storeName]
          }
        }],
        ...(options?.systemInstruction && {
          systemInstruction: options.systemInstruction
        })
      }
    });

    // Extract sources from grounding metadata
    const candidate = response.candidates?.[0];
    const groundingMetadata = candidate?.groundingMetadata as any;

    const sources = groundingMetadata?.groundingChunks?.map((chunk: any) => ({
      uri: chunk.retrievedContext?.uri || '',
      title: chunk.retrievedContext?.title || ''
    })) || [];

    console.log(`✅ Response generated with ${sources.length} source(s)`);

    return {
      answer: response.text || '',
      sources
    };
  }
}

// =============================================================================
// EXAMPLE USAGE
// =============================================================================

async function main() {
  console.log('🚀 Google File Search Example\n');

  // Initialize client
  const client = new GoogleFileSearchClient();

  try {
    // Create a store
    const storeName = await client.createStore('Example RAG Store');

    // Upload a document (replace with actual file path)
    // await client.uploadFile(
    //   storeName,
    //   './document.pdf',
    //   'document.pdf',
    //   {
    //     chunkingConfig: {
    //       whiteSpaceConfig: {
    //         maxTokensPerChunk: 200,
    //         maxOverlapTokens: 20
    //       }
    //     },
    //     customMetadata: [
    //       { key: 'author', stringValue: 'Example Author' },
    //       { key: 'year', numericValue: 2024 }
    //     ]
    //   }
    // );

    // Search the store
    // const result = await client.search(
    //   storeName,
    //   'What are the main features?',
    //   { systemInstruction: 'Answer based on the documents. Cite sources.' }
    // );
    // console.log('\n💬 Answer:', result.answer);
    // console.log('📚 Sources:', result.sources);

    // List all stores
    await client.listStores();

    // Clean up (uncomment to delete)
    // await client.deleteStore(storeName);

    console.log('\n✅ Example complete!');

  } catch (error: any) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

export default GoogleFileSearchClient;
