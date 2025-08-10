#!/bin/bash
# Enhanced Cortex Test Framework Manager
# Integrates bash framework with Python test suite from 00-System/Tests

FRAMEWORK_PATH="/Users/simonjanke/Projects/cortex-test-framework"
CORTEX_PATH="/Users/simonjanke/Projects/cortex"
CORTEX_TESTS_PATH="/Users/simonjanke/Projects/cortex/00-System/Tests"
TEST_PROJECTS_PATH="$FRAMEWORK_PATH/test-projects"
TEST_RESULTS_PATH="$FRAMEWORK_PATH/test-results"
TEST_BRIDGE="$FRAMEWORK_PATH/cortex_test_bridge.py"

function show_help() {
    echo "🧪 Enhanced Cortex Test Framework Manager"
    echo ""
    echo "Usage: $0 {create|run|teardown|report|status|list|python|python-status|unified|install-deps}"
    echo ""
    echo "📋 Framework Commands:"
    echo "  create <project-name> <template-type>  - Create new test project"
    echo "  run <test-scenario> [project-name]      - Run test scenarios"
    echo "  teardown <project-name>                 - Clean up test project"
    echo "  report <project-name>                   - Generate test report"
    echo "  status                                   - Show framework status"
    echo "  list                                     - List active test projects"
    echo ""
    echo "🐍 Python Integration Commands:"
    echo "  python <test-type>                      - Run Cortex Python tests"
    echo "      Test types: unit, integration, performance, all, smoke, install"
    echo "  python-status                           - Show Python test system status"
    echo "  unified                                 - Run both Python + Framework tests"
    echo "  install-deps                            - Install Python test dependencies"
    echo ""
    echo "Examples:"
    echo "  $0 python unit                         # Run Python unit tests"
    echo "  $0 unified                             # Run all tests (Python + Framework)"
    echo "  $0 python-status                       # Check Python test availability"
    echo ""
    echo "🔗 Framework automatically integrates with Cortex Python test suite"
}

function check_python_bridge() {
    if [ ! -f "$TEST_BRIDGE" ]; then
        echo "❌ Python test bridge not found: $TEST_BRIDGE"
        return 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python3 not found"
        return 1
    fi
    
    return 0
}

function run_python_tests() {
    local test_type="$1"
    
    if [ -z "$test_type" ]; then
        echo "❌ Error: Test type required"
        echo "Usage: $0 python <test-type>"
        echo "Test types: unit, integration, performance, all, smoke, install"
        return 1
    fi
    
    echo "🐍 Running Python test suite: $test_type"
    
    if ! check_python_bridge; then
        return 1
    fi
    
    if python3 "$TEST_BRIDGE" python "$test_type"; then
        echo "✅ Python tests ($test_type) completed successfully"
        return 0
    else
        echo "❌ Python tests ($test_type) failed"
        return 1
    fi
}

function show_python_status() {
    echo "🐍 Python Test System Status"
    echo ""
    
    if ! check_python_bridge; then
        echo "❌ Python test bridge not available"
        return 1
    fi
    
    python3 "$TEST_BRIDGE" status
}

function install_python_dependencies() {
    echo "🔧 Installing Python test dependencies..."
    
    if ! check_python_bridge; then
        return 1
    fi
    
    if python3 "$TEST_BRIDGE" python install; then
        echo "✅ Python test dependencies installed"
        return 0
    else
        echo "❌ Failed to install Python test dependencies"
        return 1
    fi
}

function run_unified_tests() {
    echo "🚀 Running Unified Test Suite (Python + Framework)"
    echo "=================================================="
    
    local overall_success=true
    
    # Run Python tests if available
    if check_python_bridge > /dev/null 2>&1; then
        echo ""
        echo "🐍 PYTHON TEST PHASE"
        echo "--------------------"
        
        for test_type in "unit" "integration" "performance"; do
            echo ""
            echo "📋 Running Python $test_type tests..."
            if python3 "$TEST_BRIDGE" python "$test_type"; then
                echo "✅ Python $test_type tests: PASSED"
            else
                echo "❌ Python $test_type tests: FAILED"
                overall_success=false
            fi
        done
    else
        echo "⚠️  Python tests not available - running framework tests only"
    fi
    
    # Run framework template tests
    echo ""
    echo "📋 FRAMEWORK TEST PHASE"
    echo "----------------------"
    
    echo ""
    echo "📋 Running template validation tests..."
    if run_framework_template_tests; then
        echo "✅ Framework template tests: PASSED"
    else
        echo "❌ Framework template tests: FAILED"
        overall_success=false
    fi
    
    # Generate unified report
    echo ""
    echo "📊 UNIFIED TEST RESULTS"
    echo "======================="
    
    if [ "$overall_success" = true ]; then
        echo "🎉 ALL TESTS PASSED!"
        echo "✅ System is ready for production"
    else
        echo "❌ SOME TESTS FAILED"
        echo "⚠️  Review individual test results before proceeding"
    fi
    
    echo "📁 Results available in: $TEST_RESULTS_PATH"
    
    return $([ "$overall_success" = true ] && echo 0 || echo 1)
}

