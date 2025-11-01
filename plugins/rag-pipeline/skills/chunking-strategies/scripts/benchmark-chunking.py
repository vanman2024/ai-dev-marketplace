#!/usr/bin/env python3
"""
Chunking Strategy Benchmark Tool

Compares different chunking strategies and parameters to help
select the optimal approach for your documents.
"""

import argparse
import json
import sys
import time
from typing import List, Dict, Any
import statistics
import subprocess
import tempfile
import os


class ChunkingBenchmark:
    """Benchmark different chunking strategies."""

    def __init__(self, input_file: str):
        """
        Initialize benchmark.

        Args:
            input_file: Path to document to benchmark
        """
        self.input_file = input_file

        # Read input text
        with open(input_file, 'r', encoding='utf-8') as f:
            self.text = f.read()

        self.text_length = len(self.text)
        self.results = {}

    def run_fixed_size(self, chunk_size: int, overlap: int) -> Dict[str, Any]:
        """Benchmark fixed-size chunking."""
        start_time = time.time()

        # Create temporary output file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as tmp:
            tmp_path = tmp.name

        try:
            # Get script directory
            script_dir = os.path.dirname(os.path.abspath(__file__))
            chunker_script = os.path.join(script_dir, "chunk-fixed-size.py")

            # Run chunking script
            subprocess.run([
                "python3", chunker_script,
                "--input", self.input_file,
                "--output", tmp_path,
                "--chunk-size", str(chunk_size),
                "--overlap", str(overlap)
            ], check=True, capture_output=True)

            # Read results
            with open(tmp_path, 'r') as f:
                result = json.load(f)

            elapsed = (time.time() - start_time) * 1000  # Convert to ms

            # Calculate metrics
            chunks = result["chunks"]
            chunk_sizes = [c["metadata"]["chunk_size"] for c in chunks]

            return {
                "time_ms": round(elapsed, 2),
                "chunk_count": len(chunks),
                "avg_size": round(statistics.mean(chunk_sizes), 2),
                "size_variance": round(statistics.variance(chunk_sizes), 2) if len(chunk_sizes) > 1 else 0,
                "min_size": min(chunk_sizes),
                "max_size": max(chunk_sizes),
                "context_score": self._estimate_context_score(chunks),
                "config": {
                    "chunk_size": chunk_size,
                    "overlap": overlap
                }
            }

        finally:
            # Clean up temp file
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    def run_semantic(self, max_chunk_size: int) -> Dict[str, Any]:
        """Benchmark semantic chunking."""
        start_time = time.time()

        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as tmp:
            tmp_path = tmp.name

        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            chunker_script = os.path.join(script_dir, "chunk-semantic.py")

            subprocess.run([
                "python3", chunker_script,
                "--input", self.input_file,
                "--output", tmp_path,
                "--max-chunk-size", str(max_chunk_size)
            ], check=True, capture_output=True)

            with open(tmp_path, 'r') as f:
                result = json.load(f)

            elapsed = (time.time() - start_time) * 1000

            chunks = result["chunks"]
            chunk_sizes = [c["metadata"]["chunk_size"] for c in chunks]

            return {
                "time_ms": round(elapsed, 2),
                "chunk_count": len(chunks),
                "avg_size": round(statistics.mean(chunk_sizes), 2),
                "size_variance": round(statistics.variance(chunk_sizes), 2) if len(chunk_sizes) > 1 else 0,
                "min_size": min(chunk_sizes),
                "max_size": max(chunk_sizes),
                "context_score": self._estimate_context_score(chunks),
                "config": {
                    "max_chunk_size": max_chunk_size
                }
            }

        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    def run_recursive(self, chunk_size: int, overlap: int, preset: str = "text") -> Dict[str, Any]:
        """Benchmark recursive chunking."""
        start_time = time.time()

        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as tmp:
            tmp_path = tmp.name

        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            chunker_script = os.path.join(script_dir, "chunk-recursive.py")

            subprocess.run([
                "python3", chunker_script,
                "--input", self.input_file,
                "--output", tmp_path,
                "--chunk-size", str(chunk_size),
                "--overlap", str(overlap),
                "--preset", preset
            ], check=True, capture_output=True)

            with open(tmp_path, 'r') as f:
                result = json.load(f)

            elapsed = (time.time() - start_time) * 1000

            chunks = result["chunks"]
            chunk_sizes = [c["metadata"]["chunk_size"] for c in chunks]

            return {
                "time_ms": round(elapsed, 2),
                "chunk_count": len(chunks),
                "avg_size": round(statistics.mean(chunk_sizes), 2),
                "size_variance": round(statistics.variance(chunk_sizes), 2) if len(chunk_sizes) > 1 else 0,
                "min_size": min(chunk_sizes),
                "max_size": max(chunk_sizes),
                "context_score": self._estimate_context_score(chunks),
                "config": {
                    "chunk_size": chunk_size,
                    "overlap": overlap,
                    "preset": preset
                }
            }

        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    def _estimate_context_score(self, chunks: List[Dict]) -> float:
        """
        Estimate context preservation score (0-1).

        Heuristic based on:
        - Paragraph completeness (fewer mid-paragraph breaks)
        - Sentence completeness
        - Chunk size consistency
        """
        if not chunks:
            return 0.0

        score = 0.0
        total_checks = 0

        for chunk in chunks:
            text = chunk["text"]

            # Check if chunk ends with sentence-ending punctuation
            if text.rstrip().endswith(('.', '!', '?')):
                score += 1
            total_checks += 1

            # Check if chunk doesn't start/end mid-word
            if not text.startswith(' ') or len(text.split()[0]) > 2:
                score += 0.5
            total_checks += 0.5

            # Check for paragraph boundaries
            if '\n\n' in text:
                score += 0.5
            total_checks += 0.5

        return round(score / total_checks if total_checks > 0 else 0.0, 3)

    def run_all(self, strategies: List[str], chunk_sizes: List[int],
                overlaps: List[int] = None) -> Dict[str, Any]:
        """
        Run all requested benchmarks.

        Args:
            strategies: List of strategies to test (fixed, semantic, recursive)
            chunk_sizes: List of chunk sizes to test
            overlaps: List of overlap sizes (default: 20% of chunk size)

        Returns:
            Complete benchmark results
        """
        if overlaps is None:
            overlaps = [int(size * 0.2) for size in chunk_sizes]
        elif len(overlaps) == 1:
            overlaps = overlaps * len(chunk_sizes)

        results = {}

        for strategy in strategies:
            for i, chunk_size in enumerate(chunk_sizes):
                overlap = overlaps[i]

                test_name = f"{strategy}-{chunk_size}"
                print(f"Running: {test_name}...", end=" ", flush=True)

                try:
                    if strategy == "fixed":
                        result = self.run_fixed_size(chunk_size, overlap)
                    elif strategy == "semantic":
                        result = self.run_semantic(chunk_size)
                    elif strategy == "recursive":
                        result = self.run_recursive(chunk_size, overlap)
                    else:
                        print(f"Unknown strategy: {strategy}")
                        continue

                    results[test_name] = result
                    print(f"✓ ({result['time_ms']}ms, {result['chunk_count']} chunks)")

                except Exception as e:
                    print(f"✗ Error: {e}")
                    results[test_name] = {"error": str(e)}

        return results


