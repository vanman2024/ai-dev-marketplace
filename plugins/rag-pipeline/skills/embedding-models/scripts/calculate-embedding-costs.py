#!/usr/bin/env python3
"""
Embedding Cost Calculator

Calculate and compare embedding costs across different providers and models.
"""

import argparse
from dataclasses import dataclass
from typing import List, Optional


@dataclass
class EmbeddingModel:
    """Embedding model with pricing information."""
    name: str
    provider: str
    dimensions: int
    cost_per_million_tokens: float
    description: str


# Pricing as of 2025 (update regularly)
MODELS = {
    'text-embedding-3-small': EmbeddingModel(
        name='text-embedding-3-small',
        provider='OpenAI',
        dimensions=1536,
        cost_per_million_tokens=0.02,
        description='Balanced performance and cost'
    ),
    'text-embedding-3-large': EmbeddingModel(
        name='text-embedding-3-large',
        provider='OpenAI',
        dimensions=3072,
        cost_per_million_tokens=0.13,
        description='Highest quality OpenAI model'
    ),
    'text-embedding-ada-002': EmbeddingModel(
        name='text-embedding-ada-002',
        provider='OpenAI',
        dimensions=1536,
        cost_per_million_tokens=0.10,
        description='Legacy OpenAI model'
    ),
    'embed-english-v3.0': EmbeddingModel(
        name='embed-english-v3.0',
        provider='Cohere',
        dimensions=1024,
        cost_per_million_tokens=0.10,
        description='Cohere English model'
    ),
    'embed-english-light-v3.0': EmbeddingModel(
        name='embed-english-light-v3.0',
        provider='Cohere',
        dimensions=384,
        cost_per_million_tokens=0.10,
        description='Cohere lightweight model'
    ),
    'embed-multilingual-v3.0': EmbeddingModel(
        name='embed-multilingual-v3.0',
        provider='Cohere',
        dimensions=1024,
        cost_per_million_tokens=0.10,
        description='Cohere multilingual model'
    ),
    'local-small': EmbeddingModel(
        name='all-MiniLM-L6-v2',
        provider='HuggingFace (Local)',
        dimensions=384,
        cost_per_million_tokens=0.0,
        description='Free local model - compute costs only'
    ),
    'local-medium': EmbeddingModel(
        name='all-mpnet-base-v2',
        provider='HuggingFace (Local)',
        dimensions=768,
        cost_per_million_tokens=0.0,
        description='Free local model - compute costs only'
    ),
    'local-large': EmbeddingModel(
        name='bge-large-en-v1.5',
        provider='HuggingFace (Local)',
        dimensions=1024,
        cost_per_million_tokens=0.0,
        description='Free local model - compute costs only'
    ),
}


def calculate_cost(
    num_documents: int,
    avg_tokens_per_doc: int,
    model: EmbeddingModel,
    cache_hit_rate: float = 0.0
) -> dict:
    """
    Calculate embedding costs for a given model and document volume.

    Args:
        num_documents: Total number of documents to embed
        avg_tokens_per_doc: Average tokens per document
        model: EmbeddingModel instance
        cache_hit_rate: Percentage of embeddings cached (0.0-1.0)

    Returns:
        Dictionary with cost breakdown
    """
    total_tokens = num_documents * avg_tokens_per_doc
    effective_tokens = total_tokens * (1 - cache_hit_rate)

    cost = (effective_tokens / 1_000_000) * model.cost_per_million_tokens

    return {
        'model': model.name,
        'provider': model.provider,
        'dimensions': model.dimensions,
        'total_documents': num_documents,
        'total_tokens': total_tokens,
        'effective_tokens': int(effective_tokens),
        'cache_hit_rate': cache_hit_rate,
        'cost_per_million': model.cost_per_million_tokens,
        'total_cost': cost,
        'cost_per_document': cost / num_documents if num_documents > 0 else 0,
        'description': model.description
    }


def format_cost(cost: float) -> str:
    """Format cost as currency string."""
    if cost == 0:
        return "$0.00 (Free)"
    elif cost < 0.01:
        return f"${cost:.4f}"
    elif cost < 1:
        return f"${cost:.3f}"
    else:
        return f"${cost:,.2f}"


def print_cost_analysis(result: dict):
    """Print formatted cost analysis."""
    print(f"\n{'='*70}")
    print(f"Model: {result['model']}")
    print(f"Provider: {result['provider']}")
    print(f"Description: {result['description']}")
    print(f"{'='*70}")
    print(f"Dimensions: {result['dimensions']}")
    print(f"Documents: {result['total_documents']:,}")
    print(f"Total Tokens: {result['total_tokens']:,}")

    if result['cache_hit_rate'] > 0:
        print(f"Cache Hit Rate: {result['cache_hit_rate']*100:.1f}%")
        print(f"Effective Tokens: {result['effective_tokens']:,}")

    print(f"\nCost per 1M tokens: {format_cost(result['cost_per_million'])}")
    print(f"Total Cost: {format_cost(result['total_cost'])}")
    print(f"Cost per Document: {format_cost(result['cost_per_document'])}")


