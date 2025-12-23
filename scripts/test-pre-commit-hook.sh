#!/bin/bash

# Test script for pre-push hook
# This script tests the pre-push hook without actually pushing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Pre-Push Hook Test Script                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Get the git root directory
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
    echo -e "${RED}✗ Error: Not in a git repository${NC}"
    exit 1
fi

PRE_PUSH_HOOK="$GIT_ROOT/.git/hooks/pre-push"

# Check if pre-push hook exists
if [ ! -f "$PRE_PUSH_HOOK" ]; then
    echo -e "${RED}✗ Pre-push hook not found${NC}"
    echo -e "${YELLOW}  Expected location: $PRE_PUSH_HOOK${NC}"
    echo -e "${YELLOW}  Run: ./scripts/install-git-hooks.sh${NC}"
    exit 1
fi

# Check if hook is executable
if [ ! -x "$PRE_PUSH_HOOK" ]; then
    echo -e "${RED}✗ Pre-push hook is not executable${NC}"
    echo -e "${YELLOW}  Run: chmod +x $PRE_PUSH_HOOK${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pre-push hook found and is executable${NC}\n"

# Get current branch and remote info
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE_NAME=$(git config branch."$CURRENT_BRANCH".remote || echo "origin")
REMOTE_URL=$(git config remote."$REMOTE_NAME".url || echo "")
LOCAL_REF="refs/heads/$CURRENT_BRANCH"
LOCAL_SHA=$(git rev-parse HEAD)

# Try to get remote SHA
REMOTE_REF="refs/heads/$CURRENT_BRANCH"
REMOTE_SHA=$(git rev-parse "$REMOTE_NAME/$CURRENT_BRANCH" 2>/dev/null || echo "0000000000000000000000000000000000000000")

# If no remote SHA, use merge base with main/master
if [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
    REMOTE_SHA=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null || git rev-parse HEAD~1 2>/dev/null || echo "0000000000000000000000000000000000000000")
fi

echo -e "${BLUE}📋 Test Configuration:${NC}"
echo -e "  Branch: ${GREEN}$CURRENT_BRANCH${NC}"
echo -e "  Remote: ${GREEN}$REMOTE_NAME${NC}"
echo -e "  Local SHA: ${GREEN}$LOCAL_SHA${NC}"
echo -e "  Remote SHA: ${GREEN}$REMOTE_SHA${NC}\n"

# Get files that would be pushed
if [ "$REMOTE_SHA" != "0000000000000000000000000000000000000000" ]; then
    PUSHED_FILES=$(git diff --name-only "$REMOTE_SHA".."$LOCAL_SHA" || true)
    if [ -z "$PUSHED_FILES" ]; then
        echo -e "${YELLOW}⚠️  No changes to push (local and remote are in sync)${NC}\n"
        echo -e "${BLUE}Test options:${NC}"
        echo -e "  1. Make some changes and commit them"
        echo -e "  2. The hook will skip checks if there are no changes\n"
        exit 0
    fi
    
    echo -e "${BLUE}📝 Files that would be pushed:${NC}"
    echo "$PUSHED_FILES"
    echo ""
else
    echo -e "${YELLOW}⚠️  No remote reference found (first push to new branch)${NC}"
    echo -e "${YELLOW}  The hook will skip checks for first push${NC}\n"
    exit 0
fi

# Run the pre-push hook with simulated arguments
echo -e "${BLUE}🧪 Running pre-push hook...${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Pre-push hook arguments: remote_name remote_url local_ref local_sha remote_ref remote_sha
if "$PRE_PUSH_HOOK" "$REMOTE_NAME" "$REMOTE_URL" "$LOCAL_REF" "$LOCAL_SHA" "$REMOTE_REF" "$REMOTE_SHA"; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           ✅ TEST PASSED - Hook Executed Successfully     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${GREEN}The pre-push hook would allow this push.${NC}\n"
    exit 0
else
    EXIT_CODE=$?
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           ❌ TEST FAILED - Hook Would Block Push          ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${RED}The pre-push hook would block this push.${NC}"
    echo -e "${RED}Exit code: $EXIT_CODE${NC}\n"
    echo -e "${YELLOW}Fix the issues above before pushing.${NC}"
    exit $EXIT_CODE
fi
