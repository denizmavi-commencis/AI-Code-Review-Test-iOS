#!/bin/bash

# Test script for pre-commit hook
# This script tests the pre-commit hook without actually committing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Pre-Commit Hook Test Script                     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Get the git root directory
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
    echo -e "${RED}✗ Error: Not in a git repository${NC}"
    exit 1
fi

PRE_COMMIT_HOOK="$GIT_ROOT/.git/hooks/pre-commit"

# Check if pre-commit hook exists
if [ ! -f "$PRE_COMMIT_HOOK" ]; then
    echo -e "${RED}✗ Pre-commit hook not found${NC}"
    echo -e "${YELLOW}  Expected location: $PRE_COMMIT_HOOK${NC}"
    echo -e "${YELLOW}  Run: ./scripts/install-git-hooks.sh${NC}"
    exit 1
fi

# Check if hook is executable
if [ ! -x "$PRE_COMMIT_HOOK" ]; then
    echo -e "${RED}✗ Pre-commit hook is not executable${NC}"
    echo -e "${YELLOW}  Run: chmod +x $PRE_COMMIT_HOOK${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pre-commit hook found and is executable${NC}\n"

# Check for staged files
STAGED_FILES=$(git diff --cached --name-only)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}⚠️  No files are currently staged${NC}"
    echo -e "${BLUE}Test options:${NC}"
    echo -e "  1. Stage some files: ${GREEN}git add <files>${NC}"
    echo -e "  2. Test with current changes: ${GREEN}git add -A && $0${NC}"
    echo -e "  3. Create a test commit: ${GREEN}git commit --dry-run${NC}\n"
    
    read -p "Do you want to stage all current changes for testing? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        echo -e "${GREEN}✓ All changes staged${NC}\n"
    else
        echo -e "${BLUE}Exiting without changes${NC}"
        exit 0
    fi
fi

# Show staged files
echo -e "${BLUE}📝 Staged files:${NC}"
git diff --cached --name-only
echo ""

# Run the pre-commit hook
echo -e "${BLUE}🧪 Running pre-commit hook...${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

if "$PRE_COMMIT_HOOK"; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           ✅ TEST PASSED - Hook Executed Successfully     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${GREEN}The pre-commit hook would allow this commit.${NC}\n"
    exit 0
else
    EXIT_CODE=$?
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           ❌ TEST FAILED - Hook Would Block Commit        ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${RED}The pre-commit hook would block this commit.${NC}"
    echo -e "${RED}Exit code: $EXIT_CODE${NC}\n"
    echo -e "${YELLOW}Fix the issues above before committing.${NC}"
    exit $EXIT_CODE
fi
