# Blog Post Content Prompt

Use this prompt template for generating blog posts with AI.

## Prompt Template

```
Write a comprehensive blog post about [TOPIC].

Topic: [SPECIFIC TOPIC]
Target Audience: [READER DESCRIPTION]
Tone: [informative/conversational/technical]
Length: [short: 500-800 words | medium: 800-1500 words | long: 1500-2500 words]
SEO Keywords: [KEYWORD 1], [KEYWORD 2], [KEYWORD 3]

Structure:
1. Engaging introduction with hook
2. 3-5 main sections with subheadings
3. Actionable takeaways
4. Conclusion with CTA

Include:
- Real-world examples
- Statistics (if applicable)
- Best practices
- Common mistakes to avoid
```

## Example Usage

```typescript
const blogPost = await generate_marketing_content({
  content_type: 'blog_post',
  topic: 'Getting started with Astro and Supabase',
  tone: 'informative',
  target_audience: 'Web developers new to Astro',
  length: 'medium',
  model: 'gemini-2.0-pro'
});
```

## Expected Output Structure

```markdown
# Getting Started with Astro and Supabase: A Developer's Guide

Building modern web applications requires the right tools...

## Why Combine Astro and Supabase?

Astro's static-first approach combined with Supabase's...

## Setting Up Your Project

Let's walk through the setup process step by step...

## Best Practices

Here are key practices to keep in mind...

## Conclusion

You now have a solid foundation for building...
```
