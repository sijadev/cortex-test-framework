#!/bin/bash

# Cortex Critical Path Validator
# Enhanced validation for critical system files with strict requirements

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.cortex-critical.yml"
TEST_SCRIPT="$SCRIPT_DIR/test-manager-enhanced.sh"

# Parse YAML configuration (simple parser for our needs)
get_config_value() {
    local key="$1"
    local default="$2"
    
    if [ -f "$CONFIG_FILE" ]; then
        # Simple YAML parsing - works for our flat structure
        grep "^[[:space:]]*${key}:" "$CONFIG_FILE" | sed 's/.*: *//' | head -1 || echo "$default"
    else
        echo "$default"
    fi
}

# Check if file matches critical patterns
is_critical_file() {
    local file_path="$1"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        # Fallback to hardcoded critical patterns
        case "$file_path" in
            *"System-Workflows"*|*"Confidence Calculator"*|*"Auth-System"*|*"Quality-Gates"*)
                return 0 ;;
            *"Cortex-Hub"*|*"Decision-Index"*|*"ADR-001"*|*"ADR-002"*|*"ADR-004"*)
                return 0 ;;
            *) return 1 ;;
        esac
    fi
    
    # Check against patterns from config file
    while IFS= read -r pattern; do
        # Skip comments and empty lines
        [[ "$pattern" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$pattern" ]] && continue
        [[ "$pattern" =~ ^[[:space:]]*- ]] || continue
        
        # Extract pattern (remove YAML list marker)
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*- *//' | sed 's/"//g')
        
        # Convert glob pattern to regex for matching
        if [[ "$file_path" =~ $(echo "$pattern" | sed 's/\*/.*/g') ]]; then
            return 0  # Is critical
        fi
    done < <(sed -n '/^critical_files:/,/^[[:alnum:]]/p' "$CONFIG_FILE")
    
    return 1  # Not critical
}

# Validate critical file content
validate_critical_content() {
    local file_path="$1"
    local errors=0
    
    echo -e "${BLUE}🔍 Validating critical content: $(basename "$file_path")${NC}"
    
    # Check minimum content length
    local min_length=$(get_config_value "min_content_length" "500")
    local content_length=$(wc -c < "$file_path" 2>/dev/null || echo "0")
    
    if [ "$content_length" -lt "$min_length" ]; then
        echo -e "${RED}❌ Content too short: $content_length < $min_length chars${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✅ Content length sufficient: $content_length chars${NC}"
    fi
    
    # Check for required sections
    echo "Checking required sections..."
    local required_found=true
    
    if ! grep -q "## Overview\|# Overview" "$file_path" 2>/dev/null; then
        echo -e "${RED}❌ Missing required section: Overview${NC}"
        required_found=false
        ((errors++))
    fi
    
    if ! grep -qE "## Related|# Related|## Links|# Links|\[\[.*\]\]" "$file_path" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Missing cross-references section${NC}"
    fi
    
    if [ "$required_found" = true ]; then
        echo -e "${GREEN}✅ Required sections found${NC}"
    fi
    
    # Check for ADR-specific requirements
    if [[ "$file_path" =~ ADR- ]]; then
        echo "Validating ADR-specific requirements..."
        
        if ! grep -qE "## Status|# Status" "$file_path" 2>/dev/null; then
            echo -e "${RED}❌ ADR missing Status section${NC}"
            ((errors++))
        fi
        
        if ! grep -qE "Confidence.*[0-9]+%" "$file_path" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  ADR missing confidence assessment${NC}"
        else
            echo -e "${GREEN}✅ Confidence assessment found${NC}"
        fi
    fi
    
    return $errors
}

# Run enhanced link validation for critical files
validate_critical_links() {
    local file_path="$1"
    local errors=0
    
    echo -e "${BLUE}🔗 Enhanced link validation for critical file${NC}"
    
    # Run standard link validation first
    if ! "$TEST_SCRIPT" link-health > /tmp/critical-validation.log 2>&1; then
        # Check if our specific file has broken links
        if grep -q "$file_path" /tmp/critical-validation.log; then
            echo -e "${RED}❌ Critical file has broken links${NC}"
            
            # Extract specific broken links for this file
            grep "$file_path" /tmp/critical-validation.log | while read -r line; do
                echo -e "${RED}  ⚠️  $line${NC}"
            done
            ((errors++))
        else
            echo -e "${YELLOW}⚠️  System has broken links, but not in this critical file${NC}"
        fi
    else
        echo -e "${GREEN}✅ All links validated successfully${NC}"
    fi
    
    # Check for external link accessibility (sample check)
    echo "Checking external links accessibility..."
    local external_links=$(grep -oE 'https?://[^)\s]+' "$file_path" 2>/dev/null || true)
    local external_errors=0
    
    if [ -n "$external_links" ]; then
        while IFS= read -r url; do
            if ! curl -s --head --max-time 5 "$url" > /dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  External link may be unreachable: $url${NC}"
                ((external_errors++))
            fi
        done <<< "$external_links"
        
        if [ $external_errors -eq 0 ]; then
            echo -e "${GREEN}✅ All external links accessible${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️  No external links to validate${NC}"
    fi
    
    rm -f /tmp/critical-validation.log
    return $errors
}

# Generate critical files report
generate_critical_report() {
    local output_file="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${BLUE}📊 Generating critical files report...${NC}"
    
    cat > "$output_file" << EOF
# Critical Files Validation Report

**Generated:** $timestamp
**Configuration:** $(basename "$CONFIG_FILE")

## Critical Files Status

EOF

    local total_critical=0
    local passed_critical=0
    
    # Find all critical files
    find "${CORTEX_PATH:-../cortex}" -name "*.md" -type f 2>/dev/null | while read -r file; do
        if is_critical_file "$file"; then
            echo "Processing critical file: $(basename "$file")"
            ((total_critical++))
            
            echo "### $(basename "$file")" >> "$output_file"
            echo "- **Path:** \`$file\`" >> "$output_file"
            
            # Run validation
            local validation_errors=0
            if validate_critical_content "$file" >/dev/null 2>&1; then
                echo "- **Content Validation:** ✅ Passed" >> "$output_file"
            else
                echo "- **Content Validation:** ❌ Failed" >> "$output_file"
                ((validation_errors++))
            fi
            
            if validate_critical_links "$file" >/dev/null 2>&1; then
                echo "- **Link Validation:** ✅ Passed" >> "$output_file"
            else
                echo "- **Link Validation:** ❌ Failed" >> "$output_file"
                ((validation_errors++))
            fi
            
            if [ $validation_errors -eq 0 ]; then
                echo "- **Overall Status:** ✅ PASSED" >> "$output_file"
                ((passed_critical++))
            else
                echo "- **Overall Status:** ❌ FAILED ($validation_errors errors)" >> "$output_file"
            fi
            
            echo "" >> "$output_file"
        fi
    done
    
    # Add summary
    cat >> "$output_file" << EOF

## Summary

- **Total Critical Files:** $total_critical
- **Passed Validation:** $passed_critical
- **Failed Validation:** $((total_critical - passed_critical))
- **Success Rate:** $(( passed_critical * 100 / total_critical ))%

## Recommendations

EOF

    if [ $passed_critical -lt $total_critical ]; then
        cat >> "$output_file" << EOF
⚠️  **Action Required:** Some critical files failed validation.

Priority actions:
1. Fix broken links in critical files
2. Ensure all required content sections are present
3. Add missing confidence assessments to ADRs
4. Review and update outdated content

EOF
    else
        cat >> "$output_file" << EOF
✅ **All Critical Files Validated Successfully**

The Cortex system's critical infrastructure is healthy and properly cross-linked.

EOF
    fi
    
    echo -e "${GREEN}✅ Report generated: $output_file${NC}"
}

# Main execution
main() {
    local command="${1:-validate}"
    local target_file="$2"
    
    echo -e "${PURPLE}🛡️  Cortex Critical Path Protection${NC}"
    echo "====================================="
    
    case "$command" in
        "validate")
            if [ -n "$target_file" ]; then
                # Validate specific file
                if [ ! -f "$target_file" ]; then
                    echo -e "${RED}❌ File not found: $target_file${NC}"
                    exit 1
                fi
                
                if is_critical_file "$target_file"; then
                    echo -e "${BLUE}🎯 Validating critical file: $(basename "$target_file")${NC}"
                    
                    local content_errors=0
                    local link_errors=0
                    
                    validate_critical_content "$target_file" || content_errors=$?
                    validate_critical_links "$target_file" || link_errors=$?
                    
                    local total_errors=$((content_errors + link_errors))
                    
                    if [ $total_errors -eq 0 ]; then
                        echo -e "${GREEN}🎉 Critical file validation PASSED${NC}"
                        exit 0
                    else
                        echo -e "${RED}❌ Critical file validation FAILED ($total_errors errors)${NC}"
                        exit 1
                    fi
                else
                    echo -e "${YELLOW}ℹ️  File is not classified as critical${NC}"
                    echo -e "${GREEN}✅ No critical validation required${NC}"
                    exit 0
                fi
            else
                # Validate all critical files
                echo -e "${BLUE}🔍 Validating all critical files...${NC}"
                generate_critical_report "/tmp/critical-validation-report.md"
                echo ""
                echo -e "${BLUE}📋 View full report: /tmp/critical-validation-report.md${NC}"
            fi
            ;;
            
        "report")
            local output_file="${target_file:-critical-files-report.md}"
            generate_critical_report "$output_file"
            ;;
            
        "list")
            echo -e "${BLUE}📋 Critical Files List${NC}"
            echo "===================="
            
            find "${CORTEX_PATH:-../cortex}" -name "*.md" -type f 2>/dev/null | while read -r file; do
                if is_critical_file "$file"; then
                    echo -e "${GREEN}✓${NC} $file"
                fi
            done
            ;;
            
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [FILE]"
            echo ""
            echo "Commands:"
            echo "  validate [FILE]    Validate critical file(s)"
            echo "  report [OUTPUT]    Generate validation report"
            echo "  list              List all critical files"
            echo "  help              Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 validate System-Workflows.md"
            echo "  $0 report critical-status.md"
            echo "  $0 list"
            ;;
            
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"