# Cortex Test Framework - ZSH Integration
# Add this to your ~/.zshrc file

# Cortex Test Framework Alias
alias cortex-test="/Users/simonjanke/Projects/cortex-test-framework/cortex-test"

# Auto-completion for cortex-test command
_cortex_test_completion() {
    local commands=(
        "status:Show framework status"
        "list:List active test projects"
        "python:Run Python tests"
        "python-status:Show Python test system status"
        "unified:Run all tests (Python + Framework)"
        "install-deps:Install Python test dependencies"
        "smoke:Quick smoke test"
        "full:Full test suite"
        "check:Health check"
        "help:Show help"
    )
    
    local python_tests=(
        "unit:Run unit tests"
        "integration:Run integration tests"
        "performance:Run performance tests"
        "all:Run all Python tests"
        "install:Install dependencies"
    )
    
    if [[ $CURRENT == 2 ]]; then
        _describe 'commands' commands
    elif [[ $words[2] == "python" && $CURRENT == 3 ]]; then
        _describe 'python tests' python_tests
    fi
}

# Register completion function
compdef _cortex_test_completion cortex-test

# Cortex Test Framework shortcuts
alias ct="cortex-test"
alias ct-status="cortex-test status"
alias ct-smoke="cortex-test smoke"
alias ct-check="cortex-test check"
alias ct-python="cortex-test python"
alias ct-unified="cortex-test unified"

# Quick test aliases
alias ct-unit="cortex-test python unit"
alias ct-integration="cortex-test python integration"
alias ct-performance="cortex-test python performance"
alias ct-all="cortex-test python all"

echo "🧪 Cortex Test Framework aliases loaded:"
echo "   cortex-test, ct, ct-status, ct-smoke, ct-check"
echo "   ct-python, ct-unified, ct-unit, ct-integration"
echo "   ct-performance, ct-all"
