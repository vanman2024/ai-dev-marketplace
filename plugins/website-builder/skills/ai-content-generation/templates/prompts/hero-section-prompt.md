# Hero Section Content Prompt

Use this prompt template with the content-image-generation MCP `generate_marketing_content` tool.

## Prompt Template

```
Generate a compelling hero section for a [PRODUCT/SERVICE] website.

Product/Service: [NAME]
Target Audience: [DESCRIPTION]
Key Benefits: [BENEFIT 1], [BENEFIT 2], [BENEFIT 3]
Tone: [professional/casual/technical/enthusiastic]

Include:
1. Attention-grabbing headline (8-12 words)
2. Supporting subheadline (15-25 words)
3. Call-to-action text (2-4 words)
4. Brief value proposition (1-2 sentences)

Make it:
- Clear and concise
- Benefit-focused
- Action-oriented
- Emotionally resonant
```

## Example Usage

```typescript
import { mcp__content-image-generation__generate_marketing_content } from 'mcp';

const heroContent = await generate_marketing_content({
  content_type: 'hero'
  topic: 'AI-powered project management tool'
  tone: 'professional'
  target_audience: 'Software development teams'
  length: 'short'
  model: 'claude-sonnet-4'
});
```

## Expected Output

```markdown
# Transform Chaos Into Clarity With AI

Stop juggling spreadsheets and endless meetings. Our AI-powered platform helps your team ship faster, collaborate better, and deliver exceptional results—automatically.

**Start Free Trial →**

Join 10,000+ teams who've already streamlined their workflow with intelligent automation.
```
