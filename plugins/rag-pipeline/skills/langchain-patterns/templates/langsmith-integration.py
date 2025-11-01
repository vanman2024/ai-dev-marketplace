"""
LangSmith Integration Template
===============================

LangSmith integration for tracing, evaluation, and monitoring.

Features:
- Automatic tracing of chain executions
- Custom run names and tags
- Evaluation dataset creation
- Feedback collection
- Performance metrics tracking

Usage:
    from langsmith_integration import LangSmithTracer

    # Initialize tracer
    tracer = LangSmithTracer(
        project_name="rag-pipeline",
        tags=["production", "v1"]
    )

    # Trace chain execution
    with tracer.trace("rag-query"):
        result = chain.invoke({"query": "..."})

    # Add feedback
    tracer.add_feedback(run_id, score=1.0, comment="Good response")
"""

import os
from typing import Optional, List, Dict, Any, Union
from datetime import datetime
from contextlib import contextmanager

from langsmith import Client
from langsmith.schemas import Run, Example, Dataset
from langchain_core.tracers.langchain import LangChainTracer
from langchain_core.callbacks import CallbackManagerForChainRun


class LangSmithTracer:
    """
    LangSmith integration for tracing and evaluation.

    Provides utilities for tracing chain executions, creating evaluation
    datasets, collecting feedback, and monitoring performance.
    """

    def __init__(
        self,
        project_name: str = "default",
        tags: Optional[List[str]] = None,
        metadata: Optional[Dict[str, Any]] = None,
        api_key: Optional[str] = None
    ):
        """
        Initialize LangSmith tracer.

        Args:
            project_name: LangSmith project name
            tags: Tags to apply to all runs
            metadata: Metadata to apply to all runs
            api_key: LangSmith API key (defaults to LANGSMITH_API_KEY env var)
        """
        # Set API key
        if api_key:
            os.environ["LANGSMITH_API_KEY"] = api_key

        # Enable tracing
        os.environ["LANGSMITH_TRACING"] = "true"
        os.environ["LANGSMITH_PROJECT"] = project_name

        # Initialize client
        self.client = Client()
        self.project_name = project_name
        self.default_tags = tags or []
        self.default_metadata = metadata or {}

        # Create tracer
        self.tracer = LangChainTracer(
            project_name=project_name,
            client=self.client,
            tags=self.default_tags
        )

        print(f"✓ LangSmith tracer initialized for project: {project_name}")

    @contextmanager
    def trace(
        self,
        name: str,
        tags: Optional[List[str]] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """
        Context manager for tracing operations.

        Args:
            name: Name of the operation
            tags: Additional tags for this run
            metadata: Additional metadata for this run

        Yields:
            Run ID
        """
        # Combine tags and metadata
        all_tags = self.default_tags + (tags or [])
        all_metadata = {**self.default_metadata, **(metadata or {})}

        # Start run
        run = self.client.create_run(
            name=name,
            run_type="chain",
            tags=all_tags,
            extra=all_metadata
        )

        try:
            yield run.id
        except Exception as e:
            # Update run with error
            self.client.update_run(
                run_id=run.id,
                error=str(e),
                end_time=datetime.utcnow()
            )
            raise
        else:
            # Update run as successful
            self.client.update_run(
                run_id=run.id,
                end_time=datetime.utcnow()
            )

    def get_tracer(self):
        """
        Get LangChain tracer for use with chains.

        Returns:
            LangChainTracer instance
        """
        return self.tracer

    def add_feedback(
        self,
        run_id: str,
        score: Optional[float] = None,
        value: Optional[Union[str, int, float, bool]] = None,
        comment: Optional[str] = None,
        correction: Optional[Dict[str, Any]] = None
    ):
        """
        Add feedback to a run.

        Args:
            run_id: ID of the run
            score: Numeric score (0-1)
            value: Categorical or numeric value
            comment: Text comment
            correction: Corrected output
        """
        self.client.create_feedback(
            run_id=run_id,
            key="user_feedback",
            score=score,
            value=value,
            comment=comment,
            correction=correction
        )
        print(f"✓ Feedback added to run {run_id}")

    def create_dataset(
        self,
        dataset_name: str,
        description: Optional[str] = None,
        examples: Optional[List[Dict[str, Any]]] = None
    ) -> Dataset:
        """
        Create an evaluation dataset.

        Args:
            dataset_name: Name of the dataset
            description: Dataset description
            examples: List of example inputs/outputs

        Returns:
            Dataset object
        """
        # Create dataset
        dataset = self.client.create_dataset(
            dataset_name=dataset_name,
            description=description
        )
        print(f"✓ Dataset created: {dataset_name}")

        # Add examples if provided
        if examples:
            for example in examples:
                self.add_example_to_dataset(
                    dataset_name=dataset_name,
                    inputs=example.get("inputs", {}),
                    outputs=example.get("outputs")
                )
            print(f"✓ Added {len(examples)} examples to dataset")

        return dataset

    def add_example_to_dataset(
        self,
        dataset_name: str,
        inputs: Dict[str, Any],
        outputs: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """
        Add an example to a dataset.

        Args:
            dataset_name: Name of the dataset
            inputs: Example inputs
            outputs: Expected outputs (optional)
            metadata: Example metadata (optional)
        """
        self.client.create_example(
            dataset_name=dataset_name,
            inputs=inputs,
            outputs=outputs,
            metadata=metadata
        )

    def get_runs(
        self,
        limit: int = 100,
        offset: int = 0,
        tags: Optional[List[str]] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None
    ) -> List[Run]:
        """
        Get runs from the project.

        Args:
            limit: Maximum number of runs to return
            offset: Number of runs to skip
            tags: Filter by tags
            start_time: Filter by start time (after)
            end_time: Filter by end time (before)

        Returns:
            List of runs
        """
        runs = list(self.client.list_runs(
            project_name=self.project_name,
            limit=limit,
            offset=offset,
            filter=f"tags:{','.join(tags)}" if tags else None
        ))
        return runs

    def get_run_stats(
        self,
        tags: Optional[List[str]] = None,
        start_time: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Get statistics for runs.

        Args:
            tags: Filter by tags
            start_time: Filter by start time (after)

        Returns:
            Statistics dictionary
        """
        runs = self.get_runs(tags=tags, limit=1000)

        # Calculate statistics
        total_runs = len(runs)
        successful_runs = sum(1 for r in runs if r.error is None)
        failed_runs = total_runs - successful_runs

        # Calculate latencies (if available)
        latencies = []
        for run in runs:
            if run.end_time and run.start_time:
                latency = (run.end_time - run.start_time).total_seconds()
                latencies.append(latency)

        stats = {
            "total_runs": total_runs,
            "successful_runs": successful_runs,
            "failed_runs": failed_runs,
            "success_rate": successful_runs / total_runs if total_runs > 0 else 0
        }

        if latencies:
            stats["avg_latency"] = sum(latencies) / len(latencies)
            stats["min_latency"] = min(latencies)
            stats["max_latency"] = max(latencies)

        return stats

    def evaluate_dataset(
        self,
        dataset_name: str,
        evaluator_chain,
        evaluator_name: str = "accuracy"
    ):
        """
        Evaluate a chain against a dataset.

        Args:
            dataset_name: Name of the dataset
            evaluator_chain: Chain to evaluate
            evaluator_name: Name of the evaluator
        """
        from langsmith.evaluation import evaluate

        results = evaluate(
            lambda inputs: evaluator_chain.invoke(inputs),
            data=dataset_name,
            evaluators=[],  # Add custom evaluators here
            project_name=f"{self.project_name}-eval"
        )

        print(f"✓ Evaluation complete: {results}")
        return results


# Helper function for chain integration
def create_traced_chain(chain, tracer: LangSmithTracer):
    """
    Wrap a chain with LangSmith tracing.

    Args:
        chain: Chain to wrap
        tracer: LangSmith tracer instance

    Returns:
        Traced chain
    """
    # The tracer is automatically picked up from environment variables
    # Just ensure LANGSMITH_TRACING=true is set
    return chain


# Example usage
if __name__ == "__main__":
    import argparse
    from langchain_openai import ChatOpenAI
    from langchain_core.messages import HumanMessage

    parser = argparse.ArgumentParser(description="LangSmith Integration Example")
    parser.add_argument("--project", default="rag-pipeline", help="Project name")
    parser.add_argument("--query", default="What is LangChain?", help="Test query")
    parser.add_argument("--create-dataset", action="store_true", help="Create example dataset")
    parser.add_argument("--show-stats", action="store_true", help="Show run statistics")

    args = parser.parse_args()

    # Initialize tracer
    tracer = LangSmithTracer(
        project_name=args.project,
        tags=["example", "test"],
        metadata={"environment": "development"}
    )

    if args.create_dataset:
        # Create example dataset
        print("\nCreating dataset...")
        examples = [
            {
                "inputs": {"query": "What is LangChain?"},
                "outputs": {"answer": "LangChain is a framework for building LLM applications."}
            },
            {
                "inputs": {"query": "What is RAG?"},
                "outputs": {"answer": "RAG stands for Retrieval-Augmented Generation."}
            }
        ]

        dataset = tracer.create_dataset(
            dataset_name="rag-examples",
            description="Example RAG queries and answers",
            examples=examples
        )
        print(f"✓ Dataset created: {dataset.name}")

    if args.show_stats:
        # Show statistics
        print("\nGetting run statistics...")
        stats = tracer.get_run_stats()
        print("\nRun Statistics:")
        print(f"  Total runs: {stats['total_runs']}")
        print(f"  Successful: {stats['successful_runs']}")
        print(f"  Failed: {stats['failed_runs']}")
        print(f"  Success rate: {stats['success_rate']:.1%}")

        if "avg_latency" in stats:
            print(f"  Avg latency: {stats['avg_latency']:.2f}s")
            print(f"  Min latency: {stats['min_latency']:.2f}s")
            print(f"  Max latency: {stats['max_latency']:.2f}s")

    # Example traced execution
    print(f"\nExecuting traced query: {args.query}")
    print("-" * 50)

    llm = ChatOpenAI(model="gpt-4", temperature=0)

    with tracer.trace("example-query", tags=["demo"]) as run_id:
        response = llm.invoke([HumanMessage(content=args.query)])
        print(f"\nResponse: {response.content}")
        print(f"Run ID: {run_id}")

    # Add feedback
    print("\nAdding feedback...")
    tracer.add_feedback(
        run_id=run_id,
        score=1.0,
        comment="Good response for demo"
    )

    print("\n✓ Example complete")
    print(f"\nView traces at: https://smith.langchain.com/o/projects/{args.project}")
