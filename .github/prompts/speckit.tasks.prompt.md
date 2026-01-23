---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/check-prerequisites.sh --json` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (API endpoints), research.md (decisions), quickstart.md (test scenarios)
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Execute task generation workflow**:
   - Load plan.md and extract tech stack, libraries, project structure
   - Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)
   - If data-model.md exists: Extract entities and map to user stories
   - If contracts/ exists: Map endpoints to user stories
   - If research.md exists: Extract decisions for setup tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate dependency graph showing user story completion order
   - Create parallel execution examples per user story
   - Validate task completeness (each user story has all needed tasks, independently testable)

4. **Generate tasks.md**: Use `.specify.specify/templates/tasks-template.md` as structure, fill with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)

5. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Tests are REQUIRED**: Every user story MUST have tests (contract, integration, unit) written BEFORE implementation (TDD approach).

**AI Observability is REQUIRED**: If the feature uses AI (LLM, embeddings, agents), MUST include an AI Observability phase with telemetry, evals, and monitoring tasks.

**Verb-first naming is REQUIRED**: Every task MUST start with an action verb: Create, Update, Delete, Configure, Implement, Add, Build, Setup, Integrate, Test, Validate, Deploy, Refactor, Optimize.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Verb + Object + Path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label
   - User Story phases: MUST have story label
   - AI Observability phase: NO story label
   - Polish phase: NO story label
5. **Description**: MUST start with action verb, include object, and exact file path

**Action Verbs (use these)**:
| Verb | Usage |
|------|-------|
| Create | New files, components, schemas |
| Update | Modify existing code/config |
| Delete | Remove deprecated code |
| Configure | Setup configuration/settings |
| Implement | Business logic, features |
| Add | Append to existing (middleware, routes) |
| Build | Construct complex components |
| Setup | Initialize infrastructure |
| Integrate | Connect systems/services |
| Test | Write or run tests |
| Validate | Verify correctness |
| Deploy | Production deployment |
| Refactor | Code restructuring |
| Optimize | Performance improvements |

**Examples**:

- ✅ CORRECT: `- [ ] T001 Create project structure per implementation plan`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T010 [P] [US1] Create contract test for user API in tests/contract/test_user.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- ✅ CORRECT: `- [ ] T050 Setup OpenTelemetry tracing in src/lib/telemetry/ai.py`
- ✅ CORRECT: `- [ ] T055 Configure eval dataset in evals/datasets/chat.json`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)
- ❌ WRONG: `- [ ] T001 User model in src/models/` (missing verb - should be "Create User model")
- ❌ WRONG: `- [ ] T001 The authentication service` (missing verb - should be "Implement authentication service")

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each contract/endpoint → to the user story it serves
   - If tests requested: Each contract → contract test task [P] before implementation in that story's phase

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships → service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (REQUIRED) → Models → Services → Endpoints → Integration
  - Each phase should be a complete, independently testable increment
- **Phase N-1**: AI Observability (REQUIRED if feature uses AI - telemetry, evals, monitoring)
- **Final Phase**: Polish & Cross-Cutting Concerns

### Required Elements Per User Story

Every user story MUST include:
1. **Tests (REQUIRED)**: Contract tests, integration tests, unit tests - written BEFORE implementation
2. **Implementation**: Models, services, endpoints
3. **Checkpoint**: Verify story works independently before next story

### AI Observability Phase (REQUIRED for AI features)

If the feature uses LLM, embeddings, or AI agents, MUST include:
1. **Telemetry**: OpenTelemetry spans, LangSmith/LangFuse tracing, latency/token tracking
2. **Evals**: Eval datasets, accuracy tests, quality tests, baseline metrics
3. **Monitoring**: Sentry AI tracing, error rate alerts, cost tracking dashboards
4. **Guardrails**: Input validation, output validation, hallucination detection, rate limiting
