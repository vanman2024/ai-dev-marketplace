#!/usr/bin/env python3
"""
Source Code Chunking

Specialized chunking for source code that preserves:
- Function and class definitions
- Docstrings with their implementations
- Import statements
- Comments
"""

import argparse
import json
import sys
import re
from typing import List, Dict, Tuple


# Language-specific patterns
LANGUAGE_PATTERNS = {
    'python': {
        'class': r'^class\s+\w+',
        'function': r'^def\s+\w+',
        'async_function': r'^async\s+def\s+\w+',
        'separators': ['\nclass ', '\ndef ', '\nasync def ', '\n\n', '\n']
    },
    'javascript': {
        'class': r'^class\s+\w+',
        'function': r'^function\s+\w+',
        'const_func': r'^const\s+\w+\s*=\s*(?:async\s*)?\(',
        'separators': ['\nclass ', '\nfunction ', '\nconst ', '\nlet ', '\n\n', '\n']
    },
    'typescript': {
        'class': r'^(?:export\s+)?class\s+\w+',
        'interface': r'^(?:export\s+)?interface\s+\w+',
        'function': r'^(?:export\s+)?function\s+\w+',
        'const_func': r'^(?:export\s+)?const\s+\w+\s*=',
        'separators': ['\nexport class ', '\nclass ', '\ninterface ', '\nfunction ', '\nconst ', '\n\n', '\n']
    },
    'java': {
        'class': r'^(?:public\s+)?class\s+\w+',
        'interface': r'^(?:public\s+)?interface\s+\w+',
        'method': r'^\s+(?:public|private|protected)\s+\w+\s+\w+\s*\(',
        'separators': ['\npublic class ', '\nclass ', '\npublic interface ', '\n\n', '\n']
    },
    'go': {
        'type': r'^type\s+\w+\s+struct',
        'function': r'^func\s+\w+',
        'method': r'^func\s+\(\w+\s+\*?\w+\)\s+\w+',
        'separators': ['\ntype ', '\nfunc ', '\n\n', '\n']
    }
}


