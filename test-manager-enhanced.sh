#!/bin/bash
# Enhanced Cortex Test Framework Manager with Link Validation
# Integrates bash framework with Python test suite and comprehensive link validation

FRAMEWORK_PATH="/Users/simonjanke/Projects/cortex-test-framework"
CORTEX_PATH="/Users/simonjanke/Projects/cortex"
CORTEX_TESTS_PATH="/Users/simonjanke/Projects/cortex/00-System/Tests"
TEST_PROJECTS_PATH="$FRAMEWORK_PATH/test-projects"
TEST_RESULTS_PATH="$FRAMEWORK_PATH/test-results"
TEST_BRIDGE="$FRAMEWORK_PATH/cortex_test_bridge.py"

# Link validation variables
TOTAL_FILES=0
TOTAL_LINKS=0
VALID_LINKS=0
BROKEN_LINKS=0
ORPHANED_FILES=0
TEMPLATE_ISSUES=0
VALIDATION_ERRORS=()

function show_help() {
    echo "Enhanced Cortex Test Framework Manager"
    echo ""
    echo "Usage: $0 {create|run|teardown|report|status|list|python|python-status|unified|install-deps|link-validation|link-health|view-broken-links}"
    echo ""
    echo "Framework Commands:"
    echo "  create <project-name> <template-type>  - Create new test project"
    echo "  run <test-scenario> [project-name]      - Run test scenarios"
    echo "  teardown <project-name>                 - Clean up test project"
    echo "  report <project-name>                   - Generate test report"
    echo "  status                                   - Show framework status"
    echo "  list                                     - List active test projects"
    echo ""
    echo "Python Integration Commands:"
    echo "  python <test-type>                      - Run Cortex Python tests"
    echo "      Test types: unit, integration, performance, all, smoke, install"
    echo "  python-status                           - Show Python test system status"
    echo "  unified                                 - Run both Python + Framework tests"
    echo "  install-deps                            - Install Python test dependencies"
    echo ""
    echo "Link Validation Commands:"
    echo "  link-validation                         - Comprehensive link validation"
    echo "  link-health                            - Quick link health check"
    echo "  view-broken-links [latest|all]         - View saved broken links reports"
    echo ""
    echo "Examples:"
    echo "  $0 python unit                         # Run Python unit tests"
    echo "  $0 unified                             # Run all tests (Python + Framework + Links)"
    echo "  $0 link-health                         # Quick link validation"
    echo "  $0 link-validation --verbose           # Detailed link validation"
}

function check_python_bridge() {
    if [ ! -f "$TEST_BRIDGE" ]; then
        echo "Python test bridge not found: $TEST_BRIDGE"
        return 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo "Python3 not found"
        return 1
    fi
    
    return 0
}

function reset_link_validation_counters() {
    TOTAL_FILES=0
    TOTAL_LINKS=0
    VALID_LINKS=0
    BROKEN_LINKS=0
    ORPHANED_FILES=0
    TEMPLATE_ISSUES=0
    VALIDATION_ERRORS=()
}

# Template detection and exclusion functions
function is_template_placeholder() {
    local link="$1"
    
    # Check for template placeholder patterns
    if [[ $link =~ \{\{.*\}\} ]]; then
        return 0  # Is template placeholder
    fi
    
    # Check for example/placeholder patterns
    if [[ $link =~ ^(ADR-XXX|ADR-YYY|Pattern-Name)$ ]]; then
        return 0  # Is example placeholder
    fi
    
    # Check for template-specific placeholders
    if [[ $link =~ ^(SIMILAR_ADR_[0-9]+|RELATED_PROJECT_[0-9]+|REUSABLE_.*_[0-9]+)$ ]]; then
        return 0  # Is template placeholder
    fi
    
    return 1  # Not a template placeholder
}

function is_template_file() {
    local file_path="$1"
    
    # Check if file is in templates directory
    if [[ $file_path =~ /00-Templates/ ]]; then
        return 0  # Is template file
    fi
    
    # Check for auto-generated files that should be excluded
    if [[ $file_path =~ Gap-Fill-examples.*_[0-9]{8}-[0-9]{6}\.md$ ]]; then
        return 0  # Is auto-generated gap fill example
    fi
    
    return 1  # Not a template file
}

