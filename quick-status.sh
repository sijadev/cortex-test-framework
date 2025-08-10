#!/bin/bash

# Simple Test Manager Demo
FRAMEWORK_PATH="/Users/simonjanke/Projects/cortex-test-framework"

echo "🧪 Cortex Test Framework - Quick Status"
echo "================================================"

echo "📁 Framework Path: $FRAMEWORK_PATH"
echo ""

echo "📋 Active Test Projects:"
if [ -d "$FRAMEWORK_PATH/test-projects" ]; then
    for project_dir in "$FRAMEWORK_PATH/test-projects"/*; do
        if [ -d "$project_dir" ]; then
            project_name=$(basename "$project_dir")
            echo "  🧪 $project_name"
            
            if [ -f "$project_dir/test-project.yaml" ]; then
                template_type=$(grep "template_type:" "$project_dir/test-project.yaml" | cut -d' ' -f2 | tr -d '\r\n')
                status=$(grep "status:" "$project_dir/test-project.yaml" | cut -d' ' -f2 | tr -d '\r\n')
                created=$(grep "created:" "$project_dir/test-project.yaml" | cut -d' ' -f2 | tr -d '\r\n')
                echo "     Type: $template_type"
                echo "     Status: $status"
                echo "     Created: $created"
                echo ""
            fi
        fi
    done
else
    echo "  No test projects directory found"
fi

echo "🔧 Available Setup Scripts:"
if [ -d "$FRAMEWORK_PATH/setup-scripts" ]; then
    ls -1 "$FRAMEWORK_PATH/setup-scripts" | while read script; do
        echo "  - $script"
    done
else
    echo "  No setup scripts found"
fi

echo ""
echo "🧹 Available Teardown Scripts:"
if [ -d "$FRAMEWORK_PATH/teardown-scripts" ]; then
    ls -1 "$FRAMEWORK_PATH/teardown-scripts" | while read script; do
        echo "  - $script"
    done
else
    echo "  No teardown scripts found"
fi

echo ""
echo "✅ Test Framework Status: Ready"
echo ""
echo "Next steps:"
echo "  1. Run existing ADR template validation test"
echo "  2. Create new test projects for other templates"
echo "  3. Generate test reports"
echo "  4. Link results back to Cortex"
