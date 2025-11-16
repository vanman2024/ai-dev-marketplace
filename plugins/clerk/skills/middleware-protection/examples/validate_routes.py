#!/usr/bin/env python3
"""
Route Validation Example (Python)

Validates Clerk middleware configuration and route protection setup.
Can be used in CI/CD pipelines to ensure security best practices.
"""

import json
import os
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple


class MiddlewareValidator:
    """Validates Clerk middleware configuration and route protection."""

    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root)
        self.middleware_path = self.project_root / "middleware.ts"
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def validate(self) -> Tuple[bool, List[str], List[str]]:
        """
        Run all validation checks.

        Returns:
            Tuple of (is_valid, errors, warnings)
        """
        self._check_middleware_exists()

        if self.middleware_path.exists():
            content = self.middleware_path.read_text()
            self._check_clerk_imports(content)
            self._check_route_matchers(content)
            self._check_security_patterns(content)
            self._check_matcher_config(content)

        self._check_env_variables()
        self._check_auth_pages()
        self._check_gitignore()

        is_valid = len(self.errors) == 0
        return is_valid, self.errors, self.warnings

    def _check_middleware_exists(self) -> None:
        """Check if middleware.ts exists."""
        if not self.middleware_path.exists():
            self.errors.append("middleware.ts not found in project root")

    def _check_clerk_imports(self, content: str) -> None:
        """Check for required Clerk imports."""
        if "from '@clerk/nextjs" not in content:
            self.errors.append("Missing Clerk imports from '@clerk/nextjs/server'")

        if "clerkMiddleware" not in content:
            self.errors.append("clerkMiddleware function not imported")

        if "createRouteMatcher" not in content:
            self.warnings.append("createRouteMatcher not used (recommended)")

    def _check_route_matchers(self, content: str) -> None:
        """Check for route matcher definitions."""
        # Check for public route matcher
        if "isPublicRoute" not in content and "publicRoutes" not in content:
            self.warnings.append("No public route matcher found")

        # Check for sign-in/sign-up in public routes
        public_routes_pattern = r"createRouteMatcher\(\[(.*?)\]\)"
        matches = re.findall(public_routes_pattern, content, re.DOTALL)

        if matches:
            public_routes = matches[0]
            if "/sign-in" not in public_routes:
                self.errors.append("Sign-in page must be public")
            if "/sign-up" not in public_routes:
                self.warnings.append("Sign-up page should be public")

    def _check_security_patterns(self, content: str) -> None:
        """Check for security best practices."""
        # Check for hardcoded API keys (basic check)
        api_key_patterns = [
            r"(sk|pk)_(test|live)_[a-zA-Z0-9]{20,}",
            r"clerk.*key.*=.*['\"][a-zA-Z0-9_-]{20,}['\"]",
        ]

        for pattern in api_key_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                self.errors.append("Possible hardcoded API key detected")
                break

        # Check for authentication validation
        if "userId" not in content and "auth()" not in content:
            self.warnings.append("No authentication state checking found")

        # Check for redirect on unauthorized
        if "redirect" not in content:
            self.warnings.append("No redirect logic found for unauthorized access")

    def _check_matcher_config(self, content: str) -> None:
        """Check matcher export configuration."""
        if "export const config" not in content:
            self.errors.append("Missing matcher config export")
            return

        if "matcher:" not in content and "matcher :" not in content:
            self.errors.append("Missing matcher property in config")

        # Check for proper static file exclusions
        if "_next" not in content:
            self.warnings.append("Matcher should exclude _next directory")

        if "api" not in content:
            self.warnings.append("API routes should be included in matcher")

    def _check_env_variables(self) -> None:
        """Check environment variable configuration."""
        env_files = [
            self.project_root / ".env.local",
            self.project_root / ".env",
        ]

        env_file_exists = any(f.exists() for f in env_files)

        if env_file_exists:
            for env_file in env_files:
                if env_file.exists():
                    content = env_file.read_text()

                    if "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" not in content:
                        self.errors.append(
                            f"Missing NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY in {env_file.name}"
                        )

                    if "CLERK_SECRET_KEY" not in content:
                        self.errors.append(
                            f"Missing CLERK_SECRET_KEY in {env_file.name}"
                        )

                    # Check for placeholder values
                    if "your_clerk" in content or "your_key_here" in content:
                        self.warnings.append(
                            f"Placeholder values found in {env_file.name}"
                        )
        else:
            self.warnings.append(
                "No .env file found (environment variables may be set elsewhere)"
            )

    def _check_auth_pages(self) -> None:
        """Check if authentication pages exist."""
        # Check for App Router structure
        app_dir = self.project_root / "app"
        if app_dir.exists():
            sign_in_paths = [
                app_dir / "sign-in" / "page.tsx",
                app_dir / "sign-in" / "page.ts",
            ]
            sign_up_paths = [
                app_dir / "sign-up" / "page.tsx",
                app_dir / "sign-up" / "page.ts",
            ]

            if not any(p.exists() for p in sign_in_paths):
                self.warnings.append("Sign-in page not found in app directory")

            if not any(p.exists() for p in sign_up_paths):
                self.warnings.append("Sign-up page not found in app directory")

        # Check for Pages Router structure
        pages_dir = self.project_root / "pages"
        if pages_dir.exists():
            sign_in_paths = [
                pages_dir / "sign-in.tsx",
                pages_dir / "sign-in.ts",
                pages_dir / "sign-in",
            ]
            sign_up_paths = [
                pages_dir / "sign-up.tsx",
                pages_dir / "sign-up.ts",
                pages_dir / "sign-up",
            ]

            if not any(p.exists() for p in sign_in_paths):
                self.warnings.append("Sign-in page not found in pages directory")

            if not any(p.exists() for p in sign_up_paths):
                self.warnings.append("Sign-up page not found in pages directory")

    def _check_gitignore(self) -> None:
        """Check .gitignore configuration."""
        gitignore_path = self.project_root / ".gitignore"

        if not gitignore_path.exists():
            self.errors.append(".gitignore not found")
            return

        content = gitignore_path.read_text()

        if ".env.local" not in content:
            self.errors.append(".env.local should be in .gitignore")

        if ".env" not in content and "*.env" not in content:
            self.warnings.append(".env files should be in .gitignore")

    def print_report(self) -> None:
        """Print validation report."""
        print("=" * 60)
        print("Clerk Middleware Validation Report")
        print("=" * 60)
        print()

        if self.errors:
            print("❌ ERRORS:")
            for error in self.errors:
                print(f"  - {error}")
            print()

        if self.warnings:
            print("⚠️  WARNINGS:")
            for warning in self.warnings:
                print(f"  - {warning}")
            print()

        if not self.errors and not self.warnings:
            print("✅ All checks passed!")
        elif not self.errors:
            print("✅ Validation passed with warnings")
        else:
            print("❌ Validation failed")

        print()


def main():
    """Run middleware validation."""
    import sys

    project_root = sys.argv[1] if len(sys.argv) > 1 else "."

    validator = MiddlewareValidator(project_root)
    is_valid, errors, warnings = validator.validate()
    validator.print_report()

    # Exit with error code if validation failed
    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()
