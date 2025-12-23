# Pre-Commit Hook Setup Guide

## Overview

This project now includes an automated pre-commit hook that performs code quality checks before allowing commits. The hook ensures that all code changes meet our quality standards and are free of critical issues for iOS/Swift development.

## 🚀 Quick Setup (For Team Members)

### Automatic Installation (Recommended)

Run the installation script from the project root:

```bash
./scripts/install-git-hooks.sh
```

This script will:
- ✅ Check all prerequisites (Xcode, Swift, Cursor, Python, SwiftLint)
- ✅ Install the pre-commit hook
- ✅ Configure Cursor Agent authentication
- ✅ Verify the installation

### Manual Installation

If you prefer to install manually:

```bash
# 1. Ensure the hook has the right permissions
chmod +x .git/hooks/pre-commit

# 2. Authenticate Cursor Agent
cursor agent login

# 3. Verify installation
git commit --dry-run
```

## 🔍 What Gets Checked?

### 1. SwiftLint (if available)
- Runs linting on all staged Swift files
- Checks for style violations, warnings, and errors
- Uses the project's `.swiftlint.yml` configuration (if present)

### 2. Xcode Build Check
- Attempts to build the Xcode project
- Checks for compilation errors in staged Swift files
- Uses `xcodebuild` to verify the code compiles

### 3. Cursor AI Code Review
- AI-powered review of your code changes
- Focuses on **critical issues only**:
  - 🔒 Security vulnerabilities (hardcoded secrets, insecure storage)
  - 🛡️ Force unwrapping that could cause crashes
  - 💧 Memory leaks or retain cycles
  - 💥 Logic errors causing crashes
  - 🔄 Breaking API changes
  - 🐌 Performance issues (main thread blocking)
  - 🏗️ Architectural violations
  - 🔐 Thread safety violations

### 4. Does NOT Check
- ✗ Minor style issues (unless they indicate critical problems)
- ✗ Missing comments
- ✗ Non-critical refactoring suggestions
- ✗ Subjective code improvements
- ✗ SwiftLint warnings (unless they indicate critical issues)

## 📝 Daily Usage

### Normal Workflow

```bash
# Make your changes
# ...

# Stage files
git add .

# Commit (hook runs automatically)
git commit -m "feat: add user authentication"
```

### Output Examples

#### ✅ Success
```
🔍 Running pre-commit checks...

📝 Staged Swift files:
Navtest/ContentView.swift
Navtest/NavtestApp.swift

🔎 Running SwiftLint...
✓ SwiftLint passed

🔨 Running Xcode build check...
✓ Xcode build check passed

🤖 Running Cursor Agent code review...
Analyzing code changes... (this may take a moment)
✓ Cursor Agent review passed - no critical issues found
  Summary: Changes look good with proper error handling

╔═══════════════════════════════════════════════════════════╗
║  ✅ All pre-commit checks passed!                        ║
╚═══════════════════════════════════════════════════════════╝
```

#### ❌ Blocked (Linting Issues)
```
🔍 Running pre-commit checks...

🔎 Running SwiftLint...
✗ SwiftLint found issues:
  Navtest/ContentView.swift:19:1: warning: Trailing Whitespace Violation

Please fix the analysis issues before committing.
```

#### ❌ Blocked (Build Errors)
```
🔍 Running pre-commit checks...

🔨 Running Xcode build check...
✗ Build errors found in staged files:
  error: Navtest/ContentView.swift:23:15: 
         Cannot find 'Color' in scope
```

#### ❌ Blocked (Critical Issues)
```
🔍 Running pre-commit checks...

🔎 Running SwiftLint...
✓ SwiftLint passed

🔨 Running Xcode build check...
✓ Xcode build check passed

🤖 Running Cursor Agent code review...
╔═══════════════════════════════════════════════════════════╗
║  ❌ CRITICAL ISSUES FOUND - COMMIT BLOCKED               ║
╚═══════════════════════════════════════════════════════════╝

🚨 Critical Issues Detected:

Issue #1:
  File: Navtest/NetworkService.swift
  Line: 45
  Severity: critical
  Issue: Force unwrapping optional that could be nil
  Reason: Could cause app crash if network response is nil

Summary: Found security vulnerability that must be fixed before commit

Please fix these critical issues before committing.
To bypass this check (not recommended), use: git commit --no-verify
```