class CodeChunker:
    """Source code aware chunking."""

    def __init__(self, language: str = 'python', chunk_size: int = 1000,
                 preserve_functions: bool = True, include_imports: bool = True):
        """
        Initialize code chunker.

        Args:
            language: Programming language
            chunk_size: Target chunk size
            preserve_functions: Keep complete functions together
            include_imports: Add imports to each chunk
        """
        self.language = language.lower()
        self.chunk_size = chunk_size
        self.preserve_functions = preserve_functions
        self.include_imports = include_imports

        if self.language not in LANGUAGE_PATTERNS:
            raise ValueError(f"Unsupported language: {language}")

        self.patterns = LANGUAGE_PATTERNS[self.language]

    def chunk(self, code: str, metadata: Dict = None) -> List[Dict]:
        """
        Chunk source code.

        Args:
            code: Source code text
            metadata: Optional metadata

        Returns:
            List of chunks with metadata
        """
        if metadata is None:
            metadata = {}

        # Extract imports/headers
        imports = self._extract_imports(code)

        # Parse code structure
        blocks = self._parse_code_blocks(code)

        # Create chunks from blocks
        chunks = self._create_chunks_from_blocks(blocks, imports)

        # Format output
        result = []
        for i, (chunk_text, chunk_meta) in enumerate(chunks):
            result.append({
                "text": chunk_text.strip(),
                "metadata": {
                    **metadata,
                    **chunk_meta,
                    "chunk_id": i,
                    "chunk_size": len(chunk_text),
                    "language": self.language,
                    "strategy": "code"
                }
            })

        return result

    def _extract_imports(self, code: str) -> str:
        """Extract import statements."""
        imports = []
        lines = code.split('\n')

        if self.language == 'python':
            for line in lines:
                if line.strip().startswith(('import ', 'from ')):
                    imports.append(line)
                elif imports and not line.strip():
                    # Empty line after imports
                    break
                elif imports and not line.strip().startswith('#'):
                    # Non-import, non-comment line
                    break

        elif self.language in ['javascript', 'typescript']:
            for line in lines:
                if line.strip().startswith(('import ', 'require(')):
                    imports.append(line)
                elif imports and not line.strip():
                    break

        elif self.language == 'java':
            for line in lines:
                if line.strip().startswith('import '):
                    imports.append(line)
                elif imports and not line.strip():
                    break

        elif self.language == 'go':
            in_import_block = False
            for line in lines:
                if line.strip().startswith('import ('):
                    in_import_block = True
                    imports.append(line)
                elif in_import_block:
                    imports.append(line)
                    if line.strip() == ')':
                        break
                elif line.strip().startswith('import '):
                    imports.append(line)

        return '\n'.join(imports)

    def _parse_code_blocks(self, code: str) -> List[Tuple[str, str, int]]:
        """
        Parse code into logical blocks (classes, functions, etc.).

        Returns:
            List of (block_type, block_content, start_pos) tuples
        """
        blocks = []

        # Use recursive splitting with language-specific separators
        separators = self.patterns['separators']
        chunks = self._recursive_split(code, separators)

        for chunk in chunks:
            # Identify block type
            block_type = self._identify_block_type(chunk)
            blocks.append((block_type, chunk, 0))

        return blocks

    def _recursive_split(self, text: str, separators: List[str]) -> List[str]:
        """Recursively split code using separator hierarchy."""
        if not separators or len(text) <= self.chunk_size:
            return [text] if text else []

        separator = separators[0]
        remaining = separators[1:]

        if not separator:
            # Character-level split
            return [text[i:i+self.chunk_size] for i in range(0, len(text), self.chunk_size)]

        splits = text.split(separator)
        chunks = []
        current = ""

        for split in splits:
            test = current + separator + split if current else split

            if len(test) <= self.chunk_size:
                current = test
            else:
                if current:
                    chunks.append(current)

                if len(split) > self.chunk_size:
                    # Split is too large - recurse
                    sub_chunks = self._recursive_split(split, remaining)
                    chunks.extend(sub_chunks)
                    current = ""
                else:
                    current = split

        if current:
            chunks.append(current)

        return chunks

    def _identify_block_type(self, code: str) -> str:
        """Identify the type of code block."""
        code_stripped = code.strip()

        # Check patterns in order of specificity
        for block_type, pattern in self.patterns.items():
            if block_type == 'separators':
                continue

            if re.match(pattern, code_stripped, re.MULTILINE):
                return block_type

        return 'other'

    def _create_chunks_from_blocks(self, blocks: List[Tuple],
                                    imports: str) -> List[Tuple[str, Dict]]:
        """Create chunks from code blocks."""
        chunks = []
        current_chunk = []
        current_size = 0

        # Add imports size if including them
        import_size = len(imports) + 2 if self.include_imports and imports else 0

        for block_type, block_content, _ in blocks:
            block_size = len(block_content)

            # Check if block fits in current chunk
            total_size = current_size + block_size + import_size

            if total_size <= self.chunk_size or not current_chunk:
                # Add to current chunk
                current_chunk.append(block_content)
                current_size += block_size
            else:
                # Save current chunk
                chunk_text = self._format_chunk(current_chunk, imports)
                chunks.append((chunk_text, {
                    "block_types": self._get_block_types(current_chunk)
                }))

                # Start new chunk
                current_chunk = [block_content]
                current_size = block_size

        # Add final chunk
        if current_chunk:
            chunk_text = self._format_chunk(current_chunk, imports)
            chunks.append((chunk_text, {
                "block_types": self._get_block_types(current_chunk)
            }))

        return chunks

    def _format_chunk(self, blocks: List[str], imports: str) -> str:
        """Format a chunk with optional imports."""
        chunk_parts = []

        if self.include_imports and imports:
            chunk_parts.append(imports)

        chunk_parts.extend(blocks)

        return '\n\n'.join(chunk_parts)

    def _get_block_types(self, blocks: List[str]) -> List[str]:
        """Get types of blocks in chunk."""
        types = []
        for block in blocks:
            block_type = self._identify_block_type(block)
            if block_type not in types:
                types.append(block_type)
        return types


def main():
    parser = argparse.ArgumentParser(
        description="Source code chunking with structure preservation"
    )
    parser.add_argument(
        "input",
        help="Input source code file"
    )
    parser.add_argument(
        "--output", "-o",
        help="Output JSON file (default: stdout)"
    )
    parser.add_argument(
        "--language", "-l",
        choices=['python', 'javascript', 'typescript', 'java', 'go'],
        default='python',
        help="Programming language (default: python)"
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=1000,
        help="Target chunk size (default: 1000)"
    )
    parser.add_argument(
        "--no-preserve-functions",
        action="store_true",
        help="Allow splitting functions"
    )
    parser.add_argument(
        "--no-imports",
        action="store_true",
        help="Don't include imports in chunks"
    )

    args = parser.parse_args()

    try:
        # Read input
        with open(args.input, 'r', encoding='utf-8') as f:
            code = f.read()

        # Create chunker
        chunker = CodeChunker(
            language=args.language,
            chunk_size=args.chunk_size,
            preserve_functions=not args.no_preserve_functions,
            include_imports=not args.no_imports
        )

        # Chunk code
        chunks = chunker.chunk(code, metadata={"source": args.input})

        # Prepare output
        output = {
            "chunks": chunks,
            "total_chunks": len(chunks),
            "strategy": "code",
            "config": {
                "language": args.language,
                "chunk_size": args.chunk_size,
                "preserve_functions": not args.no_preserve_functions,
                "include_imports": not args.no_imports
            }
        }

        # Write output
        output_json = json.dumps(output, indent=2)

        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output_json)
            print(f"✓ Created {len(chunks)} chunks")
            print(f"✓ Language: {args.language}")
            print(f"✓ Output written to {args.output}")
        else:
            print(output_json)

    except FileNotFoundError:
        print(f"Error: File '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
