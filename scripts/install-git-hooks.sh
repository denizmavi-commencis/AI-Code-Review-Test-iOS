#!/bin/bash

# Git Hooks Installation Script
# This script installs the pre-push hook for the project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Git Hooks Installation for Mobile Projects (iOS/Android) ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Get the git root directory
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
    echo -e "${RED}✗ Error: Not in a git repository${NC}"
    exit 1
fi

HOOKS_DIR="$GIT_ROOT/.git/hooks"
PRE_PUSH_HOOK="$HOOKS_DIR/pre-push"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

# Create hooks directory if it doesn't exist
if [ ! -d "$HOOKS_DIR" ]; then
echo -e "${BLUE}📁 Creating git hooks directory...${NC}"
    mkdir -p "$HOOKS_DIR"
    echo -e "${GREEN}✓ Git hooks directory created${NC}\n"
fi

echo -e "${BLUE}📍 Git repository: $GIT_ROOT${NC}\n"

# Defaults (runtime detection happens inside hooks)
SWIFTLINT_AVAILABLE=false
SWIFTLINT_PATH=""
IS_IOS_PROJECT=false
IS_ANDROID_PROJECT=false
ANDROID_GRADLEW=""
ANDROID_WORKDIR=""
BREW_AVAILABLE=false
BREW_INSTALL_INSTRUCTIONS=""

if command -v brew &> /dev/null; then
    BREW_AVAILABLE=true
    BREW_INSTALL_INSTRUCTIONS="brew install cursor-cli"
else
    BREW_INSTALL_INSTRUCTIONS="Install Homebrew (see https://brew.sh) then run: brew install cursor-cli"
fi

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}\n"

# Check Cursor CLI - try multiple locations
CURSOR_PATH=""
CURSOR_AVAILABLE=false
CURSOR_AGENT_BIN=""
CURSOR_AUTHENTICATED=false

if command -v cursor &> /dev/null; then
    CURSOR_PATH=$(which cursor)
    CURSOR_AVAILABLE=true
elif [ -f "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]; then
    CURSOR_PATH="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    CURSOR_AVAILABLE=true
elif [ -f "$HOME/.cursor/bin/cursor" ]; then
    CURSOR_PATH="$HOME/.cursor/bin/cursor"
    CURSOR_AVAILABLE=true
elif [ -f "$HOME/.local/bin/cursor" ]; then
    CURSOR_PATH="$HOME/.local/bin/cursor"
    CURSOR_AVAILABLE=true
fi

# Check if Cursor Agent is available and authenticated
if [ "$CURSOR_AVAILABLE" = true ]; then
    # Require cursor-agent to be runnable from the terminal PATH (no GUI fallbacks)
    if command -v cursor-agent &> /dev/null; then
        CURSOR_AGENT_BIN=$(which cursor-agent)
    fi

    # Ensure Cursor Agent binary is runnable (not just GUI)
    if [ -n "$CURSOR_AGENT_BIN" ] && [ -x "$CURSOR_AGENT_BIN" ]; then
        # Ensure Cursor has the agent subcommand available
        if "$CURSOR_PATH" agent --help >/dev/null 2>&1; then
            # Quick reachability/auth check
            CURSOR_STATUS_OUTPUT=$("$CURSOR_PATH" agent status 2>&1) || CURSOR_STATUS_EXIT=$?
            CURSOR_STATUS_EXIT=${CURSOR_STATUS_EXIT:-0}
            if ! echo "$CURSOR_STATUS_OUTPUT" | grep -Eqi "command not found|No such file|not recognized|unknown command|unknown subcommand|is not a valid command"; then
                if ! echo "$CURSOR_STATUS_OUTPUT" | grep -qi "not logged in"; then
                    if [ $CURSOR_STATUS_EXIT -eq 0 ]; then
                        CURSOR_AUTHENTICATED=true
                        echo -e "${GREEN}✓ Cursor Agent CLI available and authenticated${NC}"
                    fi
                fi
            fi
        fi
    fi
fi

# Check CodeRabbit CLI - try multiple locations
CODERABBIT_PATH=""
CODERABBIT_AVAILABLE=false
CODERABBIT_AUTHENTICATED=false

# Try to find CodeRabbit in common locations
if command -v coderabbit &> /dev/null; then
    CODERABBIT_PATH=$(which coderabbit)
    CODERABBIT_AVAILABLE=true
elif [ -f "$HOME/.local/bin/coderabbit" ]; then
    CODERABBIT_PATH="$HOME/.local/bin/coderabbit"
    CODERABBIT_AVAILABLE=true
elif [ -f "/usr/local/bin/coderabbit" ]; then
    CODERABBIT_PATH="/usr/local/bin/coderabbit"
    CODERABBIT_AVAILABLE=true
elif [ -f "/opt/homebrew/bin/coderabbit" ]; then
    CODERABBIT_PATH="/opt/homebrew/bin/coderabbit"
    CODERABBIT_AVAILABLE=true
fi

if [ "$CODERABBIT_AVAILABLE" = true ] && [ -n "$CODERABBIT_PATH" ]; then
    # Check if CodeRabbit is authenticated
    # Note: auth status returns non-zero when not authenticated, but command exists
    CODERABBIT_AUTH_OUTPUT=$("$CODERABBIT_PATH" auth status 2>&1) || CODERABBIT_AUTH_EXIT=$?
    CODERABBIT_AUTH_EXIT=${CODERABBIT_AUTH_EXIT:-0}
    
    # Check if output indicates authentication (look for success indicators)
    # CodeRabbit shows "Not logged in" when not authenticated, or success messages when authenticated
    if echo "$CODERABBIT_AUTH_OUTPUT" | grep -qiE "authenticated.*yes|logged in.*yes|✓.*authenticated|successfully authenticated" || \
       ([ $CODERABBIT_AUTH_EXIT -eq 0 ] && ! echo "$CODERABBIT_AUTH_OUTPUT" | grep -qi "not logged in\|not authenticated"); then
        CODERABBIT_AUTHENTICATED=true
        echo -e "${GREEN}✓ CodeRabbit CLI available and authenticated${NC}"
    else
        echo -e "${YELLOW}⚠️  CodeRabbit CLI found but not authenticated${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  CodeRabbit CLI not found${NC}"
    echo -e "${YELLOW}  Checked locations:${NC}"
    echo -e "${YELLOW}    - PATH (which coderabbit)${NC}"
    echo -e "${YELLOW}    - ~/.local/bin/coderabbit${NC}"
    echo -e "${YELLOW}    - /usr/local/bin/coderabbit${NC}"
    echo -e "${YELLOW}    - /opt/homebrew/bin/coderabbit${NC}"
fi

# Determine which tool to use
SELECTED_TOOL=""
SELECTED_TOOL_PATH=""

# If both are available and authenticated, ask user
if [ "$CURSOR_AUTHENTICATED" = true ] && [ "$CODERABBIT_AUTHENTICATED" = true ]; then
    echo ""
    echo -e "${BLUE}Both Cursor and CodeRabbit are available and authenticated.${NC}"
    echo -e "${BLUE}Which tool would you like to use for code reviews?${NC}"
    echo -e "  1) Cursor Agent"
    echo -e "  2) CodeRabbit"
    read -p "Enter your choice (1 or 2): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[2]$ ]]; then
        SELECTED_TOOL="coderabbit"
        SELECTED_TOOL_PATH="$CODERABBIT_PATH"
        echo -e "${GREEN}✓ Selected CodeRabbit for code reviews${NC}\n"
    else
        SELECTED_TOOL="cursor"
        SELECTED_TOOL_PATH="$CURSOR_PATH"
        echo -e "${GREEN}✓ Selected Cursor Agent for code reviews${NC}\n"
    fi
# If only CodeRabbit is available and authenticated
elif [ "$CODERABBIT_AUTHENTICATED" = true ] && [ "$CURSOR_AUTHENTICATED" != true ]; then
    echo -e "${BLUE}ℹ️  CodeRabbit is available and authenticated, but Cursor is not.${NC}"
    echo -e "${BLUE}ℹ️  Using CodeRabbit for code reviews.${NC}\n"
    SELECTED_TOOL="coderabbit"
    SELECTED_TOOL_PATH="$CODERABBIT_PATH"
# If only Cursor is available and authenticated
elif [ "$CURSOR_AUTHENTICATED" = true ] && [ "$CODERABBIT_AUTHENTICATED" != true ]; then
    SELECTED_TOOL="cursor"
    SELECTED_TOOL_PATH="$CURSOR_PATH"
    echo -e "${GREEN}✓ Using Cursor Agent for code reviews${NC}\n"
# If CodeRabbit is available but not authenticated
elif [ "$CODERABBIT_AVAILABLE" = true ] && [ "$CODERABBIT_AUTHENTICATED" != true ]; then
    echo -e "${YELLOW}⚠️  CodeRabbit CLI found but not authenticated${NC}"
    read -p "Do you want to authenticate CodeRabbit now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if "$CODERABBIT_PATH" auth login; then
            CODERABBIT_AUTHENTICATED=true
            SELECTED_TOOL="coderabbit"
            SELECTED_TOOL_PATH="$CODERABBIT_PATH"
            echo -e "${GREEN}✓ CodeRabbit authenticated successfully${NC}\n"
        else
            echo -e "${RED}✗ CodeRabbit authentication failed${NC}\n"
        fi
    fi
    
    # If CodeRabbit authentication was declined or failed, check Cursor
    if [ -z "$SELECTED_TOOL" ] && [ "$CURSOR_AVAILABLE" = true ] && [ "$CURSOR_AUTHENTICATED" != true ]; then
        echo -e "${YELLOW}⚠️  Cursor CLI found but not authenticated${NC}"
        read -p "Do you want to authenticate Cursor Agent now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if "$CURSOR_PATH" agent login; then
                CURSOR_AUTHENTICATED=true
                SELECTED_TOOL="cursor"
                SELECTED_TOOL_PATH="$CURSOR_PATH"
                echo -e "${GREEN}✓ Cursor Agent authenticated successfully${NC}\n"
            else
                echo -e "${RED}✗ Cursor Agent authentication failed${NC}\n"
            fi
        fi
    fi
# If neither is available/authenticated, try to set up CodeRabbit
elif [ "$CURSOR_AUTHENTICATED" != true ] && [ "$CODERABBIT_AUTHENTICATED" != true ]; then
    echo -e "${YELLOW}⚠️  Neither Cursor Agent nor CodeRabbit is available and authenticated${NC}"
    
    # Offer to install CodeRabbit
    if [ "$CODERABBIT_AVAILABLE" != true ]; then
        echo -e "${BLUE}Would you like to install CodeRabbit CLI?${NC}"
        read -p "Install CodeRabbit CLI? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Installing CodeRabbit CLI...${NC}"
            if curl -fsSL https://cli.coderabbit.ai/install.sh | sh; then
                CODERABBIT_PATH=$(which coderabbit 2>/dev/null || echo "")
                if [ -n "$CODERABBIT_PATH" ]; then
                    CODERABBIT_AVAILABLE=true
                    echo -e "${GREEN}✓ CodeRabbit CLI installed successfully${NC}"
                else
                    echo -e "${RED}✗ CodeRabbit CLI installation may have failed. Please add it to your PATH.${NC}"
                fi
            else
                echo -e "${RED}✗ CodeRabbit CLI installation failed${NC}"
            fi
        fi
    fi
    
    # If CodeRabbit is now available, authenticate it
    if [ "$CODERABBIT_AVAILABLE" = true ] && [ -n "$CODERABBIT_PATH" ]; then
        echo -e "${BLUE}Authenticating CodeRabbit...${NC}"
        read -p "Do you want to authenticate CodeRabbit now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if "$CODERABBIT_PATH" auth login; then
                CODERABBIT_AUTHENTICATED=true
                SELECTED_TOOL="coderabbit"
                SELECTED_TOOL_PATH="$CODERABBIT_PATH"
                echo -e "${GREEN}✓ CodeRabbit authenticated successfully${NC}\n"
            else
                echo -e "${RED}✗ CodeRabbit authentication failed${NC}\n"
            fi
        fi
    fi
    
    # If still no tool selected, check Cursor
    if [ -z "$SELECTED_TOOL" ] && [ "$CURSOR_AVAILABLE" = true ]; then
        echo -e "${YELLOW}⚠️  Cursor CLI found but not authenticated${NC}"
        read -p "Do you want to authenticate Cursor Agent now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if "$CURSOR_PATH" agent login; then
                CURSOR_AUTHENTICATED=true
                SELECTED_TOOL="cursor"
                SELECTED_TOOL_PATH="$CURSOR_PATH"
                echo -e "${GREEN}✓ Cursor Agent authenticated successfully${NC}\n"
            else
                echo -e "${RED}✗ Cursor Agent authentication failed${NC}\n"
            fi
        fi
    fi
    
    # Final check - require at least one tool
    if [ -z "$SELECTED_TOOL" ]; then
        echo -e "${RED}✗ Error: No code review tool is available and authenticated${NC}"
        echo -e "${YELLOW}  Please install and authenticate either:${NC}"
        echo -e "${YELLOW}    - Cursor Agent: brew install cursor-cli && cursor agent login${NC}"
        echo -e "${YELLOW}    - CodeRabbit: curl -fsSL https://cli.coderabbit.ai/install.sh | sh && coderabbit auth login${NC}"
        exit 1
    fi
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found${NC}"
    echo -e "${YELLOW}  Please install Python 3: https://www.python.org/downloads/${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python 3 found: $(python3 --version)${NC}\n"

# Check if pre-push hook already exists
if [ -f "$PRE_PUSH_HOOK" ]; then
    echo -e "${YELLOW}⚠️  Pre-push hook already exists${NC}"
    echo -e "${YELLOW}  Path: $PRE_PUSH_HOOK${NC}\n"
    
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installation cancelled${NC}"
        exit 0
    fi
    
    # Backup existing hook
    BACKUP_FILE="$PRE_PUSH_HOOK.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PRE_PUSH_HOOK" "$BACKUP_FILE"
    echo -e "${GREEN}✓ Existing hook backed up to: $BACKUP_FILE${NC}\n"
fi

# Create the pre-push hook
echo -e "${BLUE}📝 Installing pre-push hook...${NC}"

# Use the CURSOR_PATH we found above, or set a default if not found
if [ -z "$CURSOR_PATH" ]; then
    # Fallback: try to find it again or use default location
    CURSOR_PATH=$(which cursor 2>/dev/null || echo "/Applications/Cursor.app/Contents/Resources/app/bin/cursor")
fi

cat > "$PRE_PUSH_HOOK" << 'HOOK_SCRIPT_START'
#!/bin/bash

# Pre-push hook for mobile projects (iOS/Android) with AI code review
# This hook will:
# 1. Run SwiftLint on Swift files being pushed (if available)
# 2. Run Android lint and unit tests when Android changes are present
# 3. Use AI tool (Cursor Agent or CodeRabbit) to review code changes
# 4. Block push if critical issues are found

set -e

# Pre-push hook arguments:
# $1 = Name of the remote to which the push is being done
# $2 = URL to which the push is being done
# $3 = Local ref being pushed (e.g., refs/heads/main)
# $4 = Local SHA1 of the commit being pushed
# $5 = Remote ref (e.g., refs/heads/main)
# $6 = Remote SHA1 (will be 0000000000000000000000000000000000000000 if new branch)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOOK_SCRIPT_START

# Add dynamic paths
echo "REVIEW_TOOL=\"$SELECTED_TOOL\"" >> "$PRE_PUSH_HOOK"
echo "REVIEW_TOOL_PATH=\"$SELECTED_TOOL_PATH\"" >> "$PRE_PUSH_HOOK"
echo "CURSOR_CLI=\"$CURSOR_PATH\"" >> "$PRE_PUSH_HOOK"
echo "CODERABBIT_CLI=\"$CODERABBIT_PATH\"" >> "$PRE_PUSH_HOOK"
echo "PROJECT_ROOT=\"$GIT_ROOT\"" >> "$PRE_PUSH_HOOK"
echo "SWIFTLINT_AVAILABLE=\"$SWIFTLINT_AVAILABLE\"" >> "$PRE_PUSH_HOOK"
echo "IS_IOS_PROJECT=\"$IS_IOS_PROJECT\"" >> "$PRE_PUSH_HOOK"
echo "IS_ANDROID_PROJECT=\"$IS_ANDROID_PROJECT\"" >> "$PRE_PUSH_HOOK"
echo "ANDROID_GRADLEW=\"$ANDROID_GRADLEW\"" >> "$PRE_PUSH_HOOK"
echo "ANDROID_WORKDIR=\"$ANDROID_WORKDIR\"" >> "$PRE_PUSH_HOOK"

cat >> "$PRE_PUSH_HOOK" << 'HOOK_SCRIPT_END'

echo -e "${BLUE}🔍 Running pre-push checks...${NC}\n"

# Detect platform at hook runtime (repo could have changed)
IS_IOS="$IS_IOS_PROJECT"
IS_ANDROID="$IS_ANDROID_PROJECT"

IOS_PROJECT=$(find "$PROJECT_ROOT" -maxdepth 3 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | head -n 1)
if [ -n "$IOS_PROJECT" ]; then
    IS_IOS=true
fi

ANDROID_GRADLEW_PATH="$ANDROID_GRADLEW"
ANDROID_WORKDIR_PATH="$ANDROID_WORKDIR"
if [ -z "$ANDROID_GRADLEW_PATH" ]; then
    if [ -x "$PROJECT_ROOT/gradlew" ]; then
        ANDROID_GRADLEW_PATH="$PROJECT_ROOT/gradlew"
        ANDROID_WORKDIR_PATH="$PROJECT_ROOT"
    elif [ -x "$PROJECT_ROOT/android/gradlew" ]; then
        ANDROID_GRADLEW_PATH="$PROJECT_ROOT/android/gradlew"
        ANDROID_WORKDIR_PATH="$PROJECT_ROOT/android"
    fi
fi
if [ -n "$ANDROID_GRADLEW_PATH" ]; then
    IS_ANDROID=true
fi

# Optional override via env: MOBILE_PLATFORM=ios|android|native (native => both)
if [ -n "$MOBILE_PLATFORM" ]; then
    PLATFORM_LOWER=$(echo "$MOBILE_PLATFORM" | tr '[:upper:]' '[:lower:]')
    case "$PLATFORM_LOWER" in
        ios)
            IS_IOS=true
            IS_ANDROID=false
            ;;
        android)
            IS_IOS=false
            IS_ANDROID=true
            ;;
        native|both|all)
            IS_IOS=true
            IS_ANDROID=true
            ;;
        *)
            # Unknown override, keep autodetected values
            ;;
    esac
