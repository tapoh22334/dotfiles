# Code Entropy Improvement

Improve code entropy across the entire project.

## Execution Steps

### 1. Re-run Tests
Execute existing tests and verify coverage and failures

### 2. Static Analysis
Collect complexity and quality metrics using appropriate tools

### 3. Review
Request reviews from each reviewer (sub-agent)

### 4. Refactoring
Improve in priority order based on the above results:

1. Bugs & vulnerabilities
2. Failing tests
3. High complexity code
4. Duplicate code
5. Other improvements

Execute tests after each change and implement incrementally.

## Report
Report metrics before and after improvement, key improvements, and remaining issues