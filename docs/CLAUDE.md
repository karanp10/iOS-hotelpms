## Standard Workflow

1. First think through the problem, read the codebase for relevant files, and write a plan to `docs/TODO.md`.
2. The plan should have a list of todo items that you can check off as you complete them.
3. Before you begin working, check in with me and I will verify the plan.
4. Then, begin working on the todo items, marking them as complete as you go.
5. Please every step of the way just give me a high level explanation of what changes you made.
6. Make every task and code change you do as simple as possible. We want to avoid making any massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
7. Finally, add a review section to the `TODO.md` file with a summary of the changes you made and any other relevant information.

## Test-Driven Development Approach

For the database integration project, we're following strict TDD methodology:

### RED-GREEN-REFACTOR Cycle
1. **RED**: Write a failing test that defines the desired behavior
2. **GREEN**: Write the minimal code to make the test pass
3. **REFACTOR**: Improve the code while keeping tests green

### Testing Strategy
- **Unit Tests**: Fast, isolated tests for individual methods
- **Integration Tests**: Slower tests with real database operations
- **UI Tests**: End-to-end user flow testing
- **Mock Services**: Isolated testing with predictable responses

### Phase-by-Phase Implementation
- **Phase 0**: Test infrastructure and comprehensive test cases FIRST
- **Phase 1**: Database schema updates with test validation
- **Phase 2**: Service layer built test-first
- **Phase 3**: UI integration with tested services
- **Phase 4**: Advanced features (offline, caching) with full test coverage

### Benefits
- **Confidence**: Know operations work before UI integration
- **Documentation**: Tests serve as living API specs
- **Refactoring Safety**: Change implementation without breaking functionality
- **Regression Prevention**: Catch bugs early in development cycle