fi

echo -e "${BLUE}Platforms:${NC}"
if [ "$IS_IOS" = true ]; then
    echo -e "  • ${GREEN}iOS checks enabled${NC}"
else
    echo -e "  • ${YELLOW}iOS checks disabled (no project detected)${NC}"
fi
if [ "$IS_ANDROID" = true ]; then
    echo -e "  • ${GREEN}Android checks enabled${NC}"
else
    echo -e "  • ${YELLOW}Android checks disabled (no Gradle wrapper found)${NC}"
fi
echo ""

# Get the range of commits being pushed
# Pre-push hook arguments:
# $1 = remote name, $2 = remote URL, $3 = local ref, $4 = local SHA, $5 = remote ref, $6 = remote SHA
LOCAL_REF="$3"
REMOTE_REF="$5"
LOCAL_SHA="$4"
REMOTE_SHA="$6"

# If LOCAL_SHA is not provided, derive it from the local ref or current HEAD
if [ -z "$LOCAL_SHA" ] || [ "$LOCAL_SHA" = "0000000000000000000000000000000000000000" ]; then
    if [ -n "$LOCAL_REF" ]; then
        LOCAL_SHA=$(git rev-parse "$LOCAL_REF" 2>/dev/null || echo "")
    fi
    
    # If still no SHA, try to get it from HEAD (current branch)
    if [ -z "$LOCAL_SHA" ] || [ "$LOCAL_SHA" = "0000000000000000000000000000000000000000" ]; then
        LOCAL_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
    fi
fi

# Ensure we have a valid local SHA
if [ -z "$LOCAL_SHA" ] || [ "$LOCAL_SHA" = "0000000000000000000000000000000000000000" ]; then
    echo -e "${YELLOW}⚠️  Could not determine local SHA from ref: $LOCAL_REF${NC}"
    echo -e "${YELLOW}⚠️  Skipping checks${NC}"
    exit 0
fi