function should_exclude_link() {
    local link="$1"
    local file_path="$2"
    
    # Always exclude template placeholders
    if is_template_placeholder "$link"; then
        return 0  # Exclude
    fi
    
    # Exclude links within template files that are examples
    if is_template_file "$file_path" && is_template_placeholder "$link"; then
        return 0  # Exclude
    fi
    
    return 1  # Don't exclude
}

# Progress bar functions
function show_progress() {
    local current=$1
    local total=$2
    local task_name="${3:-Processing}"
    local width=50
    
    if [ $total -eq 0 ]; then
        printf "\r%s: [%s] %d/%d" "$task_name" "$(printf "%*s" $width "")" $current $total
        return
    fi
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r%s: [%s%s] %d/%d (%d%%)" \
        "$task_name" \
        "$(printf "%*s" $filled "" | tr ' ' '█')" \
        "$(printf "%*s" $empty "")" \
        $current $total $percentage
        
    if [ $current -eq $total ]; then
        echo ""
    fi
}

function count_files() {
    local path="$1"
    local pattern="$2"
    find "$path" -name "$pattern" -type f 2>/dev/null | wc -l
}

# Function to save broken links to structured file
function save_broken_links_report() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local broken_links_file="$TEST_RESULTS_PATH/broken_links_$timestamp.json"
    local broken_links_md="$TEST_RESULTS_PATH/broken_links_$timestamp.md"
    
    echo "Saving broken links report to:"
    echo "  JSON: $broken_links_file"
    echo "  Markdown: $broken_links_md"
    
    # Create JSON report
    echo "{" > "$broken_links_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$broken_links_file"
    echo "  \"total_files_scanned\": $TOTAL_FILES," >> "$broken_links_file"
    echo "  \"total_links\": $TOTAL_LINKS," >> "$broken_links_file"
    echo "  \"valid_links\": $VALID_LINKS," >> "$broken_links_file"
    echo "  \"broken_links_count\": $BROKEN_LINKS," >> "$broken_links_file"
    echo "  \"health_score\": \"$(calculate_health_score)%\"," >> "$broken_links_file"
    echo "  \"broken_links\": [" >> "$broken_links_file"
    
    # Create Markdown report
    cat > "$broken_links_md" << EOF
# Broken Links Report

**Generated:** $(date)
**Files Scanned:** $TOTAL_FILES
**Total Links:** $TOTAL_LINKS
**Valid Links:** $VALID_LINKS
**Broken Links:** $BROKEN_LINKS
**Health Score:** $(calculate_health_score)%

## Broken Links Details

EOF

    local first=true
    for error in "${VALIDATION_ERRORS[@]}"; do
        # Parse error format: "TYPE: file:line - link"
        if [[ $error =~ ^([^:]+):[[:space:]](.+):([0-9]+)[[:space:]]-[[:space:]](.+)$ ]]; then
            local error_type="${BASH_REMATCH[1]}"
            local file_path="${BASH_REMATCH[2]}"
            local line_number="${BASH_REMATCH[3]}"  
            local link_text="${BASH_REMATCH[4]}"
            
            # Add to JSON
            if [ "$first" = false ]; then
                echo "    ," >> "$broken_links_file"
            fi
            echo "    {" >> "$broken_links_file"
            echo "      \"type\": \"$error_type\"," >> "$broken_links_file"
            echo "      \"file\": \"$file_path\"," >> "$broken_links_file"
            echo "      \"line\": $line_number," >> "$broken_links_file"
            echo "      \"link\": \"$(echo "$link_text" | sed 's/"/\\"/g')\"" >> "$broken_links_file"
            echo "    }" >> "$broken_links_file"
            
            # Add to Markdown
            echo "### $error_type" >> "$broken_links_md"
            echo "- **File:** \`$file_path\`" >> "$broken_links_md"
            echo "- **Line:** $line_number" >> "$broken_links_md"
            echo "- **Link:** \`$link_text\`" >> "$broken_links_md"
            echo "" >> "$broken_links_md"
            
            first=false
        fi
    done
    
    # Close JSON
    echo "  ]" >> "$broken_links_file"
    echo "}" >> "$broken_links_file"
    
    # Add summary to Markdown
    cat >> "$broken_links_md" << EOF

## Quick Fix Commands

To review these files quickly, you can use:

\`\`\`bash
# Open files with broken links
$(for error in "${VALIDATION_ERRORS[@]}"; do
    if [[ $error =~ ^[^:]+:[[:space:]](.+):([0-9]+) ]]; then
        echo "code \"${BASH_REMATCH[1]}:${BASH_REMATCH[2]}\""
    fi
done | sort -u)
\`\`\`

## Statistics

- **Files with broken links:** $(echo "${VALIDATION_ERRORS[@]}" | tr ' ' '\n' | grep -o '[^:]*:[0-9]*' | cut -d: -f1 | sort -u | wc -l | xargs)
- **Most problematic files:**

$(for error in "${VALIDATION_ERRORS[@]}"; do
    if [[ $error =~ ^[^:]+:[[:space:]](.+):([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
done | sort | uniq -c | sort -nr | head -5 | while read count file; do
    echo "  - \`$file\`: $count broken links"
done)

EOF

    echo ""
    echo "Broken links reports saved successfully!"
    return 0
}

# Function to view saved broken links reports
function view_broken_links() {
    local option="${1:-latest}"
    
    if [ ! -d "$TEST_RESULTS_PATH" ]; then
        echo "No test results directory found: $TEST_RESULTS_PATH"
        return 1
    fi
    
    # Find broken links files
    local json_files=($(find "$TEST_RESULTS_PATH" -name "broken_links_*.json" -type f | sort -r))
    local md_files=($(find "$TEST_RESULTS_PATH" -name "broken_links_*.md" -type f | sort -r))
    
    if [ ${#json_files[@]} -eq 0 ]; then
        echo "No broken links reports found in $TEST_RESULTS_PATH"
        echo "Run 'link-validation' first to generate reports."
        return 1
    fi
    
    case "$option" in
        "latest")
            echo "=== Latest Broken Links Report ==="
            echo "JSON: ${json_files[0]}"
            echo "Markdown: ${md_files[0]}"
            echo ""
            
            if command -v jq >/dev/null 2>&1; then
                echo "Summary (from JSON):"
                jq -r '
                    "Generated: " + .timestamp + 
                    "\nFiles scanned: " + (.total_files_scanned|tostring) + 
                    "\nTotal links: " + (.total_links|tostring) +
                    "\nBroken links: " + (.broken_links_count|tostring) +
                    "\nHealth score: " + .health_score +
                    "\n\nBroken Links:\n" +
                    (.broken_links[] | "- " + .file + ":" + (.line|tostring) + " - " + .link)
                ' "${json_files[0]}"
            else
                echo "Viewing Markdown report (install 'jq' for JSON parsing):"
                echo ""
                if command -v bat >/dev/null 2>&1; then
                    bat "${md_files[0]}"
                elif command -v less >/dev/null 2>&1; then
                    less "${md_files[0]}"
                else
                    cat "${md_files[0]}"
                fi
            fi
            ;;
            
        "all")
            echo "=== All Broken Links Reports ==="
            echo "Found ${#json_files[@]} reports:"
            echo ""
            
            for i in "${!json_files[@]}"; do
                local file="${json_files[$i]}"
                local basename=$(basename "$file" .json)
                local timestamp=$(echo "$basename" | sed 's/broken_links_//')
                local readable_date=$(date -j -f "%Y%m%d_%H%M%S" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
                
                echo "[$((i+1))] $readable_date"
                echo "    JSON: $file"
                echo "    MD:   ${md_files[$i]}"
                
                if command -v jq >/dev/null 2>&1; then
                    local summary=$(jq -r '.broken_links_count|tostring' "$file" 2>/dev/null)
                    echo "    Broken links: ${summary:-unknown}"
                fi
                echo ""
            done
            
            echo "Use 'view-broken-links latest' to see the most recent report in detail."
            ;;
            
        *)
            echo "Invalid option: $option"
            echo "Usage: view-broken-links [latest|all]"
            return 1
            ;;
    esac
}

function find_target_file() {
    local target="$1"
    local search_path="${2:-$CORTEX_PATH}"
    
    # Try direct filename match
    if [ -f "$search_path/$target" ]; then
        return 0
    fi
    
    # Try with .md extension
    if [ -f "$search_path/$target.md" ]; then
        return 0
    fi
    
    # Search in all subdirectories
    if find "$search_path" -name "$target" -type f -not -path "*/.git/*" -not -path "*/.obsidian/*" 2>/dev/null | grep -q .; then
        return 0
    fi
    
    if find "$search_path" -name "$target.md" -type f -not -path "*/.git/*" -not -path "*/.obsidian/*" 2>/dev/null | grep -q .; then
        return 0
    fi
    
    return 1
}

function validate_wikilinks() {
    echo "  Validating wikilinks [[target]]..."
    local broken_count=0
    local valid_count=0
    local file_count=0
    
    # Count total files for progress tracking
    local total_files=$(count_files "$CORTEX_PATH" "*.md")
    echo "    Found $total_files markdown files to scan..."
    
    while IFS= read -r -d '' file; do
        if [[ $file == */.git/* ]] || [[ $file == */.obsidian/* ]] || [[ $file == */__pycache__/* ]]; then
            continue
        fi
        
        ((TOTAL_FILES++))
        ((file_count++))
        show_progress $file_count $total_files "Scanning wikilinks"
        
        # Extract wikilinks and validate them
        while IFS=: read -r line_num line_content; do
            # Extract all wikilinks from the line
            while [[ $line_content =~ \[\[([^\]]+)\]\] ]]; do
                local target="${BASH_REMATCH[1]}"
                
                # Clean target (remove aliases and anchors)
                local clean_target=$(echo "$target" | sed 's/|.*$//' | sed 's/#.*$//' | xargs)
                
                # Skip template placeholders
                if should_exclude_link "$clean_target" "$file"; then
                    if [ "$1" = "--verbose" ]; then
                        echo "    TEMPLATE: $file:$line_num - [[$target]] (excluded)"
                    fi
                    # Remove the matched part to find additional links on the same line
                    line_content="${line_content#*]]}"
                    continue
                fi
                
                ((TOTAL_LINKS++))
                
                if find_target_file "$clean_target"; then
                    ((VALID_LINKS++))
                    ((valid_count++))
                else
                    ((BROKEN_LINKS++))
                    ((broken_count++))
                    local error_msg="BROKEN WIKILINK: $file:$line_num - [[$target]]"
                    VALIDATION_ERRORS+=("$error_msg")
                    
                    if [ "$1" = "--verbose" ]; then
                        echo "    BROKEN: $file:$line_num - [[$target]]"
                    fi
                fi
                
                # Remove the matched part to find additional links on the same line
                line_content="${line_content#*]]}"
            done
        done < <(grep -n '\[\[.*\]\]' "$file" 2>/dev/null || true)
        
    done < <(find "$CORTEX_PATH" -name "*.md" -type f -print0 2>/dev/null)
    
    echo "    Valid: $valid_count"
    echo "    Broken: $broken_count"
}

function validate_markdown_links() {
    echo "  Validating markdown links [text](target)..."
    local broken_count=0
    local valid_count=0
    local file_count=0
    
    # Count total files for progress tracking
    local total_files=$(count_files "$CORTEX_PATH" "*.md")
    echo "    Found $total_files markdown files to scan..."
    
    while IFS= read -r -d '' file; do
        if [[ $file == */.git/* ]] || [[ $file == */.obsidian/* ]] || [[ $file == */__pycache__/* ]]; then
            continue
        fi
        
        ((file_count++))
        show_progress $file_count $total_files "Scanning files"
        
        while IFS=: read -r line_num line_content; do
            # Extract markdown links
            local md_link_regex='\[([^]]*)\]\(([^)]+)\)'
            while [[ $line_content =~ $md_link_regex ]]; do
                local link_text="${BASH_REMATCH[1]}"
                local target="${BASH_REMATCH[2]}"
                
                # Skip template placeholders
                if should_exclude_link "$target" "$file"; then
                    if [ "$1" = "--verbose" ]; then
                        echo "    TEMPLATE: $file:$line_num - [$link_text]($target) (excluded)"
                    fi
                    # Remove the matched part
                    line_content="${line_content#*)]}"
                    continue
                fi
                
                ((TOTAL_LINKS++))
                
                # Skip external URLs
                if [[ $target =~ ^https?:// ]] || [[ $target =~ ^mailto: ]] || [[ $target =~ ^ftp:// ]]; then
                    ((VALID_LINKS++))
                    ((valid_count++))
                else
                    # Handle relative paths
                    local target_path
                    if [[ $target =~ ^\. ]]; then
                        target_path="$(dirname "$file")/$target"
                    else
                        target_path="$CORTEX_PATH/$target"
                    fi
                    
                    if [ -f "$target_path" ] || find_target_file "$target"; then
                        ((VALID_LINKS++))
                        ((valid_count++))
                    else
                        ((BROKEN_LINKS++))
                        ((broken_count++))
                        local error_msg="BROKEN MARKDOWN LINK: $file:$line_num - [$link_text]($target)"
                        VALIDATION_ERRORS+=("$error_msg")
                        
                        if [ "$1" = "--verbose" ]; then
                            echo "    BROKEN: $file:$line_num - [$link_text]($target)"
                        fi
                    fi
                fi
                
                # Remove the matched part
                line_content="${line_content#*)]}"
            done
        done < <(grep -n '\[.*\](.*' "$file" 2>/dev/null || true)
        
    done < <(find "$CORTEX_PATH" -name "*.md" -type f -print0 2>/dev/null)
    
    echo "    Valid: $valid_count"
    echo "    Broken: $broken_count"
}

function validate_template_structure() {
    echo "  Validating template structure..."
    local template_dir="$CORTEX_PATH/00-Templates"
    local issues=0
    
    if [ ! -d "$template_dir" ]; then
        ((TEMPLATE_ISSUES++))
        ((issues++))
        VALIDATION_ERRORS+=("MISSING DIRECTORY: Templates directory not found at $template_dir")
        echo "    Templates directory missing"
        return
    fi
    
    # Check for expected templates
    local expected_templates=("ADR-Enhanced.md" "Project-Workspace.md")
    
    for template in "${expected_templates[@]}"; do
        local template_path="$template_dir/$template"
        
        if [ -f "$template_path" ]; then
            # Check ADR template structure
            if [ "$template" = "ADR-Enhanced.md" ]; then
                local required_sections=("Context & Problem Statement" "Considered Options" "Decision" "Consequences")
                local missing_sections=()
                
                for section in "${required_sections[@]}"; do
                    if ! grep -q "$section" "$template_path"; then
                        missing_sections+=("$section")
                    fi
                done
                
                if [ ${#missing_sections[@]} -gt 0 ]; then
                    ((TEMPLATE_ISSUES++))
                    ((issues++))
                    local missing_list=$(IFS=", "; echo "${missing_sections[*]}")
                    VALIDATION_ERRORS+=("TEMPLATE STRUCTURE: $template missing sections: $missing_list")
                    
                    if [ "$1" = "--verbose" ]; then
                        echo "    $template missing sections: $missing_list"
                    fi
                else
                    echo "    $template structure valid"
                fi
            else
                echo "    $template found"
            fi
        else
            ((TEMPLATE_ISSUES++))
            ((issues++))
            VALIDATION_ERRORS+=("MISSING TEMPLATE: Expected template not found: $template")
            
            if [ "$1" = "--verbose" ]; then
                echo "    Missing template: $template"
            fi
        fi
    done
    
    echo "    Template issues: $issues"
}

function check_orphaned_files() {
    echo "  Checking for orphaned files..."
    local orphaned_count=0
    local file_count=0
    
    # Count total files for progress tracking
    local total_files=$(count_files "$CORTEX_PATH" "*.md")
    echo "    Analyzing references in $total_files files..."
    
    # Create temporary file with all referenced files
    local temp_refs="/tmp/cortex_refs_$$"
    
    # Extract all referenced files from wikilinks and markdown links
    find "$CORTEX_PATH" -name "*.md" -type f -not -path "*/.git/*" -not -path "*/.obsidian/*" 2>/dev/null | while read -r file; do
        ((file_count++))
        show_progress $file_count $total_files "Analyzing refs"
        # Extract wikilink targets
        grep -o '\[\[.*\]\]' "$file" 2>/dev/null | sed 's/\[\[\(.*\)\]\]/\1/' | sed 's/|.*$//' | sed 's/#.*$//' >> "$temp_refs" 2>/dev/null || true
        
        # Extract markdown link targets (local files only)
        grep -o '\[.*\](.*' "$file" 2>/dev/null | sed 's/.*](\(.*\))/\1/' | grep -v '^http' | grep -v '^mailto' >> "$temp_refs" 2>/dev/null || true
    done
    
    # Check each markdown file to see if it's referenced
    while IFS= read -r -d '' file; do
        if [[ $file == */.git/* ]] || [[ $file == */.obsidian/* ]] || [[ $file == */__pycache__/* ]]; then
            continue
        fi
        
        local filename=$(basename "$file")
        local filename_noext=$(basename "$file" .md)
        
        # Skip certain special files
        if [[ $filename =~ ^(README|readme|index|Index|Cortex-Hub|Hub)\.md$ ]]; then
            continue
        fi
        
        # Skip archived files
        if [[ $file == */99-Archive/* ]]; then
            continue
        fi
        
        # Check if file is referenced
        if [ -f "$temp_refs" ]; then
            if ! grep -q "$filename\|$filename_noext" "$temp_refs" 2>/dev/null; then
                ((ORPHANED_FILES++))
                ((orphaned_count++))
                VALIDATION_ERRORS+=("ORPHANED FILE: $file")
                
                if [ "$1" = "--verbose" ]; then
                    echo "    Orphaned: $filename"
                fi
            fi
        fi
        
    done < <(find "$CORTEX_PATH" -name "*.md" -type f -print0 2>/dev/null)
    
    # Cleanup
    rm -f "$temp_refs" 2>/dev/null
    
    echo "    Orphaned files: $orphaned_count"
}

function calculate_health_score() {
    local total_issues=$((BROKEN_LINKS + ORPHANED_FILES + TEMPLATE_ISSUES))
    local total_items=$((TOTAL_LINKS + TOTAL_FILES))
    
    if [ $total_items -eq 0 ]; then
        echo "0"
        return
    fi
    
    local health_score=$(echo "scale=1; 100 - ($total_issues * 100 / $total_items)" | bc 2>/dev/null || echo "0")
    
    # Ensure score is not negative
    if (( $(echo "$health_score < 0" | bc -l 2>/dev/null) )); then
        health_score="0"
    fi
    
    echo "$health_score"
}

function run_link_validation() {
    local verbose=""
    if [ "$1" = "--verbose" ] || [ "$2" = "--verbose" ]; then
        verbose="--verbose"
    fi
    
    echo "Starting Cortex Link Validation"
    echo "================================"
    
    reset_link_validation_counters
    
    if [ ! -d "$CORTEX_PATH" ]; then
        echo "Cortex directory not found: $CORTEX_PATH"
        return 1
    fi
    
    echo ""
    echo "Scanning Cortex system..."
    echo ""
    
    # Run all validation checks with progress feedback
    echo "Phase 1/4: WikiLink Validation"
    validate_wikilinks $verbose
    echo ""
    
    echo "Phase 2/4: Markdown Link Validation" 
    validate_markdown_links $verbose
    echo ""
    
    echo "Phase 3/4: Template Structure Validation"
    validate_template_structure $verbose
    echo ""
    
    echo "Phase 4/4: Orphaned File Detection"
    check_orphaned_files $verbose
    echo ""
    
    # Calculate and display results
    echo ""
    echo "VALIDATION SUMMARY"
    echo "=================="
    echo "Files scanned: $TOTAL_FILES"
    echo "Total links found: $TOTAL_LINKS"
    echo "Valid links: $VALID_LINKS"
    echo "Broken links: $BROKEN_LINKS"
    echo "Orphaned files: $ORPHANED_FILES"
    echo "Template issues: $TEMPLATE_ISSUES"
    
    # Calculate health score
    local health_score=$(calculate_health_score)
    echo ""
    echo "System Health Score: ${health_score}%"
    
    # Health assessment
    if (( $(echo "$health_score >= 95" | bc -l 2>/dev/null) )); then
        echo "Excellent! Your Cortex system is very healthy."
    elif (( $(echo "$health_score >= 85" | bc -l 2>/dev/null) )); then
        echo "Good! Minor issues to address."
    elif (( $(echo "$health_score >= 70" | bc -l 2>/dev/null) )); then
        echo "Fair. Several issues need attention."
    else
        echo "Poor. Significant issues require immediate attention."
    fi
    
    # Show errors if any and not in quiet mode
    local total_errors=${#VALIDATION_ERRORS[@]}
    if [ $total_errors -gt 0 ]; then
        echo ""
        echo "ISSUES FOUND ($total_errors total):"
        
        if [ "$verbose" = "--verbose" ]; then
            for error in "${VALIDATION_ERRORS[@]}"; do
                echo "  $error"
            done
        else
            echo "  Run with --verbose to see detailed error list"
            echo "  First 3 issues:"
            for i in {0..2}; do
                if [ $i -lt $total_errors ]; then
                    echo "  ${VALIDATION_ERRORS[$i]}"
                fi
            done
        fi
        
        # Save broken links to structured files
        echo ""
        save_broken_links_report
    fi
    
    # Generate report
    generate_link_report
    
    # Return appropriate exit code
    if [ $total_errors -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function run_link_health_check() {
    echo "Quick Link Health Check"
    echo "======================="
    
    reset_link_validation_counters
    
    # Quick validation (no verbose output)
    validate_wikilinks
    validate_template_structure
    
    local health_score=$(calculate_health_score)
    local total_issues=$((BROKEN_LINKS + TEMPLATE_ISSUES))
    
    echo ""
    echo "Health Score: ${health_score}%"
    echo "Links checked: $TOTAL_LINKS"
    echo "Issues found: $total_issues"
    
    if [ $total_issues -eq 0 ]; then
        echo "System is healthy!"
        return 0
    else
        echo "Issues detected. Run 'cortex-test link-validation' for details."
        
        # Save broken links for later processing
        if [ ${#VALIDATION_ERRORS[@]} -gt 0 ]; then
            echo ""
            save_broken_links_report
        fi
        
        return 1
    fi
}

function generate_link_report() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="$TEST_RESULTS_PATH/link_validation_$timestamp.md"
    
    mkdir -p "$TEST_RESULTS_PATH"
    
    cat > "$report_file" << EOF
# Cortex Link Validation Report

**Generated**: $(date -Iseconds)  
**Cortex Path**: $CORTEX_PATH  

## Summary

- **Files scanned**: $TOTAL_FILES
- **Total links found**: $TOTAL_LINKS  
- **Valid links**: $VALID_LINKS
- **Broken links**: $BROKEN_LINKS
- **Orphaned files**: $ORPHANED_FILES
- **Template issues**: $TEMPLATE_ISSUES
- **Health Score**: $(calculate_health_score)%

EOF

    if [ ${#VALIDATION_ERRORS[@]} -gt 0 ]; then
        cat >> "$report_file" << EOF

## Issues Found

EOF
        for error in "${VALIDATION_ERRORS[@]}"; do
            echo "- $error" >> "$report_file"
        done
    fi
    
    echo ""
    echo "Detailed report saved: $report_file"
}

function run_python_tests() {
    local test_type="$1"
    
    if [ -z "$test_type" ]; then
        echo "Error: Test type required"
        echo "Usage: $0 python <test-type>"
        return 1
    fi
    
    echo "Running Python test suite: $test_type"
    
    if ! check_python_bridge; then
        return 1
    fi
    
    if python3 "$TEST_BRIDGE" python "$test_type"; then
        echo "Python tests ($test_type) completed successfully"
        return 0
    else
        echo "Python tests ($test_type) failed"
        return 1
    fi
}

function show_python_status() {
    echo "Python Test System Status"
    echo ""
    
    if ! check_python_bridge; then
        echo "Python test bridge not available"
        return 1
    fi
    
    python3 "$TEST_BRIDGE" status
}

function install_python_dependencies() {
    echo "Installing Python test dependencies..."
    
    if ! check_python_bridge; then
        return 1
    fi
    
    if python3 "$TEST_BRIDGE" python install; then
        echo "Python test dependencies installed"
        return 0
    else
        echo "Failed to install Python test dependencies"
        return 1
    fi
}

function run_unified_tests() {
    echo "Running Enhanced Unified Test Suite (Python + Framework + Links)"
    echo "================================================================"
    
    local overall_success=true
    
    # Run Python tests if available
    if check_python_bridge > /dev/null 2>&1; then
        echo ""
        echo "PYTHON TEST PHASE"
        echo "-----------------"
        
        for test_type in "unit" "integration" "performance"; do
            echo ""
            echo "Running Python $test_type tests..."
            if python3 "$TEST_BRIDGE" python "$test_type"; then
                echo "Python $test_type tests: PASSED"
            else
                echo "Python $test_type tests: FAILED"
                overall_success=false
            fi
        done
    else
        echo "Python tests not available - running framework tests only"
    fi
    
    # Run framework template tests
    echo ""
    echo "FRAMEWORK TEST PHASE"
    echo "--------------------"
    
    echo ""
    echo "Running template validation tests..."
    if run_framework_template_tests; then
        echo "Framework template tests: PASSED"
    else
        echo "Framework template tests: FAILED"
        overall_success=false
    fi
    
    # Run link validation
    echo ""
    echo "LINK VALIDATION PHASE"
    echo "---------------------"
    
    echo ""
    echo "Running comprehensive link validation..."
    if run_link_validation; then
        echo "Link validation: PASSED"
    else
        echo "Link validation: FAILED"
        overall_success=false
    fi
    
    # Generate unified report
    echo ""
    echo "UNIFIED TEST RESULTS"
    echo "==================="
    
    if [ "$overall_success" = true ]; then
        echo "ALL TESTS PASSED!"
        echo "System is ready for production"
    else
        echo "SOME TESTS FAILED"
        echo "Review individual test results before proceeding"
    fi
    
    echo "Results available in: $TEST_RESULTS_PATH"
    
    return $([ "$overall_success" = true ] && echo 0 || echo 1)
}

function run_framework_template_tests() {
    local template_tests_passed=true
    
    echo "  Validating ADR template..."
    local adr_template="$FRAMEWORK_PATH/test-projects/adr-template-validation/templates/ADR-Enhanced.md"
    if [ -f "$adr_template" ]; then
        echo "    ADR template exists"
        
        if grep -q "Context & Problem Statement" "$adr_template" && \
           grep -q "Considered Options" "$adr_template" && \
           grep -q "Decision" "$adr_template"; then
            echo "    ADR template structure valid"
        else
            echo "    ADR template structure invalid"
            template_tests_passed=false
        fi
    else
        echo "    ADR template not found"
        template_tests_passed=false
    fi
    
    echo "  Validating framework structure..."
    local required_dirs=("setup-scripts" "teardown-scripts" "test-projects" "test-results")
    for dir in "${required_dirs[@]}"; do
        if [ -d "$FRAMEWORK_PATH/$dir" ]; then
            echo "    Directory $dir exists"
        else
            echo "    Directory $dir missing"
            template_tests_passed=false
        fi
    done
    
    return $([ "$template_tests_passed" = true ] && echo 0 || echo 1)
}

function show_status() {
    echo "Enhanced Cortex Test Framework Status (with Link Validation)"
    echo "==========================================================="
    echo ""
    echo "Framework Path: $FRAMEWORK_PATH"
    echo "Cortex Path: $CORTEX_PATH"
    echo "Python Tests Path: $CORTEX_TESTS_PATH"
    echo ""
    
    # Check Python test availability
    if check_python_bridge > /dev/null 2>&1; then
        echo "Python Test Integration: Available"
    else
        echo "Python Test Integration: Not Available"
    fi
    
    # Quick link health check
    echo "Link Validation: Integrated"
    echo ""
    echo "Quick Link Health Check:"
    reset_link_validation_counters
    validate_wikilinks > /dev/null 2>&1
    local health_score=$(calculate_health_score)
    echo "   Health Score: ${health_score}%"
    echo "   Links Checked: $TOTAL_LINKS"
    echo "   Issues Found: $((BROKEN_LINKS + TEMPLATE_ISSUES))"
    
    echo ""
    local active_projects=$(find "$TEST_PROJECTS_PATH" -maxdepth 1 -type d ! -path "$TEST_PROJECTS_PATH" 2>/dev/null | wc -l)
    echo "Active Test Projects: $active_projects"
    
    echo ""
    echo "Recent Test Results:"
    if [ -d "$TEST_RESULTS_PATH" ]; then
        local result_count=$(find "$TEST_RESULTS_PATH" -name "*.json" -o -name "*.html" -o -name "*.md" 2>/dev/null | wc -l)
        echo "  Result files: $result_count"
    else
        echo "  No test results directory found"
    fi
}

function list_projects() {
    echo "Active Test Projects:"
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
                echo "  Test Project: $project"
                echo "     Type: $template_type"
                echo "     Status: $status"
                echo "     Created: $created"
                echo ""
            fi
        fi
    done
}

function run_template_system_test() {
    echo "🧪 Running Template System Tests"
    echo "=============================="
    
    if [ -f "$FRAMEWORK_PATH/test-template-system.sh" ]; then
        bash "$FRAMEWORK_PATH/test-template-system.sh"
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "✅ Template system tests: PASSED"
            return 0
        else
            echo "❌ Template system tests: FAILED"
            return 1
        fi
    else
        echo "❌ Template system test script not found"
        return 1
    fi
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
    view-broken-links)
        view_broken_links "$2"
        ;;
    link-report)
        run_link_validation "$2"
        ;;
    template-test)
        run_template_system_test
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
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
