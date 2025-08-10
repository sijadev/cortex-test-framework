#!/bin/bash

# Cortex Git Hooks Installation Script
# Sets up pre-commit hooks for link validation across repositories

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 Cortex Git Hooks Installation${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/git-hooks"

# Function to install hooks in a repository
install_hooks_in_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    echo ""
    echo -e "${BLUE}📁 Installing hooks in: $repo_name${NC}"
    
    if [ ! -d "$repo_path/.git" ]; then
        echo -e "${YELLOW}⚠️  Skipping $repo_name - not a git repository${NC}"
        return 1
    fi
    
    local git_hooks_dir="$repo_path/.git/hooks"
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$git_hooks_dir"
    
    # Install pre-commit hook
    if [ -f "$HOOKS_DIR/pre-commit" ]; then
        cp "$HOOKS_DIR/pre-commit" "$git_hooks_dir/pre-commit"
        chmod +x "$git_hooks_dir/pre-commit"
        echo -e "${GREEN}✅ Pre-commit hook installed${NC}"
    else
        echo -e "${RED}❌ Pre-commit hook source not found${NC}"
        return 1
    fi
    
    # Create backup of existing hook if present
    if [ -f "$git_hooks_dir/pre-commit.backup" ]; then
        echo -e "${YELLOW}ℹ️  Backup of previous hook preserved${NC}"
    fi
    
    return 0
}

# Function to detect cortex repositories
detect_cortex_repos() {
    local base_path="$1"
    local repos=()
    
    # Look for cortex main repository
    if [ -d "$base_path/cortex" ]; then
        repos+=("$base_path/cortex")
    fi
    
    # Look for cortex-test-framework
    if [ -d "$base_path/cortex-test-framework" ]; then
        repos+=("$base_path/cortex-test-framework")
    fi
    
    # Look for other cortex-related repos
    for dir in "$base_path"/cortex-*; do
        if [ -d "$dir/.git" ]; then
            repos+=("$dir")
        fi
    done
    
    printf '%s\n' "${repos[@]}"
}

# Main installation logic
main() {
    local target_repos=()
    local install_all=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                install_all=true
                shift
                ;;
            --repo)
                target_repos+=("$2")
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --all           Install in all detected cortex repositories"
                echo "  --repo PATH     Install in specific repository path"
                echo "  --help, -h      Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --all"
                echo "  $0 --repo /path/to/cortex"
                echo "  $0 --repo ../cortex --repo ../cortex-api"
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Auto-detect repositories if none specified
    if [ ${#target_repos[@]} -eq 0 ] && [ "$install_all" = false ]; then
        echo "Auto-detecting cortex repositories..."
        local parent_dir=$(dirname "$SCRIPT_DIR")
        mapfile -t target_repos < <(detect_cortex_repos "$parent_dir")
        
        if [ ${#target_repos[@]} -eq 0 ]; then
            echo -e "${YELLOW}No cortex repositories detected.${NC}"
            echo "Use --repo PATH to specify repository locations manually."
            echo "Or --all to install in all detected git repositories."
            exit 0
        fi
        
        echo "Detected repositories:"
        for repo in "${target_repos[@]}"; do
            echo "  - $(basename "$repo")"
        done
        echo ""
    fi
    
    # Install hooks in all detected repos if --all is specified
    if [ "$install_all" = true ]; then
        local parent_dir=$(dirname "$SCRIPT_DIR")
        mapfile -t target_repos < <(detect_cortex_repos "$parent_dir")
    fi
    
    # Install hooks
    local success_count=0
    local total_count=${#target_repos[@]}
    
    for repo in "${target_repos[@]}"; do
        if install_hooks_in_repo "$repo"; then
            ((success_count++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎉 Installation Summary${NC}"
    echo "Successfully installed hooks in $success_count/$total_count repositories"
    
    if [ $success_count -eq $total_count ] && [ $total_count -gt 0 ]; then
        echo ""
        echo -e "${GREEN}✅ All hooks installed successfully!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Test the hooks with a commit containing markdown changes"
        echo "2. Configure critical files in .cortex-critical.yml"
        echo "3. Run './test-manager-enhanced.sh link-health' for current status"
        echo ""
        echo -e "${BLUE}The hooks will now validate links before each commit.${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠️  Some installations failed. Check the output above for details.${NC}"
        exit 1
    fi
}

# Check prerequisites
if [ ! -f "$HOOKS_DIR/pre-commit" ]; then
    echo -e "${RED}❌ Error: Pre-commit hook not found at $HOOKS_DIR/pre-commit${NC}"
    echo "Please ensure you're running this script from the cortex-test-framework directory."
    exit 1
fi

# Run main installation
main "$@"