function run_framework_template_tests() {
    local template_tests_passed=true
    
    echo "  📋 Validating ADR template..."
    local adr_template="$FRAMEWORK_PATH/test-projects/adr-template-validation/templates/ADR-Enhanced.md"
    if [ -f "$adr_template" ]; then
        echo "    ✅ ADR template exists"
        
        if grep -q "Context & Problem Statement" "$adr_template" && \
           grep -q "Considered Options" "$adr_template" && \
           grep -q "Decision" "$adr_template"; then
            echo "    ✅ ADR template structure valid"
        else
            echo "    ❌ ADR template structure invalid"
            template_tests_passed=false
        fi
    else
        echo "    ❌ ADR template not found"
        template_tests_passed=false
    fi
    
    echo "  📋 Validating framework structure..."
    local required_dirs=("setup-scripts" "teardown-scripts" "test-projects" "test-results")
    for dir in "${required_dirs[@]}"; do
        if [ -d "$FRAMEWORK_PATH/$dir" ]; then
            echo "    ✅ Directory $dir exists"
        else
            echo "    ❌ Directory $dir missing"
            template_tests_passed=false
        fi
    done
    
    return $([ "$template_tests_passed" = true ] && echo 0 || echo 1)
}

function show_status() {
    echo "🧪 Enhanced Cortex Test Framework Status"
    echo "========================================="
    echo ""
    echo "📁 Framework Path: $FRAMEWORK_PATH"
    echo "🔗 Cortex Path: $CORTEX_PATH"
    echo "🐍 Python Tests Path: $CORTEX_TESTS_PATH"
    echo ""
    
    # Check Python test availability
    if check_python_bridge > /dev/null 2>&1; then
        echo "🐍 Python Test Integration: ✅ Available"
    else
        echo "🐍 Python Test Integration: ❌ Not Available"
    fi
    
    echo ""
    local active_projects=$(find "$TEST_PROJECTS_PATH" -maxdepth 1 -type d ! -path "$TEST_PROJECTS_PATH" 2>/dev/null | wc -l)
    echo "📋 Active Test Projects: $active_projects"
    
    if [ $active_projects -gt 0 ]; then
        echo ""
        echo "Active Projects:"
        for project_dir in "$TEST_PROJECTS_PATH"/*; do
            if [ -d "$project_dir" ]; then
                local project=$(basename "$project_dir")
                if [ -f "$project_dir/test-project.yaml" ]; then
                    local template_type=$(grep "template_type:" "$project_dir/test-project.yaml" | cut -d' ' -f2)
                    local created=$(grep "created:" "$project_dir/test-project.yaml" | cut -d' ' -f2)
                    echo "  - $project ($template_type) - Created: $created"
                fi
            fi
        done
    fi
    
    echo ""
    echo "📊 Recent Test Results:"
    if [ -d "$TEST_RESULTS_PATH" ]; then
        local result_count=$(find "$TEST_RESULTS_PATH" -name "*.json" -o -name "*.html" -o -name "*.md" 2>/dev/null | wc -l)
        echo "  Result files: $result_count"
        if [ $result_count -gt 0 ]; then
            echo "  Recent files:"
            find "$TEST_RESULTS_PATH" -name "*.json" -o -name "*.html" -o -name "*.md" 2>/dev/null | sort | tail -3 | while read file; do
                echo "    - $(basename "$file")"
            done
        fi
    else
        echo "  No test results directory found"
    fi
}

function list_projects() {
    echo "📋 Active Test Projects:"
    echo ""
    
    if [ ! -d "$TEST_PROJECTS_PATH" ] || [ -z "$(ls -A "$TEST_PROJECTS_PATH" 2>/dev/null)" ]; then
        echo "  No active test projects"
        return 0
    fi
    
    for project_dir in "$TEST_PROJECTS_PATH"/*; do
        if [ -d "$project_dir" ]; then
            local project=$(basename "$project_dir")
            if [ -f "$project_dir/test-project.yaml" ]; then
                local template_type=$(grep "template_type:" "$project_dir/test-project.yaml" | cut -d' ' -f2)
                local status=$(grep "status:" "$project_dir/test-project.yaml" | cut -d' ' -f2)
                local created=$(grep "created:" "$project_dir/test-project.yaml" | cut -d' ' -f2)
                echo "  🧪 $project"
                echo "     Type: $template_type"
                echo "     Status: $status"
                echo "     Created: $created"
                echo ""
            fi
        fi
    done
}

# Enhanced command dispatcher with link validation
case "$1" in
    python)
        run_python_tests "$2"
        ;;
    python-status)
        show_python_status
        ;;
    unified)
        run_unified_tests
        ;;
    install-deps)
        install_python_dependencies
        ;;
    link-validation)
        run_link_validation "$2"
        ;;
    link-health)
        run_link_health_check
        ;;
    link-report)
        run_link_validation "$2"
        ;;
    status)
        show_status
        ;;
    list)
        list_projects
        ;;
    "")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_help
        exit 1
        ;;
esac_dir/test-project.yaml" | cut -d' ' -f2)
                local created=$(grep "created:" "$project_dir/test-project.yaml" | cut -d' ' -f2)
                echo "  🧪 $project"
                echo "     Type: $template_type"
                echo "     Status: $status"
                echo "     Created: $created"
                echo ""
            fi
        fi
    done
}

# Enhanced command dispatcher
case "$1" in
    python)
        run_python_tests "$2"
        ;;
    python-status)
        show_python_status
        ;;
    unified)
        run_unified_tests
        ;;
    install-deps)
        install_python_dependencies
        ;;
    status)
        show_status
        ;;
    list)
        list_projects
        ;;
    "")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_help
        exit 1
        ;;
esac
