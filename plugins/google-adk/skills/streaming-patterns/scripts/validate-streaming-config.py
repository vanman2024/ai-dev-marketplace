#!/usr/bin/env python3
"""
Validate ADK bidi-streaming RunConfig settings.

Usage:
    python validate-streaming-config.py <config_file.py>

Validates:
- Response modality configuration
- Session resumption settings
- Context window compression
- Audio configuration
- Streaming mode settings
"""

import sys
import ast
import argparse
from pathlib import Path
from typing import Dict, List, Any


class StreamingConfigValidator:
    """Validate ADK streaming configuration."""

    VALID_MODALITIES = {"TEXT", "AUDIO"}
    VALID_STREAMING_MODES = {"BIDI", "NONE"}

    def __init__(self, config_file: Path):
        self.config_file = config_file
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def validate(self) -> bool:
        """Run all validation checks."""
        if not self.config_file.exists():
            self.errors.append(f"Config file not found: {self.config_file}")
            return False

        try:
            with open(self.config_file) as f:
                content = f.read()
                tree = ast.parse(content)

            self._validate_imports(tree)
            self._validate_runconfig(tree, content)
            self._validate_modality_consistency(content)
            self._validate_session_config(content)

            return len(self.errors) == 0

        except SyntaxError as e:
            self.errors.append(f"Syntax error in config file: {e}")
            return False
        except Exception as e:
            self.errors.append(f"Validation error: {e}")
            return False

    def _validate_imports(self, tree: ast.AST) -> None:
        """Check for required imports."""
        required_imports = {
            "google.adk.agents.run_config": ["RunConfig", "StreamingMode"],
            "google.genai": ["types"]
        }

        found_imports = {}
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom):
                module = node.module
                names = [alias.name for alias in node.names]
                if module in found_imports:
                    found_imports[module].extend(names)
                else:
                    found_imports[module] = names

        for module, expected_names in required_imports.items():
            if module not in found_imports:
                self.errors.append(f"Missing import: from {module}")
            else:
                missing = set(expected_names) - set(found_imports[module])
                if missing:
                    self.warnings.append(
                        f"Missing imports from {module}: {', '.join(missing)}"
                    )

    def _validate_runconfig(self, tree: ast.AST, content: str) -> None:
        """Validate RunConfig instantiation."""
        has_runconfig = "RunConfig(" in content

        if not has_runconfig:
            self.errors.append("No RunConfig instantiation found")
            return

        # Check for streaming mode
        if "StreamingMode.BIDI" not in content:
            self.errors.append(
                "Missing streaming_mode=StreamingMode.BIDI for bidi-streaming"
            )

    def _validate_modality_consistency(self, content: str) -> None:
        """Validate response modality configuration."""
        # Check for response_modalities setting
        if "response_modalities" not in content:
            self.warnings.append(
                "No response_modalities specified (will use default)"
            )
            return

        # Count modality assignments
        if '["TEXT"]' in content and '["AUDIO"]' in content:
            self.errors.append(
                "CRITICAL: Multiple response modalities found. "
                "Only ONE modality per session is allowed!"
            )
        elif '["TEXT", "AUDIO"]' in content or '["AUDIO", "TEXT"]' in content:
            self.errors.append(
                "CRITICAL: Cannot use both TEXT and AUDIO modalities. "
                "Choose ONE per session!"
            )

        # Validate modality format
        for modality in self.VALID_MODALITIES:
            pattern = f'["{modality}"]'
            if pattern in content:
                # Valid format found
                break
        else:
            if "response_modalities" in content:
                self.warnings.append(
                    "Unusual response_modalities format detected"
                )

    def _validate_session_config(self, content: str) -> None:
        """Validate session management settings."""
        # Check for session resumption
        if "session_resumption" in content:
            if "SessionResumptionConfig" not in content:
                self.errors.append(
                    "session_resumption requires SessionResumptionConfig()"
                )

        # Check for context window compression
        if "context_window_compression" in content:
            if "ContextWindowCompressionConfig" not in content:
                self.errors.append(
                    "context_window_compression requires "
                    "ContextWindowCompressionConfig()"
                )

            # Validate compression parameters
            if "trigger_tokens" not in content:
                self.warnings.append(
                    "Context compression missing trigger_tokens parameter"
                )
            if "sliding_window" not in content and "SlidingWindow" not in content:
                self.warnings.append(
                    "Context compression missing sliding_window parameter"
                )

    def print_results(self) -> None:
        """Print validation results."""
        print(f"\n{'='*60}")
        print(f"Validation Results for: {self.config_file.name}")
        print(f"{'='*60}\n")

        if self.errors:
            print(f"❌ ERRORS ({len(self.errors)}):")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}")
            print()

        if self.warnings:
            print(f"⚠️  WARNINGS ({len(self.warnings)}):")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")
            print()

        if not self.errors and not self.warnings:
            print("✅ All validations passed!")
        elif not self.errors:
            print("✅ No critical errors (warnings only)")
        else:
            print(f"❌ Validation failed with {len(self.errors)} error(s)")

        print(f"\n{'='*60}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Validate ADK bidi-streaming configuration"
    )
    parser.add_argument(
        "config_file",
        type=Path,
        help="Path to Python config file containing RunConfig"
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as errors"
    )

    args = parser.parse_args()

    validator = StreamingConfigValidator(args.config_file)
    is_valid = validator.validate()
    validator.print_results()

    # Exit with error code if validation failed
    if not is_valid:
        sys.exit(1)
    if args.strict and validator.warnings:
        print("❌ Strict mode: Warnings treated as errors")
        sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main()
