---
description: Deploy Google ADK agents to Vertex AI, Cloud Run, or GKE
argument-hint: deployment-target
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Deploy Google ADK agents to Google Cloud platforms (Vertex AI, Cloud Run, or GKE) with proper configuration and validation

Core Principles:
- Detect project structure and deployment requirements
- Validate credentials and prerequisites before deployment
- Support multiple deployment targets
- Provide clear deployment status and URLs

Phase 1: Discovery
Goal: Understand project structure and deployment target

Actions:
- Parse $ARGUMENTS for deployment target (vertex-ai, cloud-run, gke, or auto-detect)
- Check for Google ADK project files
- Example: !{bash ls -la adk.yaml package.json pyproject.toml go.mod pom.xml 2>/dev/null}
- Detect project language and framework
- Load deployment configuration if exists
- Example: @adk.yaml

Phase 2: Validation
Goal: Verify prerequisites and credentials

Actions:
- Check if gcloud CLI is installed and authenticated
- Example: !{bash gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null}
- Verify Google Cloud project is set
- Example: !{bash gcloud config get-value project 2>/dev/null}
- Check for required deployment files (Dockerfile, k8s manifests, etc.)
- Validate ADK configuration is complete
- Load project context for agent

Phase 3: Planning
Goal: Determine deployment strategy

Actions:
- Based on $ARGUMENTS and detected configuration:
  - If "vertex-ai": Deploy as Vertex AI agent
  - If "cloud-run": Deploy as Cloud Run service
  - If "gke": Deploy to Google Kubernetes Engine
  - If no target specified: Recommend based on project structure
- Identify required Google Cloud APIs to enable
- Check if deployment artifacts exist (container image, etc.)
- Present deployment plan to user

Phase 4: Deployment
Goal: Execute deployment with specialist agent

Actions:

Task(description="Deploy Google ADK agent", subagent_type="google-adk-deployment-specialist", prompt="You are the google-adk-deployment-specialist agent. Deploy the Google ADK agent for $ARGUMENTS.

Project Context:
- Project structure detected in Phase 1
- Deployment target: [vertex-ai/cloud-run/gke]
- Google Cloud project: [from gcloud config]
- Language/framework: [detected language]

Requirements:
- Build container image if needed
- Push to Google Container Registry or Artifact Registry
- Configure deployment settings (scaling, resources, environment variables)
- Deploy to target platform
- Set up monitoring and logging
- Configure IAM permissions if needed

Deliverable:
- Deployment status (success/failure)
- Service URL or endpoint
- Deployment configuration summary
- Next steps for testing and monitoring")

Phase 5: Verification
Goal: Confirm deployment succeeded

Actions:
- Check deployment status
- Verify service is running
- Example: !{bash gcloud run services list --filter="metadata.name:adk-agent" --format="value(status.url)" 2>/dev/null}
- Test health endpoint if available
- Display service logs for verification

Phase 6: Summary
Goal: Report deployment results and next steps

Actions:
- Display deployment summary:
  - Platform deployed to
  - Service URL/endpoint
  - Configuration applied
  - Resource allocation
- Show monitoring and logging commands
- Suggest next steps:
  - Test the deployed agent
  - Set up custom domain
  - Configure CI/CD pipeline
  - Enable additional monitoring
