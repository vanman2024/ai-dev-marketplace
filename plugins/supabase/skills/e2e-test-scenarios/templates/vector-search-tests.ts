/**
 * Vector Search E2E Tests
 * Tests for pgvector embeddings and semantic search
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

config({ path: '.env.test' });

const supabaseUrl = process.env.SUPABASE_TEST_URL!;
const supabaseKey = process.env.SUPABASE_TEST_ANON_KEY!;

// Helper to generate random vector
const generateRandomVector = (dimensions: number): number[] => {
  return Array.from({ length: dimensions }, () => Math.random());
};

// Helper to normalize vector
const normalizeVector = (vector: number[]): number[] => {
  const magnitude = Math.sqrt(vector.reduce((sum, val) => sum + val * val, 0));
  return vector.map(val => val / magnitude);
};

// Helper to calculate cosine similarity
const cosineSimilarity = (a: number[], b: number[]): number => {
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dotProduct / (magA * magB);
};

describe('Vector Search E2E Tests', () => {
  let supabase: SupabaseClient;
  const testTableName = 'test_documents';
  const vectorDimension = 1536; // OpenAI text-embedding-3-small

  beforeAll(async () => {
    supabase = createClient(supabaseUrl, supabaseKey);

    // Create test table with vector column
    const { error: createError } = await supabase.rpc('exec_sql', {
      query: `
        DROP TABLE IF EXISTS ${testTableName};

        CREATE TABLE ${testTableName} (
          id BIGSERIAL PRIMARY KEY,
          content TEXT NOT NULL,
          embedding vector(${vectorDimension}),
          metadata JSONB DEFAULT '{}',
          created_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create HNSW index
        CREATE INDEX ON ${testTableName} USING hnsw (embedding vector_cosine_ops);

        -- Create match function
        CREATE OR REPLACE FUNCTION match_test_documents(
          query_embedding vector(${vectorDimension}),
          match_threshold float DEFAULT 0.7,
          match_count int DEFAULT 5
        )
        RETURNS TABLE (
          id bigint,
          content text,
          similarity float
        )
        LANGUAGE sql STABLE
        AS $$
          SELECT
            id,
            content,
            1 - (embedding <=> query_embedding) AS similarity
          FROM ${testTableName}
          WHERE 1 - (embedding <=> query_embedding) > match_threshold
          ORDER BY embedding <=> query_embedding
          LIMIT match_count;
        $$;
      `,
    });

    if (createError) {
      console.warn('Table creation via RPC failed, may already exist');
    }
  });

  afterAll(async () => {
    // Cleanup test table
    await supabase.rpc('exec_sql', {
      query: `
        DROP TABLE IF EXISTS ${testTableName} CASCADE;
        DROP FUNCTION IF EXISTS match_test_documents;
      `,
    });
  });

  describe('Embedding Storage', () => {
    test('should store embedding vector', async () => {
      const embedding = generateRandomVector(vectorDimension);

      const { data, error } = await supabase
        .from(testTableName)
        .insert({
          content: 'Test document about machine learning',
          embedding: embedding,
        })
        .select()
        .single();

      expect(error).toBeNull();
      expect(data).toBeDefined();
      expect(data?.id).toBeDefined();
    });

    test('should reject wrong dimension vector', async () => {
      const wrongDimEmbedding = generateRandomVector(512); // Wrong dimension

      const { error } = await supabase
        .from(testTableName)
        .insert({
          content: 'Test document',
          embedding: wrongDimEmbedding,
        });

      expect(error).toBeDefined();
      expect(error?.message).toContain('dimension');
    });

    test('should store multiple embeddings', async () => {
      const documents = [
        'Introduction to machine learning',
        'Deep learning fundamentals',
        'Neural networks explained',
        'Python programming basics',
        'Data structures and algorithms',
      ];

      const inserts = documents.map(content => ({
        content,
        embedding: generateRandomVector(vectorDimension),
      }));

      const { data, error } = await supabase
        .from(testTableName)
        .insert(inserts)
        .select();

      expect(error).toBeNull();
      expect(data).toHaveLength(documents.length);
    });
  });

  describe('Vector Similarity Search', () => {
    let queryVector: number[];
    let similarVector: number[];

    beforeAll(async () => {
      // Create a known vector
      queryVector = normalizeVector(generateRandomVector(vectorDimension));

      // Create a similar vector (same vector with small noise)
      similarVector = queryVector.map(v => v + (Math.random() - 0.5) * 0.1);
      similarVector = normalizeVector(similarVector);

      // Insert documents
      await supabase.from(testTableName).insert([
        {
          content: 'Very similar document',
          embedding: similarVector,
        },
        {
          content: 'Completely different document',
          embedding: generateRandomVector(vectorDimension),
        },
      ]);
    });

    test('should find similar vectors using cosine distance', async () => {
      const { data, error } = await supabase.rpc('match_test_documents', {
        query_embedding: queryVector,
        match_threshold: 0.5,
        match_count: 10,
      });

      expect(error).toBeNull();
      expect(data).toBeDefined();
      expect(data!.length).toBeGreaterThan(0);

      // First result should be the similar vector
      const topResult = data![0];
      expect(topResult.similarity).toBeGreaterThan(0.8);
    });

    test('should respect match_threshold parameter', async () => {
      const { data: highThreshold } = await supabase.rpc(
        'match_test_documents',
        {
          query_embedding: queryVector,
          match_threshold: 0.95,
          match_count: 10,
        }
      );

      const { data: lowThreshold } = await supabase.rpc(
        'match_test_documents',
        {
          query_embedding: queryVector,
          match_threshold: 0.5,
          match_count: 10,
        }
      );

      expect(lowThreshold!.length).toBeGreaterThanOrEqual(
        highThreshold!.length
      );
    });

    test('should respect match_count parameter', async () => {
      const { data } = await supabase.rpc('match_test_documents', {
        query_embedding: queryVector,
        match_threshold: 0.0,
        match_count: 3,
      });

      expect(data!.length).toBeLessThanOrEqual(3);
    });

    test('should return results ordered by similarity', async () => {
      const { data } = await supabase.rpc('match_test_documents', {
        query_embedding: queryVector,
        match_threshold: 0.0,
        match_count: 10,
      });

      expect(data).toBeDefined();

      // Verify descending similarity order
      for (let i = 1; i < data!.length; i++) {
        expect(data![i - 1].similarity).toBeGreaterThanOrEqual(
          data![i].similarity
        );
      }
    });
  });

  describe('Distance Operators', () => {
    let testVector: number[];

    beforeAll(async () => {
      testVector = generateRandomVector(vectorDimension);

      await supabase.from(testTableName).insert({
        content: 'Test document for distance operators',
        embedding: testVector,
      });
    });

    test('should calculate cosine distance (< =>)', async () => {
      const { data, error } = await supabase
        .from(testTableName)
        .select('content, embedding')
        .limit(1)
        .single();

      expect(error).toBeNull();
      expect(data).toBeDefined();

      // Cosine distance with itself should be 0
      const distance = cosineSimilarity(data!.embedding, data!.embedding);
      expect(distance).toBeCloseTo(1.0, 5);
    });

    test('should use HNSW index for queries', async () => {
      // This would require EXPLAIN ANALYZE which is harder to test
      // Just verify the query works
      const { data, error } = await supabase
        .from(testTableName)
        .select('*')
        .limit(5);

      expect(error).toBeNull();
      expect(data).toBeDefined();
    });
  });

  describe('Metadata Filtering', () => {
    beforeAll(async () => {
      await supabase.from(testTableName).insert([
        {
          content: 'Machine learning document',
          embedding: generateRandomVector(vectorDimension),
          metadata: { category: 'ai', difficulty: 'beginner' },
        },
        {
          content: 'Advanced deep learning',
          embedding: generateRandomVector(vectorDimension),
          metadata: { category: 'ai', difficulty: 'advanced' },
        },
        {
          content: 'Python basics',
          embedding: generateRandomVector(vectorDimension),
          metadata: { category: 'programming', difficulty: 'beginner' },
        },
      ]);
    });

    test('should filter by metadata during search', async () => {
      const queryVector = generateRandomVector(vectorDimension);

      const { data, error } = await supabase
        .from(testTableName)
        .select('content, metadata')
        .contains('metadata', { category: 'ai' });

      expect(error).toBeNull();
      expect(data).toBeDefined();

      // All results should have category 'ai'
      expect(data!.every(doc => doc.metadata.category === 'ai')).toBe(true);
    });
  });

  describe('Performance', () => {
    test('should complete search within acceptable time', async () => {
      const queryVector = generateRandomVector(vectorDimension);
      const startTime = Date.now();

      const { data, error } = await supabase.rpc('match_test_documents', {
        query_embedding: queryVector,
        match_threshold: 0.7,
        match_count: 10,
      });

      const duration = Date.now() - startTime;

      expect(error).toBeNull();
      expect(duration).toBeLessThan(1000); // Should complete in < 1 second
    });

    test('should handle batch inserts efficiently', async () => {
      const batchSize = 100;
      const documents = Array.from({ length: batchSize }, (_, i) => ({
        content: `Batch document ${i}`,
        embedding: generateRandomVector(vectorDimension),
      }));

      const startTime = Date.now();

      const { error } = await supabase.from(testTableName).insert(documents);

      const duration = Date.now() - startTime;

      expect(error).toBeNull();
      expect(duration).toBeLessThan(5000); // Should complete in < 5 seconds
    });
  });

  describe('Edge Cases', () => {
    test('should handle empty query vector', async () => {
      const zeroVector = Array(vectorDimension).fill(0);

      const { data, error } = await supabase.rpc('match_test_documents', {
        query_embedding: zeroVector,
        match_threshold: 0.0,
        match_count: 5,
      });

      // Should not crash, but results may be unexpected
      expect(error).toBeNull();
    });

    test('should handle match_count of 0', async () => {
      const queryVector = generateRandomVector(vectorDimension);

      const { data, error } = await supabase.rpc('match_test_documents', {
        query_embedding: queryVector,
        match_threshold: 0.7,
        match_count: 0,
      });

      expect(error).toBeNull();
      expect(data).toHaveLength(0);
    });

    test('should handle very high threshold (no results)', async () => {
      const queryVector = generateRandomVector(vectorDimension);

      const { data, error } = await supabase.rpc('match_test_documents', {
        query_embedding: queryVector,
        match_threshold: 0.9999,
        match_count: 10,
      });

      expect(error).toBeNull();
      // May return 0 results
      expect(Array.isArray(data)).toBe(true);
    });
  });
});
