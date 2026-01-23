---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are REQUIRED for every user story. Each story MUST have contract tests and integration tests written BEFORE implementation.

**AI Observability**: Every AI feature MUST include observability tasks for telemetry, evals, and monitoring.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Verb + Object + Path`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- **Verb-first naming**: MUST start with action verb (Create, Update, Delete, Configure, Implement, Add, Build, Setup, Integrate, Test, Validate, Deploy)
- Include exact file paths in descriptions

## Task Naming Convention (REQUIRED)

Every task MUST start with an action verb:

| Verb | Usage |
|------|-------|
| **Create** | New files, components, schemas |
| **Update** | Modify existing code/config |
| **Delete** | Remove deprecated code |
| **Configure** | Setup configuration/settings |
| **Implement** | Business logic, features |
| **Add** | Append to existing (middleware, routes) |
| **Build** | Construct complex components |
| **Setup** | Initialize infrastructure |
| **Integrate** | Connect systems/services |
| **Test** | Write or run tests |
| **Validate** | Verify correctness |
| **Deploy** | Production deployment |
| **Refactor** | Code restructuring |
| **Optimize** | Performance improvements |

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

<!-- 
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  
  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/
  
  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment
  
  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T004 Setup database schema and migrations framework
- [ ] T005 [P] Implement authentication/authorization framework
- [ ] T006 [P] Setup API routing and middleware structure
- [ ] T007 Create base models/entities that all stories depend on
- [ ] T008 Configure error handling and logging infrastructure
- [ ] T009 Setup environment configuration management

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (REQUIRED) ✅

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation (TDD)**

- [ ] T010 [P] [US1] Create contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T011 [P] [US1] Create integration test for [user journey] in tests/integration/test_[name].py
- [ ] T012 [P] [US1] Create unit tests for [service] in tests/unit/test_[name].py

### Implementation for User Story 1

- [ ] T013 [P] [US1] Create [Entity1] model in src/models/[entity1].py
- [ ] T014 [P] [US1] Create [Entity2] model in src/models/[entity2].py
- [ ] T015 [US1] Implement [Service] in src/services/[service].py (depends: T013, T014)
- [ ] T016 [US1] Implement [endpoint/feature] in src/[location]/[file].py
- [ ] T017 [US1] Add validation and error handling to [file].py
- [ ] T018 [US1] Configure logging for user story 1 operations

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 (REQUIRED) ✅

- [ ] T019 [P] [US2] Create contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T020 [P] [US2] Create integration test for [user journey] in tests/integration/test_[name].py
- [ ] T021 [P] [US2] Create unit tests for [service] in tests/unit/test_[name].py

### Implementation for User Story 2

- [ ] T022 [P] [US2] Create [Entity] model in src/models/[entity].py
- [ ] T023 [US2] Implement [Service] in src/services/[service].py
- [ ] T024 [US2] Implement [endpoint/feature] in src/[location]/[file].py
- [ ] T025 [US2] Integrate with User Story 1 components (if needed)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 (REQUIRED) ✅

- [ ] T026 [P] [US3] Create contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T027 [P] [US3] Create integration test for [user journey] in tests/integration/test_[name].py
- [ ] T028 [P] [US3] Create unit tests for [service] in tests/unit/test_[name].py

### Implementation for User Story 3

- [ ] T029 [P] [US3] Create [Entity] model in src/models/[entity].py
- [ ] T030 [US3] Implement [Service] in src/services/[service].py
- [ ] T031 [US3] Implement [endpoint/feature] in src/[location]/[file].py

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N-1: AI Observability & Evals (REQUIRED for AI features) 🤖

**Purpose**: Telemetry, evaluation, and monitoring for AI-powered features

> **CRITICAL**: If this feature uses AI (LLM, embeddings, agents), this phase is MANDATORY

### Telemetry Setup

- [ ] TXXX [P] Setup OpenTelemetry spans for AI calls in src/lib/telemetry/[feature].py
- [ ] TXXX [P] Configure LangSmith/LangFuse tracing in src/config/observability.py
- [ ] TXXX [P] Add latency and token tracking middleware in src/middleware/ai-metrics.py

### Evaluation Framework

- [ ] TXXX [P] Create eval dataset for [AI feature] in evals/datasets/[feature].json
- [ ] TXXX [P] Implement accuracy eval for [AI output] in evals/[feature]/test_accuracy.py
- [ ] TXXX [P] Implement quality eval (coherence, relevance) in evals/[feature]/test_quality.py
- [ ] TXXX Create baseline metrics in evals/baselines/[feature].json
- [ ] TXXX Setup eval runner script in scripts/run-evals.sh

### Monitoring & Alerts

- [ ] TXXX Configure Sentry AI tracing in src/config/sentry.py
- [ ] TXXX [P] Add error rate alerts for AI calls in infra/alerts/ai-monitoring.yaml
- [ ] TXXX [P] Create cost tracking dashboard config in infra/dashboards/ai-costs.json
- [ ] TXXX [P] Setup hallucination detection in src/lib/guardrails/hallucination.py

### Guardrails

- [ ] TXXX [P] Implement input validation for prompts in src/lib/guardrails/input.py
- [ ] TXXX [P] Implement output validation in src/lib/guardrails/output.py
- [ ] TXXX Add rate limiting for AI endpoints in src/middleware/rate-limit.py

**Checkpoint**: AI features should now have full observability, evals, and monitoring

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Update documentation in docs/
- [ ] TXXX Refactor shared utilities for cleaner code
- [ ] TXXX Optimize performance across all stories
- [ ] TXXX [P] Add E2E tests in tests/e2e/
- [ ] TXXX Implement security hardening (RLS, auth)
- [ ] TXXX Validate quickstart.md instructions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (REQUIRED):
Task: "Create contract test for [endpoint] in tests/contract/test_[name].py"
Task: "Create integration test for [user journey] in tests/integration/test_[name].py"
Task: "Create unit tests for [service] in tests/unit/test_[name].py"

# Launch all models for User Story 1 together:
Task: "Create [Entity1] model in src/models/[entity1].py"
Task: "Create [Entity2] model in src/models/[entity2].py"
```

## Task Naming Examples

**✅ CORRECT (Verb-first):**
- `Create User model in src/models/user.py`
- `Implement authentication service in src/services/auth.py`
- `Configure Supabase RLS policies in supabase/migrations/`
- `Add rate limiting middleware in src/middleware/rate-limit.py`
- `Setup OpenTelemetry tracing in src/lib/telemetry/`
- `Integrate Stripe webhooks in src/api/webhooks/stripe.py`
- `Test user registration flow in tests/integration/`
- `Validate API responses in tests/contract/`
- `Deploy to production environment`
- `Refactor database queries for performance`

**❌ WRONG (Missing verb or weak verb):**
- `User model in src/models/` → Should be "Create User model..."
- `Authentication service` → Should be "Implement authentication service..."
- `RLS policies` → Should be "Configure RLS policies..."
- `Rate limiting` → Should be "Add rate limiting..."
- `The user registration test` → Should be "Test user registration..."
- `Handle error responses` → Should be "Implement error handling..."

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
