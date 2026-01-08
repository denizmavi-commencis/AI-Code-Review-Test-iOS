#!/bin/bash

# Test script for pre-commit hook
# This script tests the pre-commit hook by creating a test file and staging it

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Pre-Commit Hook Test Script                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝\n"

# Get the git root directory
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
    echo -e "${RED}✗ Error: Not in a git repository${NC}"
    echo -e "${YELLOW}  Creating a temporary test repository...${NC}\n"
    
    # Create a temporary test repo
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    git init
    GIT_ROOT="$TEST_DIR"
    echo -e "${GREEN}✓ Created test repository at: $TEST_DIR${NC}\n"
fi

PRE_COMMIT_HOOK="$GIT_ROOT/.git/hooks/pre-commit"

# Check if pre-commit hook exists
if [ ! -f "$PRE_COMMIT_HOOK" ]; then
    echo -e "${YELLOW}⚠️  Pre-commit hook not found${NC}"
    echo -e "${YELLOW}  Expected location: $PRE_COMMIT_HOOK${NC}"
    echo -e "${BLUE}  Installing hooks...${NC}\n"
    
    # Run the installation script
    if [ -f "$(dirname "$0")/../scripts/install-git-hooks.sh" ]; then
        bash "$(dirname "$0")/../scripts/install-git-hooks.sh" <<< "y"
    else
        echo -e "${RED}✗ Installation script not found${NC}"
        exit 1
    fi
    
    if [ ! -f "$PRE_COMMIT_HOOK" ]; then
        echo -e "${RED}✗ Pre-commit hook still not found after installation${NC}"
        exit 1
    fi
fi

# Check if hook is executable
if [ ! -x "$PRE_COMMIT_HOOK" ]; then
    echo -e "${YELLOW}⚠️  Pre-commit hook is not executable${NC}"
    echo -e "${BLUE}  Making it executable...${NC}"
    chmod +x "$PRE_COMMIT_HOOK"
fi

echo -e "${GREEN}✓ Pre-commit hook found and is executable${NC}\n"

# Create a test file with code that should trigger warnings
echo -e "${BLUE}📝 Creating test file with code that should trigger warnings...${NC}"

TEST_FILE="$GIT_ROOT/test_file.swift"
cat > "$TEST_FILE" << 'EOF'
import Foundation

class TestClass {
    var optionalValue: String?
    
    func badMethod() {
        // Force unwrapping - should trigger warning
        let value = optionalValue!
        
        // Another force unwrap
        let array = [1, 2, 3]
        let first = array.first!
        
        print(value)
        print(first)
    }
    
    func anotherBadMethod() {
        // Potential crash
        let dict = ["key": "value"]
        let value = dict["nonexistent"]!
    }
}
EOF

echo -e "${GREEN}✓ Created test file: $TEST_FILE${NC}\n"

# Stage the file
echo -e "${BLUE}📦 Staging test file...${NC}"
cd "$GIT_ROOT"
git add "$TEST_FILE" 2>/dev/null || git add "test_file.swift"
echo -e "${GREEN}✓ File staged${NC}\n"

# Run the pre-commit hook
echo -e "${BLUE}🧪 Running pre-commit hook...${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# The hook will run automatically, but we can also call it directly
if "$PRE_COMMIT_HOOK"; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ HOOK EXECUTED - Check output above for warnings    ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝\n"
    echo -e "${GREEN}The pre-commit hook executed. If you see warnings above, the hook is working!${NC}\n"
    echo -e "${YELLOW}Note: Pre-commit hook shows warnings but does not block commits.${NC}\n"
else
    EXIT_CODE=$?
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║        ⚠️  HOOK EXECUTED WITH EXIT CODE $EXIT_CODE            ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝\n"
    echo -e "${YELLOW}Check the output above for any errors or warnings.${NC}\n"
fi

# Cleanup
echo -e "${BLUE}🧹 Cleaning up test file...${NC}"
git reset HEAD "$TEST_FILE" 2>/dev/null || git reset HEAD "test_file.swift" 2>/dev/null || true
rm -f "$TEST_FILE"
echo -e "${GREEN}✓ Cleanup complete${NC}\n"

exit 0
