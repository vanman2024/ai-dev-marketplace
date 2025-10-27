# CI/CD Integration Examples

This guide shows how to integrate schema validation into various CI/CD platforms.

---

## Table of Contents

1. [GitHub Actions](#github-actions)
2. [GitLab CI](#gitlab-ci)
3. [CircleCI](#circleci)
4. [Jenkins](#jenkins)
5. [Azure DevOps](#azure-devops)
6. [Bitbucket Pipelines](#bitbucket-pipelines)

---

## GitHub Actions

### Basic Validation

`.github/workflows/validate-schema.yml`:

```yaml
name: Validate Database Schema

on:
  pull_request:
    paths:
      - 'supabase/migrations/**/*.sql'
      - 'supabase/schema.sql'
  push:
    branches:
      - main
      - develop

jobs:
  validate-schema:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install PostgreSQL client
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Run schema validation
        run: |
          bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
            supabase/migrations/

      - name: Check validation results
        run: |
          if grep -q "ERROR" validation-report.md; then
            echo "::error::Schema validation failed with errors"
            cat validation-report.md
            exit 1
          elif grep -q "WARNING" validation-report.md; then
            echo "::warning::Schema validation passed with warnings"
            cat validation-report.md
          else
            echo "::notice::Schema validation passed"
          fi

      - name: Upload validation report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: validation-report
          path: validation-report.md
          retention-days: 30

      - name: Comment on PR
        if: github.event_name == 'pull_request' && always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('validation-report.md', 'utf8');

            // Find existing comment
            const { data: comments } = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
            });

            const botComment = comments.find(comment =>
              comment.user.login === 'github-actions[bot]' &&
              comment.body.includes('Schema Validation Report')
            );

            const commentBody = `## 🗄️ Schema Validation Report\n\n${report}`;

            if (botComment) {
              // Update existing comment
              await github.rest.issues.updateComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: botComment.id,
                body: commentBody
              });
            } else {
              // Create new comment
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
                body: commentBody
              });
            }
```

### Advanced Validation with Matrix

`.github/workflows/validate-schema-advanced.yml`:

```yaml
name: Advanced Schema Validation

on:
  pull_request:
    paths:
      - 'supabase/**/*.sql'

jobs:
  validate-individual-scripts:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        validator:
          - validate-sql-syntax.sh
          - validate-naming.sh
          - validate-constraints.sh
          - validate-indexes.sh
          - validate-rls.sh

    steps:
      - uses: actions/checkout@v4

      - name: Install PostgreSQL
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Run ${{ matrix.validator }}
        run: |
          for file in supabase/migrations/*.sql; do
            echo "Validating $file with ${{ matrix.validator }}"
            bash plugins/supabase/skills/schema-validation/scripts/${{ matrix.validator }} "$file" || true
          done

  validate-full:
    runs-on: ubuntu-latest
    needs: validate-individual-scripts

    steps:
      - uses: actions/checkout@v4

      - name: Run full validation
        run: |
          bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
            supabase/migrations/

      - name: Fail on errors
        run: |
          if grep -q "ERROR" validation-report.md; then
            exit 1
          fi

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: full-validation-report
          path: validation-report.md
```

---

## GitLab CI

`.gitlab-ci.yml`:

```yaml
stages:
  - validate
  - report

variables:
  POSTGRES_VERSION: "15"

schema-validation:
  stage: validate
  image: postgres:${POSTGRES_VERSION}
  before_script:
    - apt-get update && apt-get install -y bash grep
  script:
    - |
      bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
        supabase/migrations/
    - |
      if grep -q "ERROR" validation-report.md; then
        echo "Schema validation failed with errors"
        cat validation-report.md
        exit 1
      elif grep -q "WARNING" validation-report.md; then
        echo "Schema validation passed with warnings"
        cat validation-report.md
      else
        echo "Schema validation passed"
      fi
  artifacts:
    paths:
      - validation-report.md
    expire_in: 1 week
    when: always
  only:
    changes:
      - supabase/migrations/**/*.sql
      - supabase/schema.sql

schema-validation-report:
  stage: report
  image: alpine:latest
  dependencies:
    - schema-validation
  script:
    - cat validation-report.md
  artifacts:
    reports:
      dotenv: validation-report.md
  only:
    - merge_requests
```

---

## CircleCI

`.circleci/config.yml`:

```yaml
version: 2.1

orbs:
  postgres: circleci/postgres@2.0

jobs:
  validate-schema:
    docker:
      - image: cimg/base:stable
      - image: cimg/postgres:15.0

    steps:
      - checkout

      - run:
          name: Install dependencies
          command: |
            sudo apt-get update
            sudo apt-get install -y postgresql-client

      - run:
          name: Run schema validation
          command: |
            bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
              supabase/migrations/

      - run:
          name: Check validation results
          command: |
            if grep -q "ERROR" validation-report.md; then
              echo "Schema validation failed"
              cat validation-report.md
              exit 1
            fi

      - store_artifacts:
          path: validation-report.md
          destination: validation-report

      - store_test_results:
          path: validation-report.md

workflows:
  validate:
    jobs:
      - validate-schema:
          filters:
            branches:
              only:
                - main
                - develop
                - /feature\/.*/
```

---

## Jenkins

`Jenkinsfile`:

```groovy
pipeline {
    agent any

    environment {
        VALIDATION_SCRIPT = 'plugins/supabase/skills/schema-validation/scripts/full-validation.sh'
        MIGRATIONS_DIR = 'supabase/migrations'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y postgresql-client bash
                '''
            }
        }

        stage('Validate Schema') {
            steps {
                sh """
                    bash ${VALIDATION_SCRIPT} ${MIGRATIONS_DIR}
                """
            }
        }

        stage('Check Results') {
            steps {
                script {
                    def hasErrors = sh(
                        script: 'grep -q "ERROR" validation-report.md',
                        returnStatus: true
                    ) == 0

                    def hasWarnings = sh(
                        script: 'grep -q "WARNING" validation-report.md',
                        returnStatus: true
                    ) == 0

                    if (hasErrors) {
                        error("Schema validation failed with errors")
                    } else if (hasWarnings) {
                        unstable("Schema validation passed with warnings")
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'validation-report.md', allowEmptyArchive: true

            publishHTML([
                reportDir: '.',
                reportFiles: 'validation-report.md',
                reportName: 'Schema Validation Report',
                keepAll: true
            ])
        }

        failure {
            emailext(
                subject: "Schema Validation Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    Schema validation failed.

                    Check the validation report at:
                    ${env.BUILD_URL}Schema_20Validation_20Report
                """,
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

---

## Azure DevOps

`azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - supabase/migrations/**

pr:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - supabase/migrations/**

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UseNode@2
    inputs:
      version: '18.x'

  - script: |
      sudo apt-get update
      sudo apt-get install -y postgresql-client
    displayName: 'Install PostgreSQL Client'

  - script: |
      bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
        supabase/migrations/
    displayName: 'Run Schema Validation'

  - script: |
      if grep -q "ERROR" validation-report.md; then
        echo "##vso[task.logissue type=error]Schema validation failed with errors"
        cat validation-report.md
        exit 1
      elif grep -q "WARNING" validation-report.md; then
        echo "##vso[task.logissue type=warning]Schema validation passed with warnings"
        cat validation-report.md
      fi
    displayName: 'Check Validation Results'

  - task: PublishBuildArtifacts@1
    condition: always()
    inputs:
      pathToPublish: 'validation-report.md'
      artifactName: 'validation-report'
      publishLocation: 'Container'

  - task: PublishTestResults@2
    condition: always()
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: 'validation-report.md'
      failTaskOnFailedTests: true
```

---

## Bitbucket Pipelines

`bitbucket-pipelines.yml`:

```yaml
image: postgres:15

pipelines:
  pull-requests:
    '**':
      - step:
          name: Validate Database Schema
          caches:
            - postgres
          script:
            - apt-get update && apt-get install -y bash
            - |
              bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
                supabase/migrations/
            - |
              if grep -q "ERROR" validation-report.md; then
                echo "Schema validation failed"
                cat validation-report.md
                exit 1
              fi
          artifacts:
            - validation-report.md

  branches:
    main:
      - step:
          name: Validate Schema (Main)
          script:
            - apt-get update && apt-get install -y bash
            - |
              bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
                supabase/migrations/
            - |
              if grep -q "ERROR" validation-report.md; then
                exit 1
              fi
          artifacts:
            - validation-report.md

definitions:
  caches:
    postgres: /var/lib/postgresql/data
```

---

## Pre-Deployment Validation

### GitHub Actions - Deploy Only if Valid

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  validate:
    runs-on: ubuntu-latest
    outputs:
      validation-passed: ${{ steps.check.outputs.passed }}

    steps:
      - uses: actions/checkout@v4

      - name: Validate schema
        run: |
          bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
            supabase/migrations/

      - name: Check results
        id: check
        run: |
          if grep -q "ERROR" validation-report.md; then
            echo "passed=false" >> $GITHUB_OUTPUT
            exit 1
          else
            echo "passed=true" >> $GITHUB_OUTPUT
          fi

  deploy:
    needs: validate
    if: needs.validate.outputs.validation-passed == 'true'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Supabase
        run: |
          npx supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_PROJECT_ID: ${{ secrets.SUPABASE_PROJECT_ID }}
```

---

## Notifications

### Slack Notification on Failure

```yaml
- name: Notify Slack on failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "❌ Schema validation failed for ${{ github.repository }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Schema Validation Failed*\n\nRepository: ${{ github.repository }}\nBranch: ${{ github.ref }}\nCommit: ${{ github.sha }}"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## Best Practices

1. **Run on every PR** - Catch issues early
2. **Block merges on errors** - Prevent bad schemas from reaching main
3. **Allow warnings** - Don't block on warnings, just notify
4. **Cache dependencies** - Speed up validation runs
5. **Parallel validation** - Run individual validators in parallel
6. **Archive reports** - Keep historical validation data
7. **Notify team** - Alert on failures via Slack/email
8. **Require passing validation** - Before deployment to production

---

**Next Steps:**
- Choose your CI/CD platform
- Copy the appropriate configuration
- Customize for your project
- Test the validation pipeline
- Set up notifications