# If REMOTE_SHA is not provided or is all zeros, try to get it from the remote tracking branch
if [ -z "$REMOTE_SHA" ] || [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
    REMOTE_NAME="$1"
    BRANCH_NAME=$(echo "$LOCAL_REF" | sed 's|refs/heads/||')
    
    # If BRANCH_NAME is empty, try to get it from current branch
    if [ -z "$BRANCH_NAME" ]; then
        BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    fi
    
    # Try to get remote SHA from remote tracking branch (multiple methods)
    if [ -n "$REMOTE_REF" ] && [ -n "${REMOTE_REF#refs/heads/}" ]; then
        REMOTE_SHA=$(git rev-parse "$REMOTE_NAME/${REMOTE_REF#refs/heads/}" 2>/dev/null || echo "")
    fi
    
    # If still no remote SHA, try the branch name directly
    if [ -z "$REMOTE_SHA" ] || [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
        if [ -n "$BRANCH_NAME" ]; then
            REMOTE_SHA=$(git rev-parse "$REMOTE_NAME/$BRANCH_NAME" 2>/dev/null || echo "")
        fi
    fi
    
    # If still no remote SHA, try to find merge base with default branch
    if [ -z "$REMOTE_SHA" ] || [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
        # Try to find merge base with origin/main or origin/master
        REMOTE_SHA=$(git merge-base "$LOCAL_SHA" origin/main 2>/dev/null || git merge-base "$LOCAL_SHA" origin/master 2>/dev/null || echo "")
    fi
    
    # If no merge base found, try to find where this branch diverged
    if [ -z "$REMOTE_SHA" ] || [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
        # Find the root commit of this branch (first commit with no parents, or oldest commit)
        REMOTE_SHA=$(git rev-list --max-parents=0 "$LOCAL_SHA" 2>/dev/null | head -1 || echo "")
    fi
    
    # If we still can't find a base, use the empty tree to review all changes
    # This will review all files in the branch as new additions
    if [ -z "$REMOTE_SHA" ] || [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
        # Use the well-known empty tree hash to compare against
        REMOTE_SHA="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
        echo -e "${BLUE}ℹ️  New branch detected - reviewing all changes in branch${NC}\n"
    else
        echo -e "${BLUE}ℹ️  Comparing against remote: $REMOTE_SHA${NC}\n"
    fi
fi

# Get list of changed files in the commits being pushed
# Handle empty tree case (new branch with no merge base)
PUSHED_FILES=""
if [ "$REMOTE_SHA" = "4b825dc642cb6eb9a060e54bf8d69288fbee4904" ]; then
    # For empty tree, use --root to show all changes from the beginning
    PUSHED_FILES=$(git diff --root --name-only --diff-filter=ACM "$LOCAL_SHA" || true)
else
    # Normal case: compare two commits
    PUSHED_FILES=$(git diff --name-only --diff-filter=ACM "$REMOTE_SHA".."$LOCAL_SHA" || true)
fi

PUSHED_SWIFT_FILES=$(echo "$PUSHED_FILES" | grep '\.swift$' || true)
PUSHED_ANDROID_FILES=$(echo "$PUSHED_FILES" | grep -E '\.(kt|kts|java|xml|gradle|gradle\.kts)$' || true)

if [ -z "$PUSHED_SWIFT_FILES" ] && [ -z "$PUSHED_ANDROID_FILES" ]; then
    echo -e "${GREEN}✓ No iOS or Android files in commits being pushed${NC}"
    exit 0
fi

if [ -n "$PUSHED_SWIFT_FILES" ]; then
    echo -e "${BLUE}📝 Swift files in commits being pushed:${NC}"
    echo "$PUSHED_SWIFT_FILES"
    echo ""
fi

if [ -n "$PUSHED_ANDROID_FILES" ]; then
    echo -e "${BLUE}📝 Android-related files in commits being pushed:${NC}"
    echo "$PUSHED_ANDROID_FILES"
    echo ""
fi

cd "$PROJECT_ROOT"

# ============================================
# Step 1: Run SwiftLint (if available)
# ============================================
if [ "$IS_IOS" = true ] && [ -n "$PUSHED_SWIFT_FILES" ]; then
    # Runtime detection of SwiftLint
    SWIFTLINT_AVAILABLE=false
    SWIFTLINT_CMD=""
    if command -v swiftlint &> /dev/null; then
        SWIFTLINT_CMD=$(command -v swiftlint)
        SWIFTLINT_AVAILABLE=true
    elif [ -f "/usr/local/bin/swiftlint" ]; then
        SWIFTLINT_CMD="/usr/local/bin/swiftlint"
        SWIFTLINT_AVAILABLE=true
    elif [ -f "/opt/homebrew/bin/swiftlint" ]; then
        SWIFTLINT_CMD="/opt/homebrew/bin/swiftlint"
        SWIFTLINT_AVAILABLE=true
    fi

    if [ "$SWIFTLINT_AVAILABLE" = "true" ]; then
        echo -e "${BLUE}🔎 Running SwiftLint...${NC}"
        
        # Run swiftlint on Swift files being pushed
        SWIFTLINT_OUTPUT=""
        SWIFTLINT_EXIT_CODE=0
        HAS_LINT_ERRORS=false
        
        for file in $PUSHED_SWIFT_FILES; do
            if [ -f "$PROJECT_ROOT/$file" ]; then
                FILE_OUTPUT=$("$SWIFTLINT_CMD" lint --path "$PROJECT_ROOT/$file" 2>&1 || true)
                FILE_EXIT_CODE=$?
                
                if [ $FILE_EXIT_CODE -ne 0 ]; then
                    HAS_LINT_ERRORS=true
                    SWIFTLINT_OUTPUT="$SWIFTLINT_OUTPUT$FILE_OUTPUT\n"
                fi
            fi
        done
        
        if [ "$HAS_LINT_ERRORS" = true ]; then
            echo -e "${RED}✗ SwiftLint found issues:${NC}"
            echo -e "$SWIFTLINT_OUTPUT"
            echo ""
            echo -e "${RED}Please fix the linting issues before pushing.${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ SwiftLint passed${NC}\n"
    else
        echo -e "${YELLOW}⚠️  SwiftLint not available, skipping lint checks${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping SwiftLint (no iOS project or no Swift files)${NC}\n"
fi

# ============================================
# Step 2: Android lint and tests (if Gradle project found)
# ============================================
if [ "$IS_ANDROID" = true ] && [ -n "$PUSHED_ANDROID_FILES" ]; then
    ANDROID_LINT_FAILED=false
    ANDROID_TEST_FAILED=false

    echo -e "${BLUE}🤖 Running Android lint...${NC}"
    set +e
    (cd "$ANDROID_WORKDIR_PATH" && "$ANDROID_GRADLEW_PATH" lint)
    ANDROID_LINT_EXIT=$?
    set -e

    if [ $ANDROID_LINT_EXIT -ne 0 ]; then
        echo -e "${RED}✗ Android lint failed${NC}"
        ANDROID_LINT_FAILED=true
    fi
    echo -e "${GREEN}✓ Android lint passed${NC}\n"

    echo -e "${BLUE}🧪 Running Android unit tests...${NC}"
    set +e
    (cd "$ANDROID_WORKDIR_PATH" && "$ANDROID_GRADLEW_PATH" test)
    ANDROID_TEST_EXIT=$?
    set -e

    if [ $ANDROID_TEST_EXIT -ne 0 ]; then
        echo -e "${RED}✗ Android tests failed${NC}"
        ANDROID_TEST_FAILED=true
    fi
    echo -e "${GREEN}✓ Android unit tests passed${NC}\n"
elif [ -n "$PUSHED_ANDROID_FILES" ]; then
    echo -e "${YELLOW}⚠️  Android changes detected but Gradle wrapper not found. Skipping Android checks.${NC}\n"
fi

# ============================================
# Step 3: Run AI Code Review (Cursor Agent or CodeRabbit)
# ============================================
# Determine which tool to use (runtime fallback if not set)
if [ -z "$REVIEW_TOOL" ]; then
    # Try to detect at runtime
    if [ -n "$REVIEW_TOOL_PATH" ] && [ -f "$REVIEW_TOOL_PATH" ]; then
        if echo "$REVIEW_TOOL_PATH" | grep -qi "cursor"; then
            REVIEW_TOOL="cursor"
        elif echo "$REVIEW_TOOL_PATH" | grep -qi "coderabbit"; then
            REVIEW_TOOL="coderabbit"
        fi
    fi
    
    # Fallback: try to find available tool
    if [ -z "$REVIEW_TOOL" ]; then
        if command -v coderabbit &> /dev/null; then
            # Check CodeRabbit authentication by parsing output
            CODERABBIT_AUTH_OUTPUT=$(coderabbit auth status 2>&1) || CODERABBIT_AUTH_EXIT=$?
            CODERABBIT_AUTH_EXIT=${CODERABBIT_AUTH_EXIT:-0}
            if echo "$CODERABBIT_AUTH_OUTPUT" | grep -qiE "authenticated.*yes|logged in.*yes|✓.*authenticated|successfully authenticated" || \
               ([ $CODERABBIT_AUTH_EXIT -eq 0 ] && ! echo "$CODERABBIT_AUTH_OUTPUT" | grep -qi "not logged in\|not authenticated"); then
                REVIEW_TOOL="coderabbit"
                REVIEW_TOOL_PATH=$(which coderabbit)
            fi
        elif command -v cursor &> /dev/null && cursor agent status >/dev/null 2>&1; then
            REVIEW_TOOL="cursor"
            REVIEW_TOOL_PATH=$(which cursor)
        fi
    fi
fi

if [ -z "$REVIEW_TOOL" ] || [ -z "$REVIEW_TOOL_PATH" ]; then
    echo -e "${YELLOW}⚠️  No AI review tool available or authenticated${NC}"
    echo -e "${YELLOW}⚠️  Skipping AI code review...${NC}\n"
    exit 0
fi

if [ "$REVIEW_TOOL" = "cursor" ]; then
    echo -e "${BLUE}🤖 Running Cursor Agent code review...${NC}"
elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
    echo -e "${BLUE}🤖 Running CodeRabbit code review...${NC}"
else
    echo -e "${YELLOW}⚠️  Unknown review tool: $REVIEW_TOOL${NC}"
    echo -e "${YELLOW}⚠️  Skipping AI code review...${NC}\n"
    exit 0
fi

# Get the diff of commits being pushed
# Handle empty tree case (new branch with no merge base)
if [ "$REMOTE_SHA" = "4b825dc642cb6eb9a060e54bf8d69288fbee4904" ]; then
    # For empty tree, use --root to show all changes from the beginning
    PUSHED_DIFF=$(git diff --root "$LOCAL_SHA")
else
    # Normal case: compare two commits
    PUSHED_DIFF=$(git diff "$REMOTE_SHA".."$LOCAL_SHA")
fi

# Trim very large diffs to avoid Cursor token limits
MAX_DIFF_CHARS=120000
MAX_DIFF_LINES=1200
DIFF_NOTE=""
REVIEW_DIFF="$PUSHED_DIFF"
if [ ${#REVIEW_DIFF} -gt $MAX_DIFF_CHARS ]; then
    DIFF_NOTE="(Diff truncated to first $MAX_DIFF_LINES lines to avoid size limits.)"
    REVIEW_DIFF=$(echo "$REVIEW_DIFF" | head -n $MAX_DIFF_LINES)
    echo -e "${YELLOW}⚠️  Large diff detected - limiting AI review to first $MAX_DIFF_LINES lines${NC}"
fi

if [ -z "$PUSHED_DIFF" ]; then
    echo -e "${GREEN}✓ No changes to review${NC}"
    exit 0
fi

# Create a temporary file with the diff
TEMP_DIFF_FILE=$(mktemp)
echo "$REVIEW_DIFF" > "$TEMP_DIFF_FILE"

# Prepare the prompt for Cursor Agent
PLATFORM_CONTEXT="$( [ "$IS_IOS" = true ] && [ "$IS_ANDROID" = true ] && echo "iOS (Swift) and Android (Kotlin/Java)" || ( [ "$IS_IOS" = true ] && echo "iOS (Swift)" || ( [ "$IS_ANDROID" = true ] && echo "Android (Kotlin/Java)" || echo "mobile" ) ) )"

REVIEW_PROMPT="You are an EXTREMELY strict senior code reviewer for a mobile project. Platform context: $PLATFORM_CONTEXT. Your job is to catch EVERY issue that could cause problems. Be very thorough and strict.

MANDATORY - You MUST flag these as CRITICAL (blocks commit):
1. For iOS/Swift: ANY force unwrapping (!) is CRITICAL. Force unwrapping will crash if nil. Flag EVERY instance (value!, optional!.property, array![0], dict![\"key\"]). Also flag retain cycles, missing error handling that leads to crashes, thread safety violations, UI work off main thread.
2. For Android/Kotlin/Java: unsafe !! (Kotlin) or unchecked nulls, lifecycle leaks, coroutine misuse (missing scope/cancellation), blocking main thread, accessing UI from background threads, exported components without protection, insecure storage/hardcoded secrets.
3. Security vulnerabilities (hardcoded secrets, API keys, passwords, insecure data storage)
4. Logic errors that will cause crashes or data corruption
5. Breaking API changes without proper migration or deprecation warnings

HIGH (should fix - blocks commit):
- Potential crashes (array out of bounds, null handling issues, division by zero)
- Performance issues (main/UI thread blocking, expensive operations on UI thread, memory-intensive operations)
- Code smells that indicate bugs (unused variables that should be used, dead code, unreachable code)
- Incorrect platform patterns (bad optional handling, misuse of state/lifecycle, incorrect async/await/coroutine usage)
- Missing input validation

MEDIUM (should consider fixing):
- Code quality issues (magic numbers, long methods, complex conditionals)
- Potential bugs (off-by-one errors, incorrect comparisons, type mismatches)
- Architectural concerns (tight coupling, violation of SOLID principles)
- Inefficient algorithms or data structures

CRITICAL RULES:
- If you see ANY Swift force unwrapping (!) or Kotlin double-bang (!!), flag as CRITICAL severity
- Be extremely thorough - scan every line of code

Be very strict. If you see ANY force unwrapping, !!, potential crashes, or problematic code, flag it immediately.

Respond ONLY in the following JSON format:
{
  \"has_critical_issues\": true/false,
  \"critical_issues\": [
    {
      \"severity\": \"critical\" | \"high\" | \"medium\",
      \"file\": \"path/to/file.swift\",
      \"line\": 123,
      \"issue\": \"Description of the issue\",
      \"reason\": \"Why this should be fixed\",
      \"suggestion\": \"How to fix it (optional)\"
    }
  ],
  \"summary\": \"Brief summary of findings\"
}

Set has_critical_issues to true if you find ANY critical or high severity issues. Remember: ANY force unwrapping (!) is CRITICAL.

Here are the changes being pushed to review:

${DIFF_NOTE:+$DIFF_NOTE
}
\`\`\`diff
$REVIEW_DIFF
\`\`\`

Respond ONLY with the JSON format above, no additional text."

# Run AI review tool in non-interactive mode
REVIEW_OUTPUT_FILE=$(mktemp)
REVIEW_ERROR_FILE=$(mktemp)

# Verify tool is available and authenticated
if [ "$REVIEW_TOOL" = "cursor" ]; then
    # Check if Cursor CLI exists - try multiple locations
    if [ ! -f "$REVIEW_TOOL_PATH" ]; then
        # Try to find cursor in common locations
        if command -v cursor &> /dev/null; then
            REVIEW_TOOL_PATH=$(which cursor)
        elif [ -f "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]; then
            REVIEW_TOOL_PATH="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
        elif [ -f "$HOME/.cursor/bin/cursor" ]; then
            REVIEW_TOOL_PATH="$HOME/.cursor/bin/cursor"
        elif [ -f "$HOME/.local/bin/cursor" ]; then
            REVIEW_TOOL_PATH="$HOME/.local/bin/cursor"
        else
            echo -e "${YELLOW}⚠️  Cursor CLI not found${NC}"
            echo -e "${YELLOW}⚠️  Skipping AI review...${NC}\n"
            rm -f "$TEMP_DIFF_FILE" "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
            exit 0
        fi
    fi
    
    # Check if Cursor Agent is logged in
    if ! "$REVIEW_TOOL_PATH" agent status >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Cursor Agent is not logged in. Run 'cursor agent login' first.${NC}"
        echo -e "${YELLOW}⚠️  Skipping AI review...${NC}\n"
        rm -f "$TEMP_DIFF_FILE" "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
        exit 0
    fi
elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
    # Check if CodeRabbit CLI exists
    if [ ! -f "$REVIEW_TOOL_PATH" ]; then
        if command -v coderabbit &> /dev/null; then
            REVIEW_TOOL_PATH=$(which coderabbit)
        else
            echo -e "${YELLOW}⚠️  CodeRabbit CLI not found${NC}"
            echo -e "${YELLOW}⚠️  Skipping AI review...${NC}\n"
            rm -f "$TEMP_DIFF_FILE" "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
            exit 0
        fi
    fi
    
    # Check if CodeRabbit is authenticated (parse output, not just exit code)
    CODERABBIT_AUTH_OUTPUT=$("$REVIEW_TOOL_PATH" auth status 2>&1) || CODERABBIT_AUTH_EXIT=$?
    CODERABBIT_AUTH_EXIT=${CODERABBIT_AUTH_EXIT:-0}
    
    # Check if output indicates authentication
    if ! (echo "$CODERABBIT_AUTH_OUTPUT" | grep -qiE "authenticated.*yes|logged in.*yes|✓.*authenticated|successfully authenticated" || \
          ([ $CODERABBIT_AUTH_EXIT -eq 0 ] && ! echo "$CODERABBIT_AUTH_OUTPUT" | grep -qi "not logged in\|not authenticated")); then
        echo -e "${YELLOW}⚠️  CodeRabbit is not authenticated. Run 'coderabbit auth login' first.${NC}"
        echo -e "${YELLOW}⚠️  Skipping AI review...${NC}\n"
        rm -f "$TEMP_DIFF_FILE" "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
        exit 0
    fi
fi

# Run the review with timeout
echo -e "${BLUE}Analyzing code changes... (this may take a moment)${NC}"

# macOS-compatible timeout: try gtimeout (coreutils), then use bash-based timeout
TIMEOUT_SECONDS=120
REVIEW_EXIT_CODE=0

if [ "$REVIEW_TOOL" = "cursor" ]; then
    # Run Cursor Agent
    if command -v gtimeout &> /dev/null; then
        # Use gtimeout from coreutils if available
        if gtimeout ${TIMEOUT_SECONDS}s "$REVIEW_TOOL_PATH" agent --print --output-format json "$REVIEW_PROMPT" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE"; then
            REVIEW_EXIT_CODE=0
        else
            REVIEW_EXIT_CODE=$?
        fi
    else
        # Bash-based timeout implementation for macOS
        "$REVIEW_TOOL_PATH" agent --print --output-format json "$REVIEW_PROMPT" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" &
        REVIEW_PID=$!
        
        # Wait for the process or timeout
        for i in $(seq 1 $TIMEOUT_SECONDS); do
            if ! kill -0 $REVIEW_PID 2>/dev/null; then
                # Process finished
                set +e
                wait $REVIEW_PID
                REVIEW_EXIT_CODE=$?
                set -e
                break
            fi
            sleep 1
        done
        
        # Check if process is still running (timeout reached)
        if kill -0 $REVIEW_PID 2>/dev/null; then
            kill $REVIEW_PID 2>/dev/null || true
            set +e
            wait $REVIEW_PID 2>/dev/null || true
            set -e
            REVIEW_EXIT_CODE=124
        fi
    fi
elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
    # Run CodeRabbit - try multiple command formats
    # CodeRabbit CLI format may vary, so we try different approaches
    REVIEW_EXIT_CODE=1
    
    # Try format 1: coderabbit review with diff file (--file or --diff-file or --diff)
    for file_flag in "--file" "--diff-file" "--diff" "-f" "-d"; do
        if command -v gtimeout &> /dev/null; then
            if gtimeout ${TIMEOUT_SECONDS}s "$REVIEW_TOOL_PATH" review $file_flag "$TEMP_DIFF_FILE" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" 2>&1; then
                REVIEW_EXIT_CODE=0
                break
            fi
        else
            "$REVIEW_TOOL_PATH" review $file_flag "$TEMP_DIFF_FILE" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" 2>&1 &
            REVIEW_PID=$!
            
            for i in $(seq 1 $TIMEOUT_SECONDS); do
                if ! kill -0 $REVIEW_PID 2>/dev/null; then
                    set +e
                    wait $REVIEW_PID
                    REVIEW_EXIT_CODE=$?
                    set -e
                    break
                fi
                sleep 1
            done
            
            if kill -0 $REVIEW_PID 2>/dev/null; then
                kill $REVIEW_PID 2>/dev/null || true
                set +e
                wait $REVIEW_PID 2>/dev/null || true
                set -e
                REVIEW_EXIT_CODE=124
            fi
            
            if [ $REVIEW_EXIT_CODE -eq 0 ]; then
                break
            fi
        fi
    done
    
    # Try format 2: coderabbit review with stdin (if format 1 failed)
    if [ $REVIEW_EXIT_CODE -ne 0 ] && [ $REVIEW_EXIT_CODE -ne 124 ]; then
        if command -v gtimeout &> /dev/null; then
            if cat "$TEMP_DIFF_FILE" | gtimeout ${TIMEOUT_SECONDS}s "$REVIEW_TOOL_PATH" review > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" 2>&1; then
                REVIEW_EXIT_CODE=0
            fi
        else
            cat "$TEMP_DIFF_FILE" | "$REVIEW_TOOL_PATH" review > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" 2>&1 &
            REVIEW_PID=$!
            
            for i in $(seq 1 $TIMEOUT_SECONDS); do
                if ! kill -0 $REVIEW_PID 2>/dev/null; then
                    set +e
                    wait $REVIEW_PID
                    REVIEW_EXIT_CODE=$?
                    set -e
                    break
                fi
                sleep 1
            done
            
            if kill -0 $REVIEW_PID 2>/dev/null; then
                kill $REVIEW_PID 2>/dev/null || true
                set +e
                wait $REVIEW_PID 2>/dev/null || true
                set -e
                REVIEW_EXIT_CODE=124
            fi
        fi
    fi
    
    # Try format 3: coderabbit review in git context (if previous formats failed)
    # CodeRabbit might need to be run in the git repo directory
    if [ $REVIEW_EXIT_CODE -ne 0 ] && [ $REVIEW_EXIT_CODE -ne 124 ]; then
        if command -v gtimeout &> /dev/null; then
            if (cd "$PROJECT_ROOT" && gtimeout ${TIMEOUT_SECONDS}s "$REVIEW_TOOL_PATH" review "$TEMP_DIFF_FILE" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" 2>&1); then
                REVIEW_EXIT_CODE=0
            fi
        else
            (cd "$PROJECT_ROOT" && "$REVIEW_TOOL_PATH" review "$TEMP_DIFF_FILE" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" 2>&1) &
            REVIEW_PID=$!
            
            for i in $(seq 1 $TIMEOUT_SECONDS); do
                if ! kill -0 $REVIEW_PID 2>/dev/null; then
                    set +e
                    wait $REVIEW_PID
                    REVIEW_EXIT_CODE=$?
                    set -e
                    break
                fi
                sleep 1
            done
            
            if kill -0 $REVIEW_PID 2>/dev/null; then
                kill $REVIEW_PID 2>/dev/null || true
                set +e
                wait $REVIEW_PID 2>/dev/null || true
                set -e
                REVIEW_EXIT_CODE=124
            fi
        fi
    fi
    
    # Note: CodeRabbit may have different output format than Cursor
    # The JSON parsing will handle both formats, or we'll skip review if parsing fails
fi

# Clean up temp diff file
rm -f "$TEMP_DIFF_FILE"

if [ $REVIEW_EXIT_CODE -eq 124 ]; then
    TOOL_NAME="AI review tool"
    if [ "$REVIEW_TOOL" = "cursor" ]; then
        TOOL_NAME="Cursor Agent"
    elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
        TOOL_NAME="CodeRabbit"
    fi
    echo -e "${YELLOW}⚠️  $TOOL_NAME review timed out after $TIMEOUT_SECONDS seconds${NC}"
    echo -e "${YELLOW}⚠️  Proceeding without AI review...${NC}\n"
    rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
    exit 0
fi

if [ $REVIEW_EXIT_CODE -ne 0 ]; then
    TOOL_NAME="AI review tool"
    if [ "$REVIEW_TOOL" = "cursor" ]; then
        TOOL_NAME="Cursor Agent"
    elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
        TOOL_NAME="CodeRabbit"
    fi
    echo -e "${YELLOW}⚠️  $TOOL_NAME review failed with exit code $REVIEW_EXIT_CODE${NC}"
    if [ -s "$REVIEW_ERROR_FILE" ]; then
        echo -e "${YELLOW}Error output:${NC}"
        cat "$REVIEW_ERROR_FILE"
    fi
    echo -e "${YELLOW}⚠️  Proceeding without AI review...${NC}\n"
    rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
    exit 0
fi

# Parse the AI review tool output
if [ -s "$REVIEW_OUTPUT_FILE" ]; then
    REVIEW_RESULT=$(cat "$REVIEW_OUTPUT_FILE")
    
    # DEBUG: Show the raw tool output
    TOOL_NAME="AI review tool"
    if [ "$REVIEW_TOOL" = "cursor" ]; then
        TOOL_NAME="Cursor Agent"
    elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
        TOOL_NAME="CodeRabbit"
    fi
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🤖 $TOOL_NAME Raw Response (DEBUG):${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "$REVIEW_RESULT"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Extract JSON from the response
    # The response is wrapped in a result object, and the actual JSON is in a code block
    # Pass file path via environment variable
    JSON_RESULT=$(REVIEW_OUTPUT_FILE="$REVIEW_OUTPUT_FILE" python3 << 'PYTHON_EOF'
import sys, json
import re
import os

def extract_json_with_string_tracking(text, start_idx):
    """Extract JSON object starting at start_idx, properly tracking strings"""
    if start_idx < 0 or start_idx >= len(text):
        return None
    
    brace_count = 0
    in_string = False
    escape_next = False
    
    for i in range(start_idx, len(text)):
        char = text[i]
        
        # Handle escape sequences
        if escape_next:
            escape_next = False
            continue
        
        if char == '\\':
            escape_next = True
            continue
        
        # Track string boundaries
        if char == '"' and not escape_next:
            in_string = not in_string
            continue
        
        # Only count braces when NOT inside a string
        if not in_string:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    # Found the matching closing brace
                    json_str = text[start_idx:i+1]
                    try:
                        parsed = json.loads(json_str)
                        return parsed
                    except json.JSONDecodeError:
                        pass
                    return None
    
    return None

def extract_from_code_block(text):
    """Extract JSON from a code block like ```json ... ```"""
    backtick = chr(96)
    code_marker = backtick + backtick + backtick + 'json'
    code_start = text.find(code_marker)
    
    if code_start >= 0:
        # Find the start of JSON (first { after ```json, skipping whitespace)
        json_start = code_start + len(code_marker)
        # Skip whitespace and newlines
        while json_start < len(text) and text[json_start] in [' ', '\n', '\r', '\t']:
            json_start += 1
        
        if json_start < len(text) and text[json_start] == '{':
            # Find the closing ``` (but we need the complete JSON first)
            # Use string tracking to find the matching }
            parsed = extract_json_with_string_tracking(text, json_start)
            if parsed:
                return parsed
            
            # Fallback: find closing ``` and try to parse what's between
            code_end = text.find(backtick + backtick + backtick, json_start)
            if code_end > json_start:
                json_candidate = text[json_start:code_end].strip()
                # Remove trailing whitespace/newlines
                json_candidate = json_candidate.rstrip()
                try:
                    parsed = json.loads(json_candidate)
                    return parsed
                except:
                    pass
    
    return None

try:
    # Read from the file in environment variable, or stdin
    review_file = os.environ.get('REVIEW_OUTPUT_FILE')
    if review_file and os.path.exists(review_file):
        with open(review_file, 'r', encoding='utf-8') as f:
            input_data = f.read()
    else:
        input_data = sys.stdin.read()
    
    data = json.loads(input_data)
    
    # Get the result field which contains the text response
    if 'result' in data and isinstance(data['result'], str):
        result_str = data['result']
        
        # Look for JSON in code blocks - match ```json ... ```
        parsed = extract_from_code_block(result_str)
        if parsed:
            print(json.dumps(parsed))
            sys.exit(0)
        
        # No code block found, try to find JSON object directly
        start_idx = result_str.find('{"has_critical_issues"')
        if start_idx >= 0:
            parsed = extract_json_with_string_tracking(result_str, start_idx)
            if parsed:
                print(json.dumps(parsed))
                sys.exit(0)
        
        # Try finding any JSON object that contains has_critical_issues
        # Use regex to find the start
        match = re.search(r'\{[^{]*"has_critical_issues"', result_str)
        if match:
            parsed = extract_json_with_string_tracking(result_str, match.start())
            if parsed:
                print(json.dumps(parsed))
                sys.exit(0)
        
        print('{}')
    elif 'has_critical_issues' in data:
        print(json.dumps(data))
    else:
        print('{}')
except Exception as e:
    # Fallback: try to extract from raw text
    try:
        text = sys.stdin.read()
        start_idx = text.find('{"has_critical_issues"')
        if start_idx >= 0:
            parsed = extract_json_with_string_tracking(text, start_idx)
            if parsed:
                print(json.dumps(parsed))
                sys.exit(0)
        
        # Try code block
        parsed = extract_from_code_block(text)
        if parsed:
            print(json.dumps(parsed))
            sys.exit(0)
        
        print('{}')
    except:
        print('{}')
PYTHON_EOF
)
    
    # DEBUG: Show extracted JSON
    echo -e "${BLUE}📋 Extracted JSON (DEBUG):${NC}"
    echo "$JSON_RESULT" | python3 -m json.tool 2>/dev/null || echo "$JSON_RESULT"
    echo ""
    
    # Check if we got valid JSON
    if ! echo "$JSON_RESULT" | python3 -m json.tool >/dev/null 2>&1; then
        TOOL_NAME="AI review tool"
        if [ "$REVIEW_TOOL" = "cursor" ]; then
            TOOL_NAME="Cursor Agent"
        elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
            TOOL_NAME="CodeRabbit"
        fi
        echo -e "${YELLOW}⚠️  Could not parse $TOOL_NAME response as JSON${NC}"
        echo -e "${YELLOW}⚠️  Proceeding without AI review...${NC}\n"
        rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
        exit 0
    fi
    
    # Extract has_critical_issues flag and check if issues array has items
    ISSUES_CHECK=$(echo "$JSON_RESULT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    has_flag = str(data.get('has_critical_issues', False)).lower()
    issues = data.get('critical_issues', [])
    issue_count = len(issues) if isinstance(issues, list) else 0
    # If there are issues in the array, we should show them regardless of flag
    if issue_count > 0:
        print('true')
    else:
        print(has_flag)
except:
    print('false')
" 2>/dev/null || echo "false")
    
    # Also get the actual issue count for debugging
    ISSUE_COUNT=$(echo "$JSON_RESULT" | python3 -c "import sys, json; data = json.load(sys.stdin); issues = data.get('critical_issues', []); print(len(issues) if isinstance(issues, list) else 0)" 2>/dev/null || echo "0")
    
    # DEBUG: Show what we found
    echo -e "${BLUE}🔍 Issue Check (DEBUG):${NC}"
    echo -e "${BLUE}  Issues found in array: $ISSUE_COUNT${NC}"
    echo -e "${BLUE}  Should show issues: $ISSUES_CHECK${NC}\n"
    
    if [ "$ISSUES_CHECK" = "true" ] || [ "$ISSUE_COUNT" -gt 0 ]; then
        echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ❌ ISSUES FOUND - COMMIT BLOCKED                        ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}\n"
        
        # Pretty print the issues with color coding by severity
        echo -e "${RED}🚨 Issues Detected:${NC}\n"
        echo "$JSON_RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, issue in enumerate(data.get('critical_issues', []), 1):
    severity = issue.get('severity', 'medium').lower()
    if severity == 'critical':
        severity_marker = '🔴 CRITICAL'
    elif severity == 'high':
        severity_marker = '🟠 HIGH'
    else:
        severity_marker = '🟡 MEDIUM'
    
    print(f\"Issue #{i} [{severity_marker}]:\")
    print(f\"  File: {issue.get('file', 'N/A')}\")
    if 'line' in issue:
        print(f\"  Line: {issue['line']}\")
    print(f\"  Issue: {issue.get('issue', 'N/A')}\")
    print(f\"  Reason: {issue.get('reason', 'N/A')}\")
    if 'suggestion' in issue and issue['suggestion']:
        print(f\"  Suggestion: {issue['suggestion']}\")
    print()
print(f\"Summary: {data.get('summary', 'Issues found in your changes')}\")"
        
        echo ""
        echo -e "${RED}Please fix these issues before pushing.${NC}"
        echo -e "${YELLOW}To bypass this check (not recommended), use: git push --no-verify${NC}"
        
        rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
        exit 1
    else
        # Even if flag says no issues, check if there are actually issues in the array
        if [ "$ISSUE_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Issues found in response but has_critical_issues flag was false${NC}"
            echo -e "${YELLOW}⚠️  Displaying issues anyway:${NC}\n"
            
            echo -e "${RED}🚨 Issues Detected:${NC}\n"
            echo "$JSON_RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, issue in enumerate(data.get('critical_issues', []), 1):
    severity = issue.get('severity', 'medium').lower()
    if severity == 'critical':
        severity_marker = '🔴 CRITICAL'
    elif severity == 'high':
        severity_marker = '🟠 HIGH'
    else:
        severity_marker = '🟡 MEDIUM'
    
    print(f\"Issue #{i} [{severity_marker}]:\")
    print(f\"  File: {issue.get('file', 'N/A')}\")
    if 'line' in issue:
        print(f\"  Line: {issue['line']}\")
    print(f\"  Issue: {issue.get('issue', 'N/A')}\")
    print(f\"  Reason: {issue.get('reason', 'N/A')}\")
    if 'suggestion' in issue and issue['suggestion']:
        print(f\"  Suggestion: {issue['suggestion']}\")
    print()
print(f\"Summary: {data.get('summary', 'Issues found in your changes')}\")"
            
            echo ""
            echo -e "${RED}Please fix these issues before committing.${NC}"
            echo -e "${YELLOW}To bypass this check (not recommended), use: git commit --no-verify${NC}"
            
            rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
            exit 1
        else
            TOOL_NAME="AI review tool"
            if [ "$REVIEW_TOOL" = "cursor" ]; then
                TOOL_NAME="Cursor Agent"
            elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                TOOL_NAME="CodeRabbit"
            fi
            echo -e "${GREEN}✓ $TOOL_NAME review passed - no blocking issues found${NC}"
            SUMMARY=$(echo "$JSON_RESULT" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('summary', 'No issues found'))" 2>/dev/null || echo "Review completed")
            echo -e "${GREEN}  Summary: $SUMMARY${NC}\n"
        fi
    fi
else
    TOOL_NAME="AI review tool"
    if [ "$REVIEW_TOOL" = "cursor" ]; then
        TOOL_NAME="Cursor Agent"
    elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
        TOOL_NAME="CodeRabbit"
    fi
    echo -e "${YELLOW}⚠️  No output from $TOOL_NAME${NC}"
    echo -e "${YELLOW}⚠️  Proceeding without AI review...${NC}\n"
fi

# If Android lint/tests failed, block after running Cursor review so AI feedback is still shown
if [ "${ANDROID_LINT_FAILED:-false}" = true ] || [ "${ANDROID_TEST_FAILED:-false}" = true ]; then
    echo -e "${RED}✗ Android quality checks failed (lint/tests). Please fix before pushing.${NC}"
    exit 1
fi

# Cleanup
rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"

# ============================================
# All checks passed
# ============================================
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ All pre-push checks passed!                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"

exit 0
HOOK_SCRIPT_END

# Make the hook executable
chmod +x "$PRE_PUSH_HOOK"

echo -e "${GREEN}✓ Pre-push hook installed successfully${NC}"
echo -e "${GREEN}  Location: $PRE_PUSH_HOOK${NC}\n"

# Final verification of selected tool
if [ -n "$SELECTED_TOOL" ] && [ -n "$SELECTED_TOOL_PATH" ]; then
    TOOL_NAME="AI review tool"
    if [ "$SELECTED_TOOL" = "cursor" ]; then
        TOOL_NAME="Cursor Agent"
    elif [ "$SELECTED_TOOL" = "coderabbit" ]; then
        TOOL_NAME="CodeRabbit"
    fi
    echo -e "${GREEN}✓ $TOOL_NAME configured for code reviews${NC}\n"
fi

# Final instructions
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Installation Complete!                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Create the pre-commit hook (warnings only, doesn't block)
echo -e "${BLUE}📝 Installing pre-commit hook...${NC}"

# Find SwiftLint path
SWIFTLINT_PATH=""
if command -v swiftlint &> /dev/null; then
    SWIFTLINT_PATH=$(which swiftlint)
elif [ -f "/usr/local/bin/swiftlint" ]; then
    SWIFTLINT_PATH="/usr/local/bin/swiftlint"
elif [ -f "/opt/homebrew/bin/swiftlint" ]; then
    SWIFTLINT_PATH="/opt/homebrew/bin/swiftlint"
fi

cat > "$PRE_COMMIT_HOOK" << 'PRE_COMMIT_START'
#!/bin/bash

# Pre-commit hook for mobile projects (iOS/Android)
# Runs SwiftLint and Android lint (if applicable) and shows warnings only
# Does NOT block commits - only provides feedback

set +e  # Don't exit on errors - we want to warn, not block

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRE_COMMIT_START

echo "SWIFTLINT_PATH=\"$SWIFTLINT_PATH\"" >> "$PRE_COMMIT_HOOK"
echo "PROJECT_ROOT=\"$GIT_ROOT\"" >> "$PRE_COMMIT_HOOK"
echo "REVIEW_TOOL=\"$SELECTED_TOOL\"" >> "$PRE_COMMIT_HOOK"
echo "REVIEW_TOOL_PATH=\"$SELECTED_TOOL_PATH\"" >> "$PRE_COMMIT_HOOK"
echo "CURSOR_CLI=\"$CURSOR_PATH\"" >> "$PRE_COMMIT_HOOK"
echo "CODERABBIT_CLI=\"$CODERABBIT_PATH\"" >> "$PRE_COMMIT_HOOK"
echo "IS_IOS_PROJECT=\"$IS_IOS_PROJECT\"" >> "$PRE_COMMIT_HOOK"
echo "IS_ANDROID_PROJECT=\"$IS_ANDROID_PROJECT\"" >> "$PRE_COMMIT_HOOK"
echo "ANDROID_GRADLEW=\"$ANDROID_GRADLEW\"" >> "$PRE_COMMIT_HOOK"
echo "ANDROID_WORKDIR=\"$ANDROID_WORKDIR\"" >> "$PRE_COMMIT_HOOK"

cat >> "$PRE_COMMIT_HOOK" << 'PRE_COMMIT_END'

echo -e "${BLUE}🔍 Running pre-commit checks (warnings only)...${NC}\n"

# Detect platform at hook runtime
IS_IOS="$IS_IOS_PROJECT"
IS_ANDROID="$IS_ANDROID_PROJECT"

IOS_PROJECT=$(find "$PROJECT_ROOT" -maxdepth 3 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | head -n 1)
if [ -n "$IOS_PROJECT" ]; then
    IS_IOS=true
fi

ANDROID_GRADLEW_PATH="$ANDROID_GRADLEW"
ANDROID_WORKDIR_PATH="$ANDROID_WORKDIR"
if [ -z "$ANDROID_GRADLEW_PATH" ]; then
    if [ -x "$PROJECT_ROOT/gradlew" ]; then
        ANDROID_GRADLEW_PATH="$PROJECT_ROOT/gradlew"
        ANDROID_WORKDIR_PATH="$PROJECT_ROOT"
    elif [ -x "$PROJECT_ROOT/android/gradlew" ]; then
        ANDROID_GRADLEW_PATH="$PROJECT_ROOT/android/gradlew"
        ANDROID_WORKDIR_PATH="$PROJECT_ROOT/android"
    fi
fi
if [ -n "$ANDROID_GRADLEW_PATH" ]; then
    IS_ANDROID=true
fi

# Optional override via env: MOBILE_PLATFORM=ios|android|native (native => both)
if [ -n "$MOBILE_PLATFORM" ]; then
    PLATFORM_LOWER=$(echo "$MOBILE_PLATFORM" | tr '[:upper:]' '[:lower:]')
    case "$PLATFORM_LOWER" in
        ios)
            IS_IOS=true
            IS_ANDROID=false
            ;;
        android)
            IS_IOS=false
            IS_ANDROID=true
            ;;
        native|both|all)
            IS_IOS=true
            IS_ANDROID=true
            ;;
        *)
            # Unknown override, keep autodetected values
            ;;
    esac
fi

echo -e "${BLUE}Platforms:${NC}"
if [ "$IS_IOS" = true ]; then
    echo -e "  • ${GREEN}iOS checks enabled${NC}"
else
    echo -e "  • ${YELLOW}iOS checks disabled (no project detected)${NC}"
fi
if [ "$IS_ANDROID" = true ]; then
    echo -e "  • ${GREEN}Android checks enabled${NC}"
else
    echo -e "  • ${YELLOW}Android checks disabled (no Gradle wrapper found)${NC}"
fi
echo ""

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM || true)
STAGED_SWIFT_FILES=$(echo "$STAGED_FILES" | grep '\.swift$' || true)
STAGED_ANDROID_FILES=$(echo "$STAGED_FILES" | grep -E '\.(kt|kts|java|xml|gradle|gradle\.kts)$' || true)

if [ -z "$STAGED_SWIFT_FILES" ] && [ -z "$STAGED_ANDROID_FILES" ]; then
    echo -e "${GREEN}✓ No iOS or Android files staged for commit${NC}"
    exit 0
fi

if [ -n "$STAGED_SWIFT_FILES" ]; then
    echo -e "${BLUE}📝 Staged Swift files:${NC}"
    echo "$STAGED_SWIFT_FILES"
    echo ""
fi

if [ -n "$STAGED_ANDROID_FILES" ]; then
    echo -e "${BLUE}📝 Staged Android-related files:${NC}"
    echo "$STAGED_ANDROID_FILES"
    echo ""
fi

cd "$PROJECT_ROOT"

# ============================================
# Step 1: Run SwiftLint (if available)
# ============================================
if [ "$IS_IOS" = true ] && [ -n "$STAGED_SWIFT_FILES" ]; then
    SWIFTLINT_AVAILABLE=false
    SWIFTLINT_CMD=""
    if command -v swiftlint &> /dev/null; then
        SWIFTLINT_CMD=$(command -v swiftlint)
        SWIFTLINT_AVAILABLE=true
    elif [ -f "/usr/local/bin/swiftlint" ]; then
        SWIFTLINT_CMD="/usr/local/bin/swiftlint"
        SWIFTLINT_AVAILABLE=true
    elif [ -f "/opt/homebrew/bin/swiftlint" ]; then
        SWIFTLINT_CMD="/opt/homebrew/bin/swiftlint"
        SWIFTLINT_AVAILABLE=true
    fi

    if [ "$SWIFTLINT_AVAILABLE" = "true" ]; then
        echo -e "${BLUE}🔎 Running SwiftLint...${NC}"
        
        HAS_LINT_ISSUES=false
        SWIFTLINT_OUTPUT=""
        
        for file in $STAGED_SWIFT_FILES; do
            if [ -f "$PROJECT_ROOT/$file" ]; then
                FILE_OUTPUT=$("$SWIFTLINT_CMD" lint "$PROJECT_ROOT/$file" 2>&1)
                FILE_EXIT_CODE=$?
                
                if [ $FILE_EXIT_CODE -ne 0 ]; then
                    HAS_LINT_ISSUES=true
                    SWIFTLINT_OUTPUT="$SWIFTLINT_OUTPUT$FILE_OUTPUT\n"
                fi
            fi
        done
        
        if [ "$HAS_LINT_ISSUES" = true ]; then
            echo -e "${YELLOW}⚠️  SwiftLint found issues (warnings only - commit will proceed):${NC}"
            echo -e "$SWIFTLINT_OUTPUT"
            echo ""
            echo -e "${YELLOW}💡 Tip: Consider fixing these issues before committing${NC}\n"
        else
            echo -e "${GREEN}✓ SwiftLint passed${NC}\n"
        fi
    else
        echo -e "${YELLOW}⚠️  SwiftLint not available, skipping lint checks${NC}\n"
        echo -e "${YELLOW}  Install with: brew install swiftlint${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping SwiftLint (no iOS project or no Swift files)${NC}\n"
fi

# ============================================
# Step 1.5: Run Android lint (warnings only)
# ============================================
if [ "$IS_ANDROID" = true ] && [ -n "$STAGED_ANDROID_FILES" ]; then
    echo -e "${BLUE}🤖 Running Android lint (warnings only)...${NC}"
    (cd "$ANDROID_WORKDIR_PATH" && "$ANDROID_GRADLEW_PATH" lint)
    ANDROID_LINT_EXIT=$?
    if [ $ANDROID_LINT_EXIT -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Android lint reported issues (commit will proceed)${NC}\n"
    else
        echo -e "${GREEN}✓ Android lint passed${NC}\n"
    fi
elif [ -n "$STAGED_ANDROID_FILES" ]; then
    echo -e "${YELLOW}⚠️  Android changes detected but Gradle wrapper not found. Skipping Android lint.${NC}\n"
fi

# ============================================
# Step 2: Run AI Code Review (warnings only)
# ============================================
# Determine which tool to use (runtime fallback if not set)
if [ -z "$REVIEW_TOOL" ]; then
    # Try to detect at runtime
    if [ -n "$REVIEW_TOOL_PATH" ] && [ -f "$REVIEW_TOOL_PATH" ]; then
        if echo "$REVIEW_TOOL_PATH" | grep -qi "cursor"; then
            REVIEW_TOOL="cursor"
        elif echo "$REVIEW_TOOL_PATH" | grep -qi "coderabbit"; then
            REVIEW_TOOL="coderabbit"
        fi
    fi
    
    # Fallback: try to find available tool
    if [ -z "$REVIEW_TOOL" ]; then
        # Check CodeRabbit authentication by parsing output
        if command -v coderabbit &> /dev/null; then
            CODERABBIT_AUTH_OUTPUT=$(coderabbit auth status 2>&1) || CODERABBIT_AUTH_EXIT=$?
            CODERABBIT_AUTH_EXIT=${CODERABBIT_AUTH_EXIT:-0}
            if echo "$CODERABBIT_AUTH_OUTPUT" | grep -qiE "authenticated.*yes|logged in.*yes|✓.*authenticated|successfully authenticated" || \
               ([ $CODERABBIT_AUTH_EXIT -eq 0 ] && ! echo "$CODERABBIT_AUTH_OUTPUT" | grep -qi "not logged in\|not authenticated"); then
                REVIEW_TOOL="coderabbit"
                REVIEW_TOOL_PATH=$(which coderabbit)
            fi
        fi
        # Check Cursor if CodeRabbit not available
        if [ -z "$REVIEW_TOOL" ] && [ -n "$CURSOR_CLI" ] && [ -f "$CURSOR_CLI" ] && "$CURSOR_CLI" agent status >/dev/null 2>&1; then
            REVIEW_TOOL="cursor"
            REVIEW_TOOL_PATH="$CURSOR_CLI"
        fi
    fi
fi

if [ -n "$REVIEW_TOOL" ] && [ -n "$REVIEW_TOOL_PATH" ] && [ -f "$REVIEW_TOOL_PATH" ]; then
    # Check if tool is authenticated
    TOOL_AUTHENTICATED=false
    if [ "$REVIEW_TOOL" = "cursor" ]; then
        if "$REVIEW_TOOL_PATH" agent status >/dev/null 2>&1; then
            TOOL_AUTHENTICATED=true
        fi
    elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
        # Check authentication by parsing output (auth status may return non-zero even when authenticated)
        CODERABBIT_AUTH_OUTPUT=$("$REVIEW_TOOL_PATH" auth status 2>&1) || CODERABBIT_AUTH_EXIT=$?
        CODERABBIT_AUTH_EXIT=${CODERABBIT_AUTH_EXIT:-0}
        
        # Check if output indicates authentication (look for success indicators)
        # CodeRabbit shows "Not logged in" when not authenticated, or success messages when authenticated
        if echo "$CODERABBIT_AUTH_OUTPUT" | grep -qiE "authenticated.*yes|logged in.*yes|✓.*authenticated|successfully authenticated" || \
           ([ $CODERABBIT_AUTH_EXIT -eq 0 ] && ! echo "$CODERABBIT_AUTH_OUTPUT" | grep -qi "not logged in\|not authenticated"); then
            TOOL_AUTHENTICATED=true
        fi
    fi
    
    if [ "$TOOL_AUTHENTICATED" = true ]; then
        TOOL_NAME="AI review tool"
        if [ "$REVIEW_TOOL" = "cursor" ]; then
            TOOL_NAME="Cursor Agent"
        elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
            TOOL_NAME="CodeRabbit"
        fi
        echo -e "${BLUE}🤖 Running $TOOL_NAME code review (warnings only)...${NC}"
        
        # Get the diff of staged changes
        STAGED_DIFF=$(git diff --cached)
        
        # Trim very large diffs to avoid Cursor token limits
        MAX_DIFF_CHARS=120000
        MAX_DIFF_LINES=1200
        DIFF_NOTE=""
        REVIEW_DIFF="$STAGED_DIFF"
        if [ ${#REVIEW_DIFF} -gt $MAX_DIFF_CHARS ]; then
            DIFF_NOTE="(Diff truncated to first $MAX_DIFF_LINES lines to avoid size limits.)"
            REVIEW_DIFF=$(echo "$REVIEW_DIFF" | head -n $MAX_DIFF_LINES)
            echo -e "${YELLOW}⚠️  Large diff detected - limiting AI review to first $MAX_DIFF_LINES lines${NC}"
        fi
        
        if [ -n "$STAGED_DIFF" ]; then
            # Create a temporary file with the diff
            TEMP_DIFF_FILE=$(mktemp)
            echo "$REVIEW_DIFF" > "$TEMP_DIFF_FILE"
            
            # Prepare the prompt for Cursor Agent (less strict for pre-commit)
            PLATFORM_CONTEXT="$( [ "$IS_IOS" = true ] && [ "$IS_ANDROID" = true ] && echo "iOS (Swift) and Android (Kotlin/Java)" || ( [ "$IS_IOS" = true ] && echo "iOS (Swift)" || ( [ "$IS_ANDROID" = true ] && echo "Android (Kotlin/Java)" || echo "mobile" ) ) )"
            REVIEW_PROMPT="You are a code reviewer for a mobile project. Platform context: $PLATFORM_CONTEXT. Review the staged changes and identify any issues. Be helpful but not overly strict.

Look for (flag as critical/high when severe):
- For iOS/Swift: force unwrapping (!), retain cycles, unsafe optional handling, missing error handling that can crash, UI work on background threads
- For Android/Kotlin/Java: unsafe !! or null handling issues, lifecycle leaks, coroutine misuse, blocking work on main thread, exported components/security issues
- Security vulnerabilities (hardcoded secrets, insecure storage)
- Logic errors that could cause crashes
- Thread safety violations
- Performance issues (main thread blocking, heavy operations)

Respond ONLY in the following JSON format:
{
  \"has_critical_issues\": true/false,
  \"critical_issues\": [
    {
      \"severity\": \"critical\" | \"high\" | \"medium\",
      \"file\": \"path/to/file.swift\",
      \"line\": 123,
      \"issue\": \"Description of the issue\",
      \"reason\": \"Why this should be fixed\",
      \"suggestion\": \"How to fix it (optional)\"
    }
  ],
  \"summary\": \"Brief summary of findings\"
}

Here are the staged changes to review:

${DIFF_NOTE:+$DIFF_NOTE
}
\`\`\`diff
$REVIEW_DIFF
\`\`\`

Respond ONLY with the JSON format above, no additional text."
            
            # Run AI review tool in non-interactive mode
            REVIEW_OUTPUT_FILE=$(mktemp)
            REVIEW_ERROR_FILE=$(mktemp)
            
            echo -e "${BLUE}Analyzing code changes... (this may take a moment)${NC}"
            
            # macOS-compatible timeout: try gtimeout (coreutils), then use bash-based timeout
            TIMEOUT_SECONDS=300
            REVIEW_EXIT_CODE=0
            
            if [ "$REVIEW_TOOL" = "cursor" ]; then
                # Run Cursor Agent
                if command -v gtimeout &> /dev/null; then
                    if gtimeout ${TIMEOUT_SECONDS}s "$REVIEW_TOOL_PATH" agent --print --output-format json "$REVIEW_PROMPT" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE"; then
                        REVIEW_EXIT_CODE=0
                    else
                        REVIEW_EXIT_CODE=$?
                    fi
                else
                    # Bash-based timeout implementation for macOS
                    "$REVIEW_TOOL_PATH" agent --print --output-format json "$REVIEW_PROMPT" > "$REVIEW_OUTPUT_FILE" 2> "$REVIEW_ERROR_FILE" &
                    REVIEW_PID=$!
                    
                    for i in $(seq 1 $TIMEOUT_SECONDS); do
                        if ! kill -0 $REVIEW_PID 2>/dev/null; then
                            set +e
                            wait $REVIEW_PID
                            REVIEW_EXIT_CODE=$?
                            set -e
                            break
                        fi
                        sleep 1
                    done
                    
                    if kill -0 $REVIEW_PID 2>/dev/null; then
                        kill $REVIEW_PID 2>/dev/null || true
                        set +e
                        wait $REVIEW_PID 2>/dev/null || true
                        set -e
                        REVIEW_EXIT_CODE=124
                    fi
                fi
            elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                # Run CodeRabbit - Use --plain flag for non-interactive output and --type uncommitted for staged changes
                REVIEW_EXIT_CODE=1
                
                # Try format 1: Run in git repo context with --plain and --type uncommitted (for staged changes)
                # Capture both stdout and stderr since CodeRabbit might output review to either
                if command -v gtimeout &> /dev/null; then
                    if (cd "$PROJECT_ROOT" && gtimeout ${TIMEOUT_SECONDS}s "$REVIEW_TOOL_PATH" review --plain --type uncommitted > "$REVIEW_OUTPUT_FILE" 2>&1); then
                        REVIEW_EXIT_CODE=0
                    else
                        REVIEW_EXIT_CODE=$?
                    fi
                else
                    (cd "$PROJECT_ROOT" && "$REVIEW_TOOL_PATH" review --plain --type uncommitted > "$REVIEW_OUTPUT_FILE" 2>&1) &
                    REVIEW_PID=$!
                    
                    for i in $(seq 1 $TIMEOUT_SECONDS); do
                        if ! kill -0 $REVIEW_PID 2>/dev/null; then
                            set +e
                            wait $REVIEW_PID
                            REVIEW_EXIT_CODE=$?
                            set -e
                            break
                        fi
                        sleep 1
                    done
                    
                    if kill -0 $REVIEW_PID 2>/dev/null; then
                        kill $REVIEW_PID 2>/dev/null || true
                        set +e
                        wait $REVIEW_PID 2>/dev/null || true
                        set -e
                        REVIEW_EXIT_CODE=124
                    fi
                fi
                
                # Try format 2: Run with --plain but without --type (if format 1 failed)
                # Capture both stdout and stderr since CodeRabbit might output review to either
                if [ $REVIEW_EXIT_CODE -ne 0 ] && [ $REVIEW_EXIT_CODE -ne 124 ]; then
                    if command -v gtimeout &> /dev/null; then
                        if (cd "$PROJECT_ROOT" && gtimeout ${TIMEOUT_SECONDS}s "$REVIEW_TOOL_PATH" review --plain > "$REVIEW_OUTPUT_FILE" 2>&1); then
                            REVIEW_EXIT_CODE=0
                        fi
                    else
                        (cd "$PROJECT_ROOT" && "$REVIEW_TOOL_PATH" review --plain > "$REVIEW_OUTPUT_FILE" 2>&1) &
                        REVIEW_PID=$!
                        
                        for i in $(seq 1 $TIMEOUT_SECONDS); do
                            if ! kill -0 $REVIEW_PID 2>/dev/null; then
                                set +e
                                wait $REVIEW_PID
                                REVIEW_EXIT_CODE=$?
                                set -e
                                break
                            fi
                            sleep 1
                        done
                        
                        if kill -0 $REVIEW_PID 2>/dev/null; then
                            kill $REVIEW_PID 2>/dev/null || true
                            set +e
                            wait $REVIEW_PID 2>/dev/null || true
                            set -e
                            REVIEW_EXIT_CODE=124
                        fi
                    fi
                fi
            fi
            
            # Clean up temp diff file
            rm -f "$TEMP_DIFF_FILE"
            
            TOOL_NAME="AI review tool"
            if [ "$REVIEW_TOOL" = "cursor" ]; then
                TOOL_NAME="Cursor Agent"
            elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                TOOL_NAME="CodeRabbit"
            fi
            
            if [ $REVIEW_EXIT_CODE -eq 124 ]; then
                echo -e "${YELLOW}⚠️  $TOOL_NAME review timed out after $TIMEOUT_SECONDS seconds${NC}"
                echo -e "${YELLOW}⚠️  Skipping AI review...${NC}\n"
                rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
            elif [ $REVIEW_EXIT_CODE -ne 0 ]; then
                echo -e "${YELLOW}⚠️  $TOOL_NAME review failed (warnings only - commit will proceed)${NC}"
                echo -e "${YELLOW}  Exit code: $REVIEW_EXIT_CODE${NC}"
                if [ -s "$REVIEW_ERROR_FILE" ]; then
                    echo -e "${YELLOW}  Error output:${NC}"
                    cat "$REVIEW_ERROR_FILE"
                fi
                if [ -s "$REVIEW_OUTPUT_FILE" ]; then
                    echo -e "${YELLOW}  Output (may contain review results):${NC}"
                    cat "$REVIEW_OUTPUT_FILE"
                    echo ""
                fi
                echo ""
                rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
            elif [ -s "$REVIEW_OUTPUT_FILE" ]; then
                # Show raw output for debugging (especially for CodeRabbit which might output plain text)
                REVIEW_RESULT=$(cat "$REVIEW_OUTPUT_FILE")
                
                # For CodeRabbit, it outputs plain text (not JSON)
                # Always show the full review output so users can see the comments
                if [ "$REVIEW_TOOL" = "coderabbit" ]; then
                    # Trim whitespace and check if there's actual content
                    REVIEW_RESULT_TRIMMED=$(echo "$REVIEW_RESULT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    
                    if [ -n "$REVIEW_RESULT_TRIMMED" ]; then
                        # Filter out just status messages to see if there's actual review content
                        # Status messages typically include: "Starting", "Connecting", "Setting up", "Analyzing", "Reviewing", "Review completed"
                        REVIEW_CONTENT=$(echo "$REVIEW_RESULT" | grep -v -iE "^(Starting|Connecting|Setting up|Analyzing|Reviewing|Review completed)" | grep -v "^$" || echo "$REVIEW_RESULT")
                        
                        # Check if there's actual review content beyond status messages
                        if [ -n "$(echo "$REVIEW_CONTENT" | tr -d '[:space:]')" ] && [ "$REVIEW_CONTENT" != "$REVIEW_RESULT" ]; then
                            # Has review content beyond status messages
                            echo -e "${YELLOW}⚠️  CodeRabbit Review Results (warnings only - commit will proceed):${NC}\n"
                            echo "$REVIEW_CONTENT"
                            echo ""
                            echo -e "${YELLOW}💡 Tip: Consider addressing these review comments before committing${NC}\n"
                        elif echo "$REVIEW_RESULT_TRIMMED" | grep -qiE "warning|error|issue|problem|suggestion|fix|critical|high|medium|🔴|🟠|🟡|⚠️|❌|recommend|consider|should|improve"; then
                            # Contains review keywords - show full output
                            echo -e "${YELLOW}⚠️  CodeRabbit Review Results (warnings only - commit will proceed):${NC}\n"
                            echo "$REVIEW_RESULT"
                            echo ""
                            echo -e "${YELLOW}💡 Tip: Consider addressing these review comments before committing${NC}\n"
                        else
                            # Show full output anyway - user should see what CodeRabbit said
                            echo -e "${BLUE}📋 CodeRabbit Review Output:${NC}\n"
                            echo "$REVIEW_RESULT"
                            echo ""
                            echo -e "${GREEN}✓ No critical issues detected in review output${NC}\n"
                        fi
                        rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
                    else
                        # Empty output
                        echo -e "${GREEN}✓ CodeRabbit review completed - no output received${NC}\n"
                        rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
                    fi
                else
                    # Parse the AI review tool output using the same extraction logic as pre-push (for Cursor)
                JSON_RESULT=$(REVIEW_OUTPUT_FILE="$REVIEW_OUTPUT_FILE" python3 << 'PYTHON_EOF'
import sys, json
import os
import re

def extract_json_with_string_tracking(text, start_idx):
    """Extract JSON object starting at start_idx, properly tracking strings"""
    if start_idx < 0 or start_idx >= len(text):
        return None
    
    brace_count = 0
    in_string = False
    escape_next = False
    
    for i in range(start_idx, len(text)):
        char = text[i]
        
        if escape_next:
            escape_next = False
            continue
        
        if char == '\\':
            escape_next = True
            continue
        
        if char == '"' and not escape_next:
            in_string = not in_string
            continue
        
        if not in_string:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    json_str = text[start_idx:i+1]
                    try:
                        parsed = json.loads(json_str)
                        return parsed
                    except json.JSONDecodeError:
                        pass
                    return None
    
    return None

def extract_from_code_block(text):
    """Extract JSON from a code block like ```json ... ```"""
    backtick = chr(96)
    code_marker = backtick + backtick + backtick + 'json'
    code_start = text.find(code_marker)
    
    if code_start >= 0:
        json_start = code_start + len(code_marker)
        while json_start < len(text) and text[json_start] in [' ', '\n', '\r', '\t']:
            json_start += 1
        
        if json_start < len(text) and text[json_start] == '{':
            parsed = extract_json_with_string_tracking(text, json_start)
            if parsed:
                return parsed
            
            code_end = text.find(backtick + backtick + backtick, json_start)
            if code_end > json_start:
                json_candidate = text[json_start:code_end].strip().rstrip()
                try:
                    parsed = json.loads(json_candidate)
                    return parsed
                except:
                    pass
    
    return None

try:
    review_file = os.environ.get('REVIEW_OUTPUT_FILE')
    if review_file and os.path.exists(review_file):
        with open(review_file, 'r', encoding='utf-8') as f:
            input_data = f.read()
    else:
        input_data = sys.stdin.read()
    
    data = json.loads(input_data)
    
    if 'result' in data and isinstance(data['result'], str):
        result_str = data['result']
        
        parsed = extract_from_code_block(result_str)
        if parsed:
            print(json.dumps(parsed))
            sys.exit(0)
        
        start_idx = result_str.find('{"has_critical_issues"')
        if start_idx >= 0:
            parsed = extract_json_with_string_tracking(result_str, start_idx)
            if parsed:
                print(json.dumps(parsed))
                sys.exit(0)
        
        match = re.search(r'\{[^{]*"has_critical_issues"', result_str)
        if match:
            parsed = extract_json_with_string_tracking(result_str, match.start())
            if parsed:
                print(json.dumps(parsed))
                sys.exit(0)
        
        print('{}')
    elif 'has_critical_issues' in data:
        print(json.dumps(data))
    else:
        print('{}')
except Exception as e:
    try:
        text = sys.stdin.read()
        start_idx = text.find('{"has_critical_issues"')
        if start_idx >= 0:
            parsed = extract_json_with_string_tracking(text, start_idx)
            if parsed:
                print(json.dumps(parsed))
                sys.exit(0)
        
        parsed = extract_from_code_block(text)
        if parsed:
            print(json.dumps(parsed))
            sys.exit(0)
        
        print('{}')
    except:
        print('{}')
PYTHON_EOF
)
                
                # Check if we got valid JSON
                if echo "$JSON_RESULT" | python3 -m json.tool >/dev/null 2>&1; then
                    # Extract issues - also check has_critical_issues flag
                    ISSUE_DATA=$(echo "$JSON_RESULT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    issues = data.get('critical_issues', [])
    issue_count = len(issues) if isinstance(issues, list) else 0
    has_flag = data.get('has_critical_issues', False)
    # If flag is true but array is empty, still count as having issues
    if has_flag and issue_count == 0:
        issue_count = 1
    print(f\"{issue_count}|{has_flag}\")
except Exception as e:
    print('0|false', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null || echo "0|false")
                    
                    ISSUE_COUNT=$(echo "$ISSUE_DATA" | cut -d'|' -f1)
                    HAS_FLAG=$(echo "$ISSUE_DATA" | cut -d'|' -f2)
                    
                    if [ "$ISSUE_COUNT" -gt 0 ] || [ "$HAS_FLAG" = "true" ]; then
                        TOOL_NAME="AI review tool"
                        if [ "$REVIEW_TOOL" = "cursor" ]; then
                            TOOL_NAME="Cursor Agent"
                        elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                            TOOL_NAME="CodeRabbit"
                        fi
                        echo -e "${YELLOW}⚠️  $TOOL_NAME found issues (warnings only - commit will proceed):${NC}\n"
                        
                        # Display issues
                        DISPLAY_OUTPUT=$(echo "$JSON_RESULT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    issues = data.get('critical_issues', [])
    
    if isinstance(issues, list) and len(issues) > 0:
        for i, issue in enumerate(issues, 1):
            severity = issue.get('severity', 'medium').lower()
            if severity == 'critical':
                severity_marker = '🔴 CRITICAL'
            elif severity == 'high':
                severity_marker = '🟠 HIGH'
            else:
                severity_marker = '🟡 MEDIUM'
            
            print(f\"Issue #{i} [{severity_marker}]:\")
            print(f\"  File: {issue.get('file', 'N/A')}\")
            if 'line' in issue:
                print(f\"  Line: {issue['line']}\")
            print(f\"  Issue: {issue.get('issue', 'N/A')}\")
            if 'reason' in issue and issue['reason']:
                print(f\"  Reason: {issue['reason']}\")
            if 'suggestion' in issue and issue['suggestion']:
                print(f\"  Suggestion: {issue['suggestion']}\")
            print()
    else:
        # No issues in array but flag says there are issues - show summary
        summary = data.get('summary', 'Issues were detected but details are not available')
        print(f\"Note: {summary}\")
        print(\"  (Issue details were not provided in the response)\")
        print()
    
    summary = data.get('summary', 'Issues found')
    if summary:
        print(f\"Summary: {summary}\")
except Exception as e:
    print(f\"Error displaying issues: {e}\", file=sys.stderr)
    sys.exit(1)
" 2>&1)
                        
                        if [ -n "$DISPLAY_OUTPUT" ]; then
                            echo "$DISPLAY_OUTPUT"
                        else
                            echo -e "${YELLOW}  (Issues were detected but could not be displayed)${NC}"
                        fi
                        echo ""
                        echo -e "${YELLOW}💡 Tip: Consider fixing these issues before committing${NC}\n"
                    else
                        TOOL_NAME="AI review tool"
                        if [ "$REVIEW_TOOL" = "cursor" ]; then
                            TOOL_NAME="Cursor Agent"
                        elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                            TOOL_NAME="CodeRabbit"
                        fi
                        echo -e "${GREEN}✓ $TOOL_NAME review passed - no issues found${NC}\n"
                    fi
                else
                    # JSON parsing failed - show raw output for debugging
                    TOOL_NAME="AI review tool"
                    if [ "$REVIEW_TOOL" = "cursor" ]; then
                        TOOL_NAME="Cursor Agent"
                    elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                        TOOL_NAME="CodeRabbit"
                    fi
                    echo -e "${YELLOW}⚠️  Could not parse $TOOL_NAME response as JSON${NC}"
                    echo -e "${BLUE}  Showing raw output for debugging:${NC}\n"
                    if [ -n "$REVIEW_RESULT" ] && [ -n "$(echo "$REVIEW_RESULT" | tr -d '[:space:]')" ]; then
                        echo "$REVIEW_RESULT"
                        echo ""
                    else
                        echo -e "${YELLOW}  (Output was empty)${NC}\n"
                    fi
                    if [ -s "$REVIEW_ERROR_FILE" ]; then
                        echo -e "${YELLOW}  Error output:${NC}"
                        cat "$REVIEW_ERROR_FILE"
                        echo ""
                    fi
                fi
                
                rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
                fi
            else
                TOOL_NAME="AI review tool"
                if [ "$REVIEW_TOOL" = "cursor" ]; then
                    TOOL_NAME="Cursor Agent"
                elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                    TOOL_NAME="CodeRabbit"
                fi
                echo -e "${YELLOW}⚠️  No output from $TOOL_NAME${NC}\n"
                rm -f "$REVIEW_OUTPUT_FILE" "$REVIEW_ERROR_FILE"
            fi
        else
            TOOL_NAME="AI review tool"
            if [ "$REVIEW_TOOL" = "cursor" ]; then
                TOOL_NAME="Cursor Agent"
            elif [ "$REVIEW_TOOL" = "coderabbit" ]; then
                TOOL_NAME="CodeRabbit"
            fi
            echo -e "${YELLOW}⚠️  $TOOL_NAME is not authenticated. Run authentication command first.${NC}\n"
        fi
    else
        echo -e "${YELLOW}⚠️  No AI review tool available, skipping AI review${NC}\n"
    fi
fi

# ============================================
# All checks complete - always allow commit
# ============================================
echo -e "${GREEN}✓ Pre-commit checks complete (warnings only)${NC}\n"
echo -e "${BLUE}ℹ️  This hook provides warnings but does not block commits${NC}\n"

exit 0
PRE_COMMIT_END

# Make the hook executable
chmod +x "$PRE_COMMIT_HOOK"

echo -e "${GREEN}✓ Pre-commit hook installed successfully${NC}"
echo -e "${GREEN}  Location: $PRE_COMMIT_HOOK${NC}\n"

echo -e "${GREEN}The pre-push hook is now active and will run on every push.${NC}\n"

echo -e "${BLUE}What the hooks do:${NC}"
echo -e "${GREEN}Pre-commit hook (warnings only):${NC}"
echo -e "  1. ✓ Runs SwiftLint on staged Swift files (if available)"
echo -e "  2. ⚠️  Shows warnings but does NOT block commits\n"
echo -e "${GREEN}Pre-push hook (strict):${NC}"
echo -e "  1. ✓ Runs SwiftLint on Swift files being pushed (if available)"
TOOL_NAME="AI tool"
if [ "$SELECTED_TOOL" = "cursor" ]; then
    TOOL_NAME="Cursor Agent"
elif [ "$SELECTED_TOOL" = "coderabbit" ]; then
    TOOL_NAME="CodeRabbit"
fi
echo -e "  2. ✓ Uses $TOOL_NAME to review code changes for critical issues"
echo -e "  3. ✓ Blocks push if critical problems are found\n"

echo -e "${BLUE}Usage:${NC}"
echo -e "  • Normal commit: ${GREEN}git commit -m \"message\"${NC} (warnings only)"
echo -e "  • Normal push: ${GREEN}git push${NC} (strict checks)"
echo -e "  • Bypass hook (emergency): ${YELLOW}git commit --no-verify${NC} or ${YELLOW}git push --no-verify${NC}\n"

echo -e "${BLUE}For more information:${NC}"
echo -e "  See: .git/hooks/README.md\n"

exit 0
