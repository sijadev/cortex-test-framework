#!/bin/zsh
# Quick Setup für cortex-test command

echo "🧪 Setting up cortex-test command for zsh..."

# Backup existing .zshrc
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created: ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Add cortex-test alias and shortcuts to .zshrc
cat >> ~/.zshrc << 'EOF'

# ======================================
# Cortex Test Framework Integration
# ======================================

# Main cortex-test command
alias cortex-test="/Users/simonjanke/Projects/cortex-test-framework/cortex-test"

# Quick shortcuts
alias ct="cortex-test"
alias ct-status="cortex-test status"
alias ct-smoke="cortex-test smoke"
alias ct-check="cortex-test check"
alias ct-unified="cortex-test unified"

# Python test shortcuts
alias ct-unit="cortex-test python unit"
alias ct-integration="cortex-test python integration"
alias ct-performance="cortex-test python performance"
alias ct-all="cortex-test python all"

echo "🧪 Cortex Test Framework loaded! Use: cortex-test --help"

EOF

echo ""
echo "✅ cortex-test command added to ~/.zshrc"
echo ""
echo "🔄 Now reload your shell configuration:"
echo "   source ~/.zshrc"
echo ""
echo "🧪 Test the installation:"
echo "   cortex-test --help"
echo "   ct-smoke"
echo "   ct-status"
