---
description: Validate complete AI Tech Stack 1 deployment
argument-hint: [app-directory]
allowed-tools: Read, Write, Bash(*), TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Validate AI Tech Stack 1 deployment (Next.js + Vercel AI SDK + Supabase + Mem0).

Core Principles:
- Check required files exist
- Verify integrations configured
- Run build and type checks
- Provide actionable fixes

Phase 1: Discovery
Goal: Determine app directory

Actions:
- Parse $ARGUMENTS for app directory (default: current directory)
- Verify exists: !{bash test -d "$ARGUMENTS" && echo "Found" || echo "Not found"}
- If not found: STOP
- Create todo list for validation

Phase 2: File Structure
Goal: Verify required files

Actions:
- Next.js:
  !{bash test -f "$ARGUMENTS/package.json" && echo "✅ package.json" || echo "❌ missing"}
  !{bash test -d "$ARGUMENTS/app" && echo "✅ app dir" || echo "❌ missing"}
  !{bash test -f "$ARGUMENTS/tsconfig.json" && echo "✅ tsconfig" || echo "❌ missing"}

- Supabase:
  !{bash test -f "$ARGUMENTS/.env.local" -o -f "$ARGUMENTS/.env" && echo "✅ .env" || echo "❌ missing"}
  !{bash grep -q "SUPABASE_URL" "$ARGUMENTS/.env"* 2>/dev/null && echo "✅ Supabase URL" || echo "❌ missing"}

- AI SDK:
  !{bash test -f "$ARGUMENTS/app/api/chat/route.ts" && echo "✅ chat route" || echo "❌ missing"}

- Mark Phase 2 complete

Phase 3: Dependencies
Goal: Verify packages installed

Actions:
- Load: @$ARGUMENTS/package.json

- Check:
  !{bash grep -q "next" "$ARGUMENTS/package.json" && echo "✅ Next.js" || echo "❌ missing"}
  !{bash grep -q "ai" "$ARGUMENTS/package.json" && echo "✅ AI SDK" || echo "❌ missing"}
  !{bash grep -q "supabase" "$ARGUMENTS/package.json" && echo "✅ Supabase" || echo "❌ missing"}

- node_modules:
  !{bash test -d "$ARGUMENTS/node_modules" && echo "✅" || echo "⚠️  Run npm install"}

- Mark Phase 3 complete

Phase 4: Build
Goal: Verify build works

Actions:
- TypeScript: !{bash cd "$ARGUMENTS" && npm run typecheck 2>&1 | head -20}
- Build: !{bash cd "$ARGUMENTS" && npm run build 2>&1 | tail -30}

- If fails: Write validation-errors.txt and STOP
- If succeeds: Mark Phase 4 complete

Phase 5: Summary
Goal: Report results

Actions:
- Mark all todos complete

- Write VALIDATION-REPORT.md with results from all phases

- Display: @VALIDATION-REPORT.md

- Status:
  - All passed: "✅ Validation PASSED"
  - Warnings: "⚠️  Passed with warnings"
  - Failed: "❌ Validation FAILED"

## Usage

/ai-tech-stack-1:validate
/ai-tech-stack-1:validate my-ai-app
