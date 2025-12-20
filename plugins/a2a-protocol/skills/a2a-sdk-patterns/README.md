# A2A SDK Patterns Skill

SDK installation and setup patterns for Agent-to-Agent Protocol across multiple programming languages.

## Overview

This skill provides comprehensive installation, configuration, and usage patterns for A2A Protocol SDKs in:
- Python (3.8+)
- TypeScript/JavaScript (Node 18+)
- Java (11+)
- C# (.NET 6+)
- Go (1.20+)

## Features

### Installation Scripts

Automated installation scripts for each language:
- `install-python.sh` - Install Python SDK via pip
- `install-typescript.sh` - Install TypeScript SDK via npm/yarn/pnpm
- `install-java.sh` - Install Java SDK via Maven/Gradle
- `install-csharp.sh` - Install C# SDK via NuGet
- `install-go.sh` - Install Go SDK via go get

### Validation Scripts

Verify SDK installation and configuration:
- `validate-python.sh` - Check Python SDK setup
- `validate-typescript.sh` - Check TypeScript SDK setup
- `validate-java.sh` - Check Java SDK setup
- `validate-csharp.sh` - Check C# SDK setup
- `validate-go.sh` - Check Go SDK setup

### Configuration Templates

Ready-to-use configuration templates:
- `env-template.txt` - Environment variable setup
- `python-config.py` - Python configuration example
- `typescript-config.ts` - TypeScript configuration example
- `java-config.xml` - Java Maven configuration
- `csharp-config.csproj` - C# project configuration
- `go-mod.txt` - Go module configuration

### Authentication Templates

Three authentication methods supported:
- `auth-api-key-template.txt` - API key authentication (simplest)
- `auth-oauth-template.txt` - OAuth 2.0 authentication (user-delegated)
- `auth-jwt-template.txt` - JWT authentication (service-to-service)

### Code Examples

Complete working examples for each language:
- `python-basic.py` - Basic Python usage
- `python-async.py` - Async Python usage
- `typescript-basic.ts` - Basic TypeScript usage
- `java-basic.java` - Basic Java usage
- `csharp-basic.cs` - Basic C# usage
- `go-basic.go` - Basic Go usage

### Error Handling Guides

Language-specific error handling patterns:
- `error-handling-python.md` - Python exception handling
- `error-handling-typescript.md` - TypeScript error handling
- `error-handling-java.md` - Java exception handling

## Quick Start

### Python

```bash
# Install SDK
./scripts/install-python.sh

# Verify installation
./scripts/validate-python.sh

# Set up environment
cp templates/env-template.txt .env
# Edit .env with your credentials

# Run example
python examples/python-basic.py
```

### TypeScript

```bash
# Install SDK
./scripts/install-typescript.sh

# Verify installation
./scripts/validate-typescript.sh

# Set up environment
cp templates/env-template.txt .env
# Edit .env with your credentials

# Run example
npx tsx examples/typescript-basic.ts
```

### Java

```bash
# Install SDK
./scripts/install-java.sh

# Verify installation
./scripts/validate-java.sh

# Set up environment
cp templates/env-template.txt .env
# Edit .env with your credentials

# Compile and run
javac examples/java-basic.java
java examples.BasicExample
```

### C#

```bash
# Install SDK
./scripts/install-csharp.sh

# Verify installation
./scripts/validate-csharp.sh

# Set up environment
cp templates/env-template.txt .env
# Edit .env with your credentials

# Run example
dotnet run examples/csharp-basic.cs
```

### Go

```bash
# Install SDK
./scripts/install-go.sh

# Verify installation
./scripts/validate-go.sh

# Set up environment
cp templates/env-template.txt .env
# Edit .env with your credentials

# Run example
go run examples/go-basic.go
```

## Security Best Practices

This skill follows strict security guidelines:

### Environment Variables

- **NEVER hardcode API keys** in source code
- Always use environment variables or secret management
- Create `.env.example` with placeholders only
- Add `.env` to `.gitignore`
- Use different keys for dev/staging/prod

### API Key Management

- Rotate keys regularly (every 90 days)
- Use different keys per environment
- Implement key expiration
- Monitor key usage for anomalies
- Revoke compromised keys immediately

### Network Security

- Always use HTTPS
- Validate SSL certificates
- Implement request signing for sensitive operations
- Use VPN/private networks for production

## Troubleshooting

### Installation Issues

If package installation fails:

```bash
# Python
pip install --upgrade pip
pip install a2a-protocol

# TypeScript
npm cache clean --force
npm install @a2a/protocol

# Java
mvn clean install -U

# C#
dotnet restore --force

# Go
go clean -modcache
go get -u github.com/a2a/protocol-go
```

### Authentication Errors

1. Check environment variables are set correctly
2. Verify API key format (no extra spaces/newlines)
3. Ensure base URL is correct
4. Check API key permissions
5. Review authentication template for your method

### Connection Issues

1. Verify network connectivity
2. Check firewall/proxy settings
3. Validate base URL is accessible
4. Review timeout settings in configuration

## Directory Structure

```
a2a-sdk-patterns/
├── SKILL.md                          # Skill manifest
├── README.md                         # This file
├── scripts/                          # Installation and validation scripts
│   ├── install-python.sh
│   ├── validate-python.sh
│   ├── install-typescript.sh
│   ├── validate-typescript.sh
│   ├── install-java.sh
│   ├── validate-java.sh
│   ├── install-csharp.sh
│   ├── validate-csharp.sh
│   ├── install-go.sh
│   └── validate-go.sh
├── templates/                        # Configuration templates
│   ├── env-template.txt
│   ├── python-config.py
│   ├── typescript-config.ts
│   ├── java-config.xml
│   ├── csharp-config.csproj
│   ├── go-mod.txt
│   ├── auth-api-key-template.txt
│   ├── auth-oauth-template.txt
│   └── auth-jwt-template.txt
└── examples/                         # Code examples
    ├── python-basic.py
    ├── python-async.py
    ├── typescript-basic.ts
    ├── java-basic.java
    ├── csharp-basic.cs
    ├── go-basic.go
    ├── error-handling-python.md
    ├── error-handling-typescript.md
    └── error-handling-java.md
```

## Resources

### Official Documentation

- [Python SDK Documentation](https://docs.a2a-protocol.org/python)
- [TypeScript SDK Documentation](https://docs.a2a-protocol.org/typescript)
- [Java SDK Documentation](https://docs.a2a-protocol.org/java)
- [C# SDK Documentation](https://docs.a2a-protocol.org/csharp)
- [Go SDK Documentation](https://docs.a2a-protocol.org/go)

### GitHub Repositories

- [Python SDK](https://github.com/a2a/protocol-python)
- [TypeScript SDK](https://github.com/a2a/protocol-ts)
- [Java SDK](https://github.com/a2a/protocol-java)
- [C# SDK](https://github.com/a2a/protocol-dotnet)
- [Go SDK](https://github.com/a2a/protocol-go)

## Version

- **Version:** 1.0.0
- **Protocol Compatibility:** A2A Protocol 1.0+
- **Last Updated:** 2025-12-20

## Contributing

This skill is part of the a2a-protocol plugin. For issues or improvements:

1. Check existing patterns in the skill
2. Review security guidelines
3. Test with all supported languages
4. Follow the established template structure

## License

Part of the A2A Protocol Plugin for Claude Code.
