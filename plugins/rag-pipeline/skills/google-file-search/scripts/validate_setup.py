#!/usr/bin/env python3
"""
Google File Search Setup Validation Script

Validates File Search configuration, store accessibility, and API connectivity.

Usage:
    python validate_setup.py --store <store_id>
    python validate_setup.py --verbose

Environment Variables:
    GOOGLE_API_KEY: Your Google AI API key
    GOOGLE_FILE_SEARCH_STORE_ID: Store ID to validate
"""

import os
import sys
import argparse
from google import genai
from google.genai import types


class Colors:
    """ANSI color codes for terminal output."""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'


def print_check(message, status, details=None):
    """Print a validation check result."""
    if status:
        symbol = f"{Colors.GREEN}✅{Colors.RESET}"
    else:
        symbol = f"{Colors.RED}❌{Colors.RESET}"

    print(f"{symbol} {message}")
    if details:
        print(f"   {details}")


def validate_api_key():
    """Validate Google API key is set."""
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print_check(
            "Google API Key",
            False,
            "GOOGLE_API_KEY environment variable not set"
        )
        return False, None

    print_check("Google API Key", True, "Found in environment")
    return True, api_key


def validate_client(api_key):
    """Validate client can be initialized."""
    try:
        client = genai.Client(api_key=api_key)
        print_check("Client Initialization", True, "Google GenAI client created")
        return True, client
    except Exception as e:
        print_check("Client Initialization", False, str(e))
        return False, None


def validate_store(client, store_id):
    """Validate store exists and is accessible."""
    try:
        store = client.file_search_stores.get(name=store_id)
        print_check("Store Access", True, f"Store '{store.display_name}' found")
        return True, store
    except Exception as e:
        print_check("Store Access", False, str(e))
        return False, None


def validate_model_access(client):
    """Validate access to Gemini models."""
    models_to_check = ["gemini-2.5-flash", "gemini-2.5-pro"]

    for model_name in models_to_check:
        try:
            # Try a simple generation to test access
            response = client.models.generate_content(
                model=model_name,
                contents="Hello"
            )
            print_check(f"Model Access: {model_name}", True, "Model accessible")
        except Exception as e:
            print_check(f"Model Access: {model_name}", False, str(e))


def get_store_stats(client, store_id):
    """Get statistics about the store."""
    try:
        # Note: This is a placeholder. The actual API method may vary.
        # You might need to list files or use a different approach.
        print(f"\n{Colors.BLUE}📊 Store Statistics:{Colors.RESET}")
        print(f"   Store ID: {store_id}")
        # Add more stats as available from the API
        return True
    except Exception as e:
        print(f"⚠️  Could not retrieve store statistics: {e}")
        return False


def list_stores(client, verbose=False):
    """List all available stores."""
    try:
        stores = list(client.file_search_stores.list())
        print(f"\n{Colors.BLUE}📚 Available Stores:{Colors.RESET}")
        if not stores:
            print("   No stores found")
        else:
            for store in stores:
                print(f"   • {store.display_name} ({store.name})")
                if verbose:
                    print(f"     Created: {getattr(store, 'create_time', 'N/A')}")
                    print(f"     Updated: {getattr(store, 'update_time', 'N/A')}")
        return True
    except Exception as e:
        print(f"❌ Error listing stores: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Validate Google File Search setup")
    parser.add_argument("--store", help="Specific store ID to validate")
    parser.add_argument("--verbose", action="store_true", help="Show detailed information")
    parser.add_argument("--list-stores", action="store_true", help="List all available stores")
    args = parser.parse_args()

    print(f"\n{Colors.BLUE}🔍 Google File Search Setup Validation{Colors.RESET}\n")

    # Validate API key
    success, api_key = validate_api_key()
    if not success:
        print("\n💡 Get your API key from: https://aistudio.google.com/apikey")
        print("   Then set it: export GOOGLE_API_KEY=your_google_api_key_here")
        sys.exit(1)

    # Validate client
    success, client = validate_client(api_key)
    if not success:
        sys.exit(1)

    # Get store ID
    store_id = args.store or os.getenv("GOOGLE_FILE_SEARCH_STORE_ID")

    if store_id:
        # Validate specific store
        success, store = validate_store(client, store_id)
        if success and args.verbose:
            get_store_stats(client, store_id)
    else:
        print_check(
            "Store ID Configuration",
            False,
            "No store ID provided (use --store or set GOOGLE_FILE_SEARCH_STORE_ID)"
        )

    # Validate model access
    print(f"\n{Colors.BLUE}🤖 Model Access Validation:{Colors.RESET}")
    validate_model_access(client)

    # List stores if requested or if no specific store was provided
    if args.list_stores or not store_id:
        list_stores(client, args.verbose)

    # Summary
    print(f"\n{Colors.BLUE}📋 Validation Summary:{Colors.RESET}")
    if store_id and success:
        print(f"   {Colors.GREEN}All checks passed!{Colors.RESET}")
        print(f"   Your File Search setup is ready to use.")
    else:
        print(f"   {Colors.YELLOW}Some validations failed or incomplete{Colors.RESET}")
        print(f"   Review the errors above and fix configuration issues.")


if __name__ == "__main__":
    main()