def compare_models(
    num_documents: int,
    avg_tokens_per_doc: int,
    cache_hit_rate: float = 0.0
):
    """Compare costs across all available models."""
    print(f"\n{'='*90}")
    print(f"EMBEDDING COST COMPARISON")
    print(f"{'='*90}")
    print(f"Documents: {num_documents:,} | Avg Tokens/Doc: {avg_tokens_per_doc:,} | Cache Rate: {cache_hit_rate*100:.0f}%")
    print(f"{'='*90}")

    results = []
    for model_key, model in MODELS.items():
        result = calculate_cost(num_documents, avg_tokens_per_doc, model, cache_hit_rate)
        results.append(result)

    # Sort by total cost
    results.sort(key=lambda x: x['total_cost'])

    # Print header
    print(f"\n{'Model':<30} {'Provider':<20} {'Dims':<6} {'Total Cost':<15} {'$/Doc':<12}")
    print(f"{'-'*30} {'-'*20} {'-'*6} {'-'*15} {'-'*12}")

    for result in results:
        print(
            f"{result['model']:<30} "
            f"{result['provider']:<20} "
            f"{result['dimensions']:<6} "
            f"{format_cost(result['total_cost']):<15} "
            f"{format_cost(result['cost_per_document']):<12}"
        )

    print(f"\n{'='*90}")
    print("Note: Local models (HuggingFace) show $0 API costs but require compute resources.")
    print("Estimate GPU compute costs separately for local model deployment.")
    print(f"{'='*90}\n")


def main():
    parser = argparse.ArgumentParser(
        description='Calculate and compare embedding costs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Calculate cost for specific model
  %(prog)s --documents 100000 --avg-tokens 500 --model text-embedding-3-small

  # Compare all models
  %(prog)s --documents 100000 --avg-tokens 500 --compare

  # Include cache hit rate
  %(prog)s --documents 100000 --avg-tokens 500 --model text-embedding-3-small --cache-rate 0.3

  # Show available models
  %(prog)s --list-models
        """
    )

    parser.add_argument(
        '--documents',
        type=int,
        help='Number of documents to embed'
    )
    parser.add_argument(
        '--avg-tokens',
        type=int,
        help='Average tokens per document'
    )
    parser.add_argument(
        '--model',
        type=str,
        choices=list(MODELS.keys()),
        help='Embedding model to analyze'
    )
    parser.add_argument(
        '--compare',
        action='store_true',
        help='Compare all available models'
    )
    parser.add_argument(
        '--cache-rate',
        type=float,
        default=0.0,
        help='Cache hit rate (0.0-1.0). Default: 0.0'
    )
    parser.add_argument(
        '--list-models',
        action='store_true',
        help='List all available models'
    )

    args = parser.parse_args()

    # List models
    if args.list_models:
        print("\nAvailable Embedding Models:")
        print(f"{'='*90}")
        for key, model in MODELS.items():
            print(f"\n{key}")
            print(f"  Provider: {model.provider}")
            print(f"  Dimensions: {model.dimensions}")
            print(f"  Cost: {format_cost(model.cost_per_million_tokens)}/1M tokens")
            print(f"  Description: {model.description}")
        print(f"\n{'='*90}\n")
        return

    # Validate required arguments
    if not args.compare and (not args.documents or not args.avg_tokens or not args.model):
        parser.error('--documents, --avg-tokens, and --model are required (unless using --compare or --list-models)')

    if args.compare and (not args.documents or not args.avg_tokens):
        parser.error('--documents and --avg-tokens are required for comparison')

    # Validate cache rate
    if not 0.0 <= args.cache_rate <= 1.0:
        parser.error('--cache-rate must be between 0.0 and 1.0')

    # Run comparison
    if args.compare:
        compare_models(args.documents, args.avg_tokens, args.cache_rate)
    else:
        # Single model analysis
        model = MODELS[args.model]
        result = calculate_cost(args.documents, args.avg_tokens, model, args.cache_rate)
        print_cost_analysis(result)

        # Show savings with caching if applicable
        if args.cache_rate > 0:
            no_cache_result = calculate_cost(args.documents, args.avg_tokens, model, 0.0)
            savings = no_cache_result['total_cost'] - result['total_cost']
            print(f"\nSavings from {args.cache_rate*100:.0f}% cache rate: {format_cost(savings)}")
        print()


if __name__ == '__main__':
    main()
