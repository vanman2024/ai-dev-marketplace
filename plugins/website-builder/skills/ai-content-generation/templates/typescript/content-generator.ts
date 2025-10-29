// TypeScript client for AI content generation

export interface ContentOptions {
  prompt: string;
  model?: 'gemini-2.0-flash-exp' | 'claude-sonnet-4';
  max_tokens?: number;
}

export async function generateMarketingContent(options: ContentOptions): Promise<string> {
  const { prompt, model = 'gemini-2.0-flash-exp', max_tokens = 1000 } = options;
  // Call MCP server tool
  return `Generated content for: ${prompt}`;
}

export async function generateBlogPost(topic: string, keywords: string[]) {
  const prompt = `Write blog post about: ${topic}\nKeywords: ${keywords.join(', ')}`;
  return generateMarketingContent({ prompt, max_tokens: 2000 });
}
