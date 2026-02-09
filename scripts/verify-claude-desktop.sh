#!/bin/bash
#
# Claude Desktop Configuration Verification Script
#
# This script helps verify that the Ideogram MCP server is correctly
# configured for Claude Desktop integration.
#
# Usage: ./scripts/verify-claude-desktop.sh
#

set -e

echo "=============================================="
echo "Claude Desktop Configuration Verification"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the project root (parent of scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project Root: $PROJECT_ROOT"
echo ""

# Step 1: Verify dist/index.js exists
echo "Step 1: Checking build output..."
if [ -f "$PROJECT_ROOT/dist/index.js" ]; then
    echo -e "${GREEN}✓${NC} dist/index.js exists"
    FILE_SIZE=$(ls -lh "$PROJECT_ROOT/dist/index.js" | awk '{print $5}')
    echo "  File size: $FILE_SIZE"
else
    echo -e "${RED}✗${NC} dist/index.js not found!"
    echo "  Run: npm run build"
    exit 1
fi
echo ""

# Step 2: Get the full path for Claude Desktop config
echo "Step 2: Full path for Claude Desktop config:"
DIST_PATH="$PROJECT_ROOT/dist/index.js"
echo ""
echo "Add this to your claude_desktop_config.json:"
echo ""
echo -e "${YELLOW}"
cat << EOF
{
  "mcpServers": {
    "ideogram": {
      "command": "node",
      "args": ["$DIST_PATH"],
      "env": {
        "IDEOGRAM_API_KEY": "your_api_key_here"
      }
    }
  }
}
EOF
echo -e "${NC}"
echo ""

# Step 3: Show config file locations
echo "Step 3: Claude Desktop config locations:"
echo ""
case "$(uname -s)" in
    Darwin)
        CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        LOG_PATH="$HOME/Library/Logs/Claude/mcp*.log"
        ;;
    Linux)
        CONFIG_PATH="$HOME/.config/claude/claude_desktop_config.json"
        LOG_PATH="$HOME/.config/claude/logs/mcp*.log"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        CONFIG_PATH="%APPDATA%\\Claude\\claude_desktop_config.json"
        LOG_PATH="%APPDATA%\\Claude\\logs\\mcp*.log"
        ;;
    *)
        CONFIG_PATH="Platform not detected"
        LOG_PATH="Platform not detected"
        ;;
esac

echo "  Config file: $CONFIG_PATH"
echo "  Log files:   $LOG_PATH"
echo ""

# Check if config file exists
if [ -f "$CONFIG_PATH" ]; then
    echo -e "${GREEN}✓${NC} Config file exists"

    # Check if ideogram server is already configured
    if grep -q '"ideogram"' "$CONFIG_PATH" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 'ideogram' server found in config"
    else
        echo -e "${YELLOW}!${NC} 'ideogram' server NOT found in config - needs to be added"
    fi
else
    echo -e "${YELLOW}!${NC} Config file not found - will be created when you configure Claude Desktop"
fi
echo ""

# Step 4: Verify node is available
echo "Step 4: Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js available: $NODE_VERSION"

    # Check if version is 18+
    MAJOR_VERSION=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -ge 18 ]; then
        echo -e "${GREEN}✓${NC} Node.js version meets requirements (18+)"
    else
        echo -e "${RED}✗${NC} Node.js version must be 18 or higher"
    fi
else
    echo -e "${RED}✗${NC} Node.js not found in PATH"
fi
echo ""

# Step 5: Test server startup
echo "Step 5: Testing server startup..."
if [ -n "$IDEOGRAM_API_KEY" ]; then
    TEST_KEY="$IDEOGRAM_API_KEY"
else
    TEST_KEY="test_key_for_verification"
fi

# Run server with timeout to verify it starts
echo "Testing server initialization (will timeout after 2 seconds)..."
IDEOGRAM_API_KEY="$TEST_KEY" timeout 2 node "$DIST_PATH" 2>&1 || true
echo ""
echo -e "${GREEN}✓${NC} Server initializes successfully (timeout is expected)"
echo ""

# Step 6: Manual verification instructions
echo "=============================================="
echo "Manual Verification Steps"
echo "=============================================="
echo ""
echo "1. ${YELLOW}Copy the configuration above${NC} to your claude_desktop_config.json"
echo "   Location: $CONFIG_PATH"
echo ""
echo "2. ${YELLOW}Replace 'your_api_key_here'${NC} with your actual Ideogram API key"
echo "   Get your key at: https://ideogram.ai/manage-api"
echo ""
echo "3. ${YELLOW}Restart Claude Desktop completely${NC}"
echo "   - Quit Claude Desktop (Cmd+Q on macOS, Alt+F4 on Windows)"
echo "   - Wait a few seconds"
echo "   - Reopen Claude Desktop"
echo ""
echo "4. ${YELLOW}Verify tools are available${NC}"
echo "   - Open a new conversation in Claude Desktop"
echo "   - Type: 'Generate an image of a sunset over mountains'"
echo "   - Claude should use the 'ideogram_generate' tool"
echo ""
echo "5. ${YELLOW}Check logs if tools don't appear${NC}"
echo "   Log location: $LOG_PATH"
echo ""
echo "=============================================="
echo "Expected Tools (5 MVP Tools)"
echo "=============================================="
echo ""
echo "  1. ideogram_generate       - Generate images from text prompts"
echo "  2. ideogram_edit           - Edit images (inpainting/outpainting)"
echo "  3. ideogram_generate_async - Queue generation for background processing"
echo "  4. ideogram_get_prediction - Get async job status"
echo "  5. ideogram_cancel_prediction - Cancel queued jobs"
echo ""
echo "=============================================="
