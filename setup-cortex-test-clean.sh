#!/bin/zsh
# Clean Setup für cortex-test command (Powerlevel10k kompatibel)

echo "🧪 Setting up cortex-test command for zsh (Powerlevel10k compatible)..."

# Backup existing .zshrc
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created: ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Remove any existing cortex-test configuration
echo "🧹 Cleaning up existing cortex-test configuration..."
sed -i.bak '/# Cortex Test Framework/,/# ======================================/d' ~/.zshrc 2>/dev/null || true
sed -i.bak '/cortex-test/d' ~/.zshrc 2>/dev/null || true

# Add clean source line to .zshrc (after instant prompt if present)
CORTEX_ALIASES="/Users/simonjanke/Projects/cortex-test-framework/cortex-test-aliases.zsh"

# Check if instant prompt exists in .zshrc
if grep -q "instant prompt" ~/.zshrc; then
    echo "📋 Adding cortex-test after instant prompt configuration..."
    # Add after the instant prompt section
    sed -i.bak '/# To customize prompt/a\
\
# Cortex Test Framework\
source "'$CORTEX_ALIASES'"
' ~/.zshrc
else
    echo "📋 Adding cortex-test to end of .zshrc..."
    # Add to end of file
    echo "" >> ~/.zshrc
    echo "# Cortex Test Framework" >> ~/.zshrc
    echo "source \"$CORTEX_ALIASES\"" >> ~/.zshrc
fi

echo ""
echo "✅ cortex-test command configured successfully!"
echo ""
echo "🔄 Reload your shell:"
echo "   source ~/.zshrc"
echo ""
echo "🧪 Test the installation:"
echo "   cortex-test --help"
echo "   ct-smoke"
echo ""
echo "💡 Available commands:"
echo "   cortex-test, ct, ct-status, ct-smoke, ct-check"
echo "   ct-unified, ct-unit, ct-integration, ct-performance, ct-all"
