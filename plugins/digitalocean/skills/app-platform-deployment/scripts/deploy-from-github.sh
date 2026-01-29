#!/bin/bash
# Deploy app from GitHub repository
# Usage: ./deploy-from-github.sh <app-name> <github-repo> <branch>

APP_NAME=${1:-"my-app"}
REPO=${2:-"https://github.com/user/repo"}
BRANCH=${3:-"main"}

echo "🚀 Deploying $APP_NAME from $REPO ($BRANCH)"

# Create app spec
cat > /tmp/app-spec.yaml << EOF
name: $APP_NAME
services:
  - name: web
    github:
      repo: $REPO
      branch: $BRANCH
      deploy_on_push: true
    build_command: npm run build
    run_command: npm start
EOF

doctl apps create --spec /tmp/app-spec.yaml

echo "✅ App created. Check status with: doctl apps list"
