---
description: Run all code review agents in parallel and systematically fix all identified issues
---

# Comprehensive Code Review and Fix

You are tasked with conducting a complete code review using all available review agents, then systematically addressing all identified issues.

## Phase 1: Parallel Review Execution

Execute ALL of the following review agents **IN PARALLEL** using a single message with multiple Task tool calls:

1. **code-practice-reviewer**: Review code against software engineering best practices
2. **test-pyramid-reviewer**: Analyze test coverage and testing strategy
3. **product-design-reviewer**: Evaluate UI/UX and feature simplicity
4. **architecture-reviewer**: Assess system architecture and design
5. **document-reviewer**: Review documentation quality and completeness

**IMPORTANT**: You MUST launch all 5 agents in parallel in a single message. Do NOT launch them sequentially one by one.

Example of correct parallel launch:
```
I'm launching all 5 review agents in parallel...
<uses Task tool 5 times in one message>
```

## Phase 2: Consolidate Findings

After all agents complete:

1. **Collect all issues** from all 5 review reports
2. **Categorize by severity**:
   - CRITICAL: Security issues, major bugs, breaking changes
   - HIGH: Significant code quality issues, missing tests
   - MEDIUM: Code duplication, minor refactoring opportunities
   - LOW: Style issues, documentation improvements

3. **Remove duplicates** - Different agents may flag the same issue
4. **Prioritize** - Order by severity (CRITICAL → HIGH → MEDIUM → LOW)

## Phase 3: Create Action Plan

Create a comprehensive TODO list using TodoWrite with ALL identified issues:

- Use clear, actionable descriptions
- Group related issues together
- Estimate complexity/time if possible
- Mark dependencies between tasks

Example TODO structure:
```
1. [pending] Fix SQL injection vulnerability in user_controller.rs (CRITICAL)
2. [pending] Add input validation to API endpoints (HIGH)
3. [pending] Remove 150 lines of duplicate error handling code (MEDIUM)
4. [pending] Add missing unit tests for payment module (HIGH)
5. [pending] Update API documentation with new endpoints (LOW)
...
```

## Phase 4: Systematic Fix Implementation

Work through the TODO list **in priority order**:

1. **Start with CRITICAL issues** - Security and correctness first
2. **Move to HIGH priority** - Code quality and testing
3. **Address MEDIUM issues** - Refactoring and improvements
4. **Finish with LOW priority** - Polish and documentation

For each issue:
- Mark as `in_progress` when starting
- Make the necessary code changes
- Test the fix (run relevant tests if applicable)
- Mark as `completed` when done
- **Build and verify** after each fix to ensure no regressions

## Phase 5: Final Verification

After all fixes are complete:

1. **Run tests**: `cargo test` (or equivalent for your language)
2. **Build project**: Ensure everything compiles/builds successfully
3. **Quick manual test**: If applicable, do a smoke test
4. **Summary report**: Provide a concise summary of:
   - Total issues found
   - Issues fixed (by category)
   - Any remaining issues (with reasons)
   - Overall improvement metrics

## Special Instructions

- **DO NOT** skip any review agents - all 5 must be executed
- **DO NOT** launch agents sequentially - use parallel execution
- **DO NOT** make cosmetic changes that weren't flagged by reviewers
- **DO** maintain existing functionality while fixing issues
- **DO** test after each significant change
- **DO** ask for clarification if an issue is ambiguous

## Output Format

Provide updates at each phase:

1. "Launching 5 review agents in parallel..."
2. "Review complete. Found X issues across Y categories..."
3. "Created TODO list with Z prioritized tasks..."
4. "Starting fixes... [progress updates as you work]"
5. "All fixes complete. Summary: [final report]"

## Error Handling

If any review agent fails:
- Note the failure but continue with other agents
- Report which agent failed and why
- Proceed with fixes based on successful reviews

---

**BEGIN COMPREHENSIVE REVIEW AND FIX NOW**