## 🆘 Troubleshooting

### Hook Not Running

```bash
# Check if hook exists and is executable
ls -la .git/hooks/pre-commit

# If not executable:
chmod +x .git/hooks/pre-commit
```

### Cursor Not Authenticated

```bash
# Login to Cursor Agent
cursor agent login

# Verify authentication
cursor agent status
```

### Python Not Found

```bash
# Install Python 3 (macOS with Homebrew)
brew install python3

# Verify installation
python3 --version
```

### SwiftLint Not Found

```bash
# Install SwiftLint (macOS with Homebrew)
brew install swiftlint

# Verify installation
swiftlint version
```

Note: SwiftLint is optional. The hook will work without it, but linting checks will be skipped.

### Xcode Command Line Tools Not Found

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcodebuild -version
```

### Hook Taking Too Long

The AI review has a 120-second timeout. If it times out, the hook will automatically skip the AI review and allow the commit to proceed with only SwiftLint and build checks.

### Need to Commit Urgently (Emergency Only)

⚠️ **Use with caution - only in emergencies**

```bash
# Bypass the hook temporarily
git commit --no-verify -m "emergency fix"

# Then create a follow-up commit to fix the issues
```

## 🔧 Configuration

### Adjust Timeout

Edit `.git/hooks/pre-commit` and change:

```bash
# Default is 120 seconds
timeout 120s "$CURSOR_CLI" agent ...
```

### Customize Critical Issue Detection

The AI review prompt can be customized by editing the `REVIEW_PROMPT` variable in `.git/hooks/pre-commit`.

### Disable Specific Checks

To temporarily disable a check (not recommended):

```bash
# Edit .git/hooks/pre-commit and comment out the section
# For SwiftLint: comment lines in "Step 1: Run SwiftLint"
# For Xcode build: comment lines in "Step 1.5: Try to build with xcodebuild"
# For AI review: comment lines in "Step 2: Run Cursor Agent Code Review"
```

## 📊 Best Practices

1. **Build your project regularly during development** - Don't wait for the commit hook
2. **Run SwiftLint locally** - Fix linting issues before committing
3. **Make small, focused commits** - Faster AI review, easier to fix issues
4. **Don't bypass the hook regularly** - It's there to catch real issues
5. **Review AI feedback carefully** - Even if not blocking, it may have good suggestions
6. **Keep dependencies updated** - Update Swift packages regularly

## 🤝 Team Guidelines

### For Developers

- ✅ Always run the installation script on new machine setups
- ✅ Keep Cursor Agent authenticated (`cursor agent status`)
- ✅ Fix issues promptly - don't accumulate technical debt
- ⚠️ Use `--no-verify` only in genuine emergencies
- 📢 Report any hook issues to the mobile lead

### For Code Reviewers

The pre-commit hook doesn't replace code review! It catches critical issues, but reviewers should still check for:
- Code quality and maintainability
- Test coverage
- Documentation
- Architecture and design patterns
- Business logic correctness

## 📚 Additional Resources

- **Hook Documentation**: `.git/hooks/README.md`
- **Installation Script**: `scripts/install-git-hooks.sh`
- **SwiftLint Rules**: `.swiftlint.yml` (if present)
- **Cursor Agent Docs**: Run `cursor agent --help`

## 🐛 Reporting Issues

If you encounter problems with the pre-commit hook:

1. Check the troubleshooting section above
2. Verify prerequisites: Xcode, Swift, Cursor, Python, SwiftLint (optional)
3. Review the terminal output for specific errors
4. Contact the mobile lead with:
   - Error message
   - What you were trying to commit
   - Output of `cursor agent status`
   - Your Cursor version: `cursor --version`
   - Your Xcode version: `xcodebuild -version`

## 📜 Version History

- **v2.0** (Dec 2025) - iOS/Swift adaptation
  - SwiftLint integration
  - Xcode build check
  - Cursor AI code review
  - Critical issue detection for iOS
  - Team installation script

- **v1.0** (Dec 2025) - Initial release (Flutter/Dart)
  - Flutter analyze integration
  - Cursor AI code review
  - Critical issue detection
  - Team installation script

---

**Remember**: This hook is designed to help maintain code quality and catch issues early. It's a tool to make our development process better, not a barrier. If you have suggestions for improvements, please share them with the team! 🚀
