#!/bin/zsh
# Cortex Test Framework Installation Script

echo "🧪 Installing Cortex Test Framework Global Command"
echo "=================================================="

# Paths
CORTEX_TEST_SCRIPT="/Users/simonjanke/Projects/cortex-test-framework/cortex-test"
LOCAL_BIN="/usr/local/bin"
HOME_BIN="$HOME/.local/bin"

# Check if script exists
if [ ! -f "$CORTEX_TEST_SCRIPT" ]; then
    echo "❌ Cortex test script not found at: $CORTEX_TEST_SCRIPT"
    exit 1
fi

# Function to install symlink
install_symlink() {
    local target_dir="$1"
    local target_path="$target_dir/cortex-test"
    
    echo "📁 Installing to: $target_dir"
    
    # Create directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        echo "   Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Remove existing symlink if it exists
    if [ -L "$target_path" ] || [ -f "$target_path" ]; then
        echo "   Removing existing cortex-test command"
        rm "$target_path"
    fi
    
    # Create symlink
    if ln -s "$CORTEX_TEST_SCRIPT" "$target_path"; then
        echo "   ✅ Symlink created successfully"
        return 0
    else
        echo "   ❌ Failed to create symlink"
        return 1
    fi
}

# Try installing to ~/.local/bin first (no sudo needed)
echo ""
echo "🔧 Installing cortex-test command..."

if install_symlink "$HOME_BIN"; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "📋 Add to your shell PATH if not already present:"
    echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    echo "   source ~/.zshrc"
    echo ""
    echo "🚀 Usage examples:"
    echo "   cortex-test status"
    echo "   cortex-test python unit"
    echo "   cortex-test unified"
    echo "   cortex-test smoke"
    echo ""
    
    # Check if PATH includes ~/.local/bin
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        echo "✅ PATH already includes ~/.local/bin"
        echo "🎉 cortex-test command is ready to use!"
    else
        echo "⚠️  ~/.local/bin is not in your PATH"
        echo "   Run: export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo "   Or add it permanently to ~/.zshrc"
    fi
    
elif install_symlink "$LOCAL_BIN"; then
    echo ""
    echo "✅ Installation successful to system directory!"
    echo "🎉 cortex-test command is ready to use!"
else
    echo ""
    echo "❌ Installation failed!"
    echo ""
    echo "📋 Manual installation:"
    echo "   sudo ln -s '$CORTEX_TEST_SCRIPT' /usr/local/bin/cortex-test"
    echo "   Or add an alias to ~/.zshrc:"
    echo "   echo 'alias cortex-test=\"$CORTEX_TEST_SCRIPT\"' >> ~/.zshrc"
    exit 1
fi

echo ""
echo "🧪 Test the installation:"
echo "   cortex-test --help"
