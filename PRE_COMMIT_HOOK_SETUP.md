# Mobile Pre-Push Hook Setup Guide (iOS & Android)

## Overview

This project now includes an automated pre-push hook that performs code quality checks before allowing pushes. The hook ensures that all code changes meet our quality standards and are free of critical issues for iOS/Swift **and** Android/Kotlin-Java development. It automatically detects the platform based on the repository layout.

You can override autodetection with an environment variable:
- `MOBILE_PLATFORM=ios` only iOS checks
- `MOBILE_PLATFORM=android` only Android checks
- `MOBILE_PLATFORM=native` (or `both`/`all`) run both

## 🚀 Quick Setup (For Team Members)

### Automatic Installation (Recommended)

Run the installation script from the project root:

```bash
./scripts/install-git-hooks.sh
```

This script will:
- ✅ Check platform prerequisites (Xcode/Swift/SwiftLint for iOS, Gradle wrapper for Android, Cursor, Python)
- ✅ Install the pre-push hook
- ✅ Configure Cursor Agent authentication
- ✅ Verify the installation

### Manual Installation

If you prefer to install manually:

```bash
# 1. Ensure the hook has the right permissions
chmod +x .git/hooks/pre-push

# 2. Authenticate Cursor Agent
cursor agent login

# 3. Verify installation
git push --dry-run
```

## 🔍 What Gets Checked?

### 1. SwiftLint (if available)
- Runs linting on all Swift files being pushed
- Checks for style violations, warnings, and errors
- Uses the project's `.swiftlint.yml` configuration (if present)

### 2. Android Lint & Unit Tests (if Gradle project found)
- Detects Android changes and runs `./gradlew lint`
- Runs `./gradlew test` to catch unit test regressions
- Skips Android checks if no Gradle wrapper is found

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

# Commit
git commit -m "feat: add user authentication"

# Push (hook runs automatically)
git push
```

### Output Examples

#### ✅ Success
```
🔍 Running pre-push checks...

📝 Swift files in commits being pushed:
Navtest/ContentView.swift
Navtest/NavtestApp.swift

🔎 Running SwiftLint...
✓ SwiftLint passed

🤖 Running Cursor Agent code review...
Analyzing code changes... (this may take a moment)
✓ Cursor Agent review passed - no critical issues found
  Summary: Changes look good with proper error handling

╔═══════════════════════════════════════════════════════════╗
║  ✅ All pre-push checks passed!                          ║
╚═══════════════════════════════════════════════════════════╝
```

#### ❌ Blocked (Linting Issues)
```
🔍 Running pre-push checks...

🔎 Running SwiftLint...
✗ SwiftLint found issues:
  Navtest/ContentView.swift:19:1: warning: Trailing Whitespace Violation

Please fix the linting issues before pushing.
```

#### ❌ Blocked (Critical Issues)
```
🔍 Running pre-push checks...

🔎 Running SwiftLint...
✓ SwiftLint passed

🤖 Running Cursor Agent code review...
╔═══════════════════════════════════════════════════════════╗
║  ❌ CRITICAL ISSUES FOUND - PUSH BLOCKED                 ║
╚═══════════════════════════════════════════════════════════╝

🚨 Critical Issues Detected:

Issue #1:
  File: Navtest/NetworkService.swift
  Line: 45
  Severity: critical
  Issue: Force unwrapping optional that could be nil
  Reason: Could cause app crash if network response is nil

Summary: Found security vulnerability that must be fixed before push

Please fix these critical issues before pushing.
To bypass this check (not recommended), use: git push --no-verify
```

## 🆘 Troubleshooting

### Hook Not Running

```bash
# Check if hook exists and is executable
ls -la .git/hooks/pre-push

# If not executable:
chmod +x .git/hooks/pre-push
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

### Gradle Wrapper Not Found (Android)

```bash
# Ensure gradlew exists and is executable (from repo root)
ls -l gradlew
chmod +x gradlew
```

If your Android project lives under `android/`, the hook will look for `android/gradlew` instead.

### Hook Taking Too Long

The AI review has a 120-second timeout. If it times out, the hook will automatically skip the AI review and allow the push to proceed with only SwiftLint checks.

### Need to Push Urgently (Emergency Only)

⚠️ **Use with caution - only in emergencies**

```bash
# Bypass the hook temporarily
git push --no-verify

# Then create a follow-up commit to fix the issues
```

## 🔧 Configuration

### Adjust Timeout

Edit `.git/hooks/pre-push` and change:

```bash
# Default is 120 seconds
timeout 120s "$CURSOR_CLI" agent ...
```

### Customize Critical Issue Detection

The AI review prompt can be customized by editing the `REVIEW_PROMPT` variable in `.git/hooks/pre-push`.

### Disable Specific Checks

To temporarily disable a check (not recommended):

```bash
# Edit .git/hooks/pre-push and comment out the section
# For SwiftLint: comment lines in "Step 1: Run SwiftLint"
# For AI review: comment lines in "Step 2: Run Cursor Agent Code Review"
```

## 📊 Best Practices

1. **Run SwiftLint locally** - Fix linting issues before pushing
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

The pre-push hook doesn't replace code review! It catches critical issues, but reviewers should still check for:
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

If you encounter problems with the pre-push hook:

1. Check the troubleshooting section above
2. Verify prerequisites: Swift, Cursor, Python, SwiftLint (optional)
3. Review the terminal output for specific errors
4. Contact the mobile lead with:
   - Error message
   - What you were trying to push
   - Output of `cursor agent status`
   - Your Cursor version: `cursor --version`

## 📜 Version History

- **v2.0** (Dec 2025) - iOS/Swift adaptation
  - SwiftLint integration
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