def main():
    parser = argparse.ArgumentParser(
        description="Benchmark chunking strategies and parameters"
    )
    parser.add_argument(
        "--input", "-i",
        required=True,
        help="Input file to benchmark"
    )
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Output JSON file for results"
    )
    parser.add_argument(
        "--strategies",
        default="fixed,semantic,recursive",
        help="Comma-separated list of strategies (default: fixed,semantic,recursive)"
    )
    parser.add_argument(
        "--chunk-sizes",
        default="500,1000,1500",
        help="Comma-separated chunk sizes to test (default: 500,1000,1500)"
    )
    parser.add_argument(
        "--overlaps",
        help="Comma-separated overlap sizes (default: 20%% of chunk size)"
    )

    args = parser.parse_args()

    try:
        # Parse arguments
        strategies = [s.strip() for s in args.strategies.split(",")]
        chunk_sizes = [int(s.strip()) for s in args.chunk_sizes.split(",")]

        overlaps = None
        if args.overlaps:
            overlaps = [int(o.strip()) for o in args.overlaps.split(",")]

        # Run benchmark
        print(f"\n{'='*60}")
        print(f"Chunking Strategy Benchmark")
        print(f"{'='*60}")
        print(f"Input: {args.input}")
        print(f"Strategies: {', '.join(strategies)}")
        print(f"Chunk sizes: {', '.join(map(str, chunk_sizes))}")
        print(f"{'='*60}\n")

        benchmark = ChunkingBenchmark(args.input)
        results = benchmark.run_all(strategies, chunk_sizes, overlaps)

        # Find best strategy
        best_strategy = None
        best_score = 0

        for name, result in results.items():
            if "error" not in result:
                # Composite score: balance speed and context
                speed_score = 1 / (result["time_ms"] / 100)  # Normalize
                context_score = result["context_score"]
                composite = (speed_score * 0.3) + (context_score * 0.7)

                if composite > best_score:
                    best_score = composite
                    best_strategy = name

        # Write results
        output = {
            "input_file": args.input,
            "text_length": benchmark.text_length,
            "results": results,
            "recommendation": {
                "best_strategy": best_strategy,
                "best_config": results.get(best_strategy, {}).get("config", {}),
                "reason": "Optimal balance of speed and context preservation"
            }
        }

        with open(args.output, 'w') as f:
            json.dump(output, f, indent=2)

        # Print summary
        print(f"\n{'='*60}")
        print("RESULTS SUMMARY")
        print(f"{'='*60}")
        print(f"{'Strategy':<20} {'Time':<10} {'Chunks':<8} {'Context':<10}")
        print(f"{'-'*60}")

        for name, result in sorted(results.items()):
            if "error" not in result:
                print(f"{name:<20} {result['time_ms']:<10.1f} {result['chunk_count']:<8} {result['context_score']:<10.3f}")

        print(f"{'='*60}")
        print(f"\nRecommended: {best_strategy}")
        print(f"Output written to: {args.output}\n")

    except FileNotFoundError:
        print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: Invalid argument - {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
