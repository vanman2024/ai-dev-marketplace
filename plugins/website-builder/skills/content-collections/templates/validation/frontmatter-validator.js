// Validate frontmatter in Markdown files before build
import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';

export function validateFrontmatter(filePath, schema) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const { data } = matter(content);

  try {
    schema.parse(data);
    return { valid: true, errors: [] };
  } catch (error) {
    return {
      valid: false,
      errors: error.errors.map(e => ({
        path: e.path.join('.'),
        message: e.message
      }))
    };
  }
}

export function validateAllContent(contentDir, schema) {
  const files = fs.readdirSync(contentDir)
    .filter(f => f.endsWith('.md') || f.endsWith('.mdx'));

  const results = files.map(file => {
    const filePath = path.join(contentDir, file);
    const result = validateFrontmatter(filePath, schema);
    return { file, ...result };
  });

  const invalid = results.filter(r => !r.valid);

  if (invalid.length > 0) {
    console.error('❌ Frontmatter validation failed:');
    invalid.forEach(({ file, errors }) => {
      console.error(`  ${file}:`);
      errors.forEach(e => console.error(`    - ${e.path}: ${e.message}`));
    });
    process.exit(1);
  }

  console.log(`✅ All ${results.length} files have valid frontmatter`);
}
