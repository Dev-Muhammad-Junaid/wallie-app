```markdown
# wallie-app Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development patterns and conventions used in the `wallie-app` Swift codebase. You'll learn about file naming, import/export styles, commit practices, and how to write and run tests. The guide also provides suggested commands for common workflows to streamline your development process.

## Coding Conventions

### File Naming
- **Convention:** PascalCase
- **Example:**  
  ```swift
  // File: UserProfile.swift
  struct UserProfile {
      // ...
  }
  ```

### Import Style
- **Convention:** Relative imports
- **Example:**  
  ```swift
  import Foundation
  import MyModule // Assuming MyModule is a relative module
  ```

### Export Style
- **Convention:** Named exports
- **Example:**  
  ```swift
  public struct Wallet {
      // ...
  }
  ```

### Commit Patterns
- **Type:** Freeform (no strict prefixing)
- **Average Length:** ~57 characters
- **Example:**  
  ```
  Add user authentication flow and update UI elements
  ```

## Workflows

### Adding a New Feature
**Trigger:** When implementing a new feature in the app  
**Command:** `/add-feature`

1. Create a new Swift file using PascalCase for the feature name.
2. Implement the feature with named exports.
3. Use relative imports for any dependencies.
4. Write corresponding tests in a `*.test.*` file.
5. Commit changes with a descriptive, freeform message.

### Fixing a Bug
**Trigger:** When resolving a bug or issue  
**Command:** `/fix-bug`

1. Identify the bug and locate the affected file(s).
2. Apply the fix, maintaining coding conventions.
3. Update or add tests to cover the bug fix.
4. Commit with a clear, descriptive message.

### Writing and Running Tests
**Trigger:** When adding or updating tests  
**Command:** `/run-tests`

1. Create or update test files following the `*.test.*` naming pattern.
2. Implement test cases for new or changed code.
3. Run the test suite using the project's testing tool (framework unknown; check project documentation or scripts).
4. Review results and address any failures.

## Testing Patterns

- **File Pattern:** `*.test.*`
- **Framework:** Unknown (refer to project documentation for specifics)
- **Example:**  
  ```swift
  // File: Wallet.test.swift
  import XCTest
  @testable import wallie_app

  class WalletTests: XCTestCase {
      func testBalance() {
          // Test implementation
      }
  }
  ```

## Commands
| Command      | Purpose                                   |
|--------------|-------------------------------------------|
| /add-feature | Start the workflow for adding a new feature|
| /fix-bug     | Begin the process for fixing a bug         |
| /run-tests   | Run the project's test suite               |
```
