#!/bin/bash

# Template Guardian - Template versioning and protection system
# Manages template evolution, validates template integrity, and protects against breaking changes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORTEX_PATH="${CORTEX_PATH:-../cortex}"
TEMPLATES_DIR="$CORTEX_PATH/00-Templates"
TEMPLATE_REGISTRY="$SCRIPT_DIR/template-registry.json"
TEMPLATE_VERSIONS_DIR="$SCRIPT_DIR/template-versions"
BACKUP_DIR="$SCRIPT_DIR/template-backups"

# Ensure directories exist
mkdir -p "$TEMPLATE_VERSIONS_DIR" "$BACKUP_DIR"

# Template metadata structure
create_template_metadata() {
    local template_file="$1"
    local template_name=$(basename "$template_file" .md)
    local template_path="$template_file"
    local version="1.0.0"
    local timestamp=$(date -Iseconds)
    
    cat << EOF
{
  "name": "$template_name",
  "path": "$template_path",
  "version": "$version",
  "created_at": "$timestamp",
  "updated_at": "$timestamp",
  "hash": "$(sha256sum "$template_file" | cut -d' ' -f1)",
  "required_sections": [],
  "optional_sections": [],
  "placeholders": [],
  "dependencies": [],
  "usage_count": 0,
  "compatibility": {
    "min_framework_version": "1.0.0",
    "max_framework_version": null,
    "breaking_changes": []
  },
  "validation_rules": {
    "min_content_length": 100,
    "required_placeholders": [],
    "forbidden_patterns": [],
    "custom_validators": []
  }
}
EOF
}

# Initialize template registry
init_template_registry() {
    echo -e "${BLUE}🏗️  Initializing template registry...${NC}"
    
    if [ ! -f "$TEMPLATE_REGISTRY" ]; then
        echo '{"templates": {}, "schema_version": "1.0", "last_updated": "'$(date -Iseconds)'"}' > "$TEMPLATE_REGISTRY"
    fi
    
    # Scan for templates and register them
    for template_file in "$TEMPLATES_DIR"/*.md; do
        if [ -f "$template_file" ]; then
            register_template "$template_file"
        fi
    done
    
    echo -e "${GREEN}✅ Template registry initialized${NC}"
}

# Register a template in the registry
register_template() {
    local template_file="$1"
    local template_name=$(basename "$template_file" .md)
    
    echo -e "${BLUE}📝 Registering template: $template_name${NC}"
    
    # Create metadata
    local metadata=$(create_template_metadata "$template_file")
    
    # Analyze template structure
    local sections=$(extract_sections "$template_file")
    local placeholders=$(extract_placeholders "$template_file")
    
    # Update registry
    local temp_registry=$(mktemp)
    jq --arg name "$template_name" --argjson metadata "$metadata" --arg timestamp "$(date -Iseconds)" \
       '.templates[$name] = $metadata | .last_updated = $timestamp' \
       "$TEMPLATE_REGISTRY" > "$temp_registry"
    
    mv "$temp_registry" "$TEMPLATE_REGISTRY"
    
    # Create initial version snapshot
    create_template_snapshot "$template_file" "1.0.0" "Initial registration"
    
    echo -e "${GREEN}✅ Template registered: $template_name${NC}"
}

# Extract sections from template
extract_sections() {
    local template_file="$1"
    
    grep '^##\? ' "$template_file" | sed 's/^##\? //' | jq -R -s 'split("\n") | map(select(length > 0))'
}

# Extract placeholders from template
extract_placeholders() {
    local template_file="$1"
    
    grep -o '{{[^}]*}}' "$template_file" | sort -u | jq -R -s 'split("\n") | map(select(length > 0))'
}

# Create template version snapshot
create_template_snapshot() {
    local template_file="$1"
    local version="$2"
    local message="$3"
    local template_name=$(basename "$template_file" .md)
    
    local version_dir="$TEMPLATE_VERSIONS_DIR/$template_name"
    mkdir -p "$version_dir"
    
    local snapshot_file="$version_dir/${version}.md"
    cp "$template_file" "$snapshot_file"
    
    # Create version metadata
    cat > "$version_dir/${version}.json" << EOF
{
  "template": "$template_name",
  "version": "$version",
  "created_at": "$(date -Iseconds)",
  "message": "$message",
  "hash": "$(sha256sum "$template_file" | cut -d' ' -f1)",
  "file_size": $(stat -c%s "$template_file"),
  "changes": {
    "added_sections": [],
    "removed_sections": [],
    "modified_sections": [],
    "added_placeholders": [],
    "removed_placeholders": []
  }
}
EOF
    
    echo -e "${GREEN}📸 Created snapshot: $template_name v$version${NC}"
}

# Validate template integrity
validate_template() {
    local template_file="$1"
    local template_name=$(basename "$template_file" .md)
    local errors=0
    
    echo -e "${BLUE}🔍 Validating template: $template_name${NC}"
    
    # Check if template exists
    if [ ! -f "$template_file" ]; then
        echo -e "${RED}❌ Template file not found: $template_file${NC}"
        return 1
    fi
    
    # Basic structure validation
    if ! grep -q '^#\|^##' "$template_file"; then
        echo -e "${RED}❌ No header structure found${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✅ Header structure present${NC}"
    fi
    
    # Check for required placeholders
    local placeholders=$(grep -o '{{[^}]*}}' "$template_file" | sort -u || true)
    if [ -n "$placeholders" ]; then
        echo -e "${GREEN}✅ Found placeholders:${NC}"
        echo "$placeholders" | sed 's/^/  - /'
    else
        echo -e "${YELLOW}⚠️  No placeholders found - is this intentional?${NC}"
    fi
    
    # Validate placeholder syntax
    if grep -q '{[^{]' "$template_file" || grep -q '[^}]}' "$template_file"; then
        echo -e "${YELLOW}⚠️  Potential malformed placeholder syntax${NC}"
    fi
    
    # Check for common template patterns
    if grep -q 'Status.*Accepted\|Status.*Draft' "$template_file"; then
        echo -e "${GREEN}✅ Status section present${NC}"
    fi
    
    if grep -q '\[\[.*\]\]' "$template_file"; then
        echo -e "${GREEN}✅ Contains example links${NC}"
    fi
    
    # Validate markdown syntax
    if command -v markdownlint >/dev/null 2>&1; then
        if markdownlint "$template_file" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Markdown syntax valid${NC}"
        else
            echo -e "${YELLOW}⚠️  Markdown syntax issues detected${NC}"
            # Don't count as error - many templates intentionally have loose syntax
        fi
    fi
    
    # Template-specific validations
    case "$template_name" in
        "ADR-Enhanced")
            validate_adr_template "$template_file" || ((errors++))
            ;;
        "Project-Workspace")
            validate_project_template "$template_file" || ((errors++))
            ;;
    esac
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}🎉 Template validation passed${NC}"
        return 0
    else
        echo -e "${RED}❌ Template validation failed with $errors errors${NC}"
        return 1
    fi
}

# ADR template specific validation
validate_adr_template() {
    local template_file="$1"
    local errors=0
    
    echo "  🎯 ADR-specific validation..."
    
    # Check for required ADR sections
    local required_sections=("Status" "Context" "Decision" "Consequences")
    for section in "${required_sections[@]}"; do
        if grep -qi "^##.*$section\|^#.*$section" "$template_file"; then
            echo -e "${GREEN}  ✅ Required section: $section${NC}"
        else
            echo -e "${RED}  ❌ Missing required section: $section${NC}"
            ((errors++))
        fi
    done
    
    # Check for confidence assessment
    if grep -qi "confidence\|assessment" "$template_file"; then
        echo -e "${GREEN}  ✅ Confidence assessment section present${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No confidence assessment section${NC}"
    fi
    
    return $errors
}

# Project template specific validation
validate_project_template() {
    local template_file="$1"
    local errors=0
    
    echo "  🎯 Project template validation..."
    
    # Check for key project sections
    if grep -qi "^##.*overview\|^#.*overview" "$template_file"; then
        echo -e "${GREEN}  ✅ Overview section present${NC}"
    else
        echo -e "${RED}  ❌ Missing overview section${NC}"
        ((errors++))
    fi
    
    if grep -qi "timeline\|schedule\|roadmap" "$template_file"; then
        echo -e "${GREEN}  ✅ Timeline/roadmap section present${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No timeline/roadmap section${NC}"
    fi
    
    return $errors
}

# Detect template changes
detect_template_changes() {
    local template_file="$1"
    local template_name=$(basename "$template_file" .md)
    
    echo -e "${BLUE}🔍 Detecting changes in: $template_name${NC}"
    
    # Get current hash
    local current_hash=$(sha256sum "$template_file" | cut -d' ' -f1)
    
    # Get last known hash from registry
    local last_hash=$(jq -r ".templates[\"$template_name\"].hash // empty" "$TEMPLATE_REGISTRY")
    
    if [ -z "$last_hash" ]; then
        echo -e "${YELLOW}⚠️  Template not in registry - registering now${NC}"
        register_template "$template_file"
        return 0
    fi
    
    if [ "$current_hash" = "$last_hash" ]; then
        echo -e "${GREEN}✅ No changes detected${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🔄 Changes detected in template${NC}"
    
    # Analyze the type of changes
    analyze_template_changes "$template_file"
    
    # Prompt for version update
    prompt_version_update "$template_file"
}

# Analyze template changes
analyze_template_changes() {
    local template_file="$1"
    local template_name=$(basename "$template_file" .md)
    
    echo -e "${BLUE}📊 Analyzing changes...${NC}"
    
    # Find the latest version
    local latest_version_file=$(find "$TEMPLATE_VERSIONS_DIR/$template_name" -name "*.md" | sort -V | tail -1)
    
    if [ -n "$latest_version_file" ] && [ -f "$latest_version_file" ]; then
        echo "Comparing with previous version..."
        
        # Basic diff analysis
        local added_lines=$(diff -u "$latest_version_file" "$template_file" | grep '^+[^+]' | wc -l)
        local removed_lines=$(diff -u "$latest_version_file" "$template_file" | grep '^-[^-]' | wc -l)
        
        echo -e "${GREEN}  + Added lines: $added_lines${NC}"
        echo -e "${RED}  - Removed lines: $removed_lines${NC}"
        
        # Check for structural changes
        local old_sections=$(extract_sections "$latest_version_file")
        local new_sections=$(extract_sections "$template_file")
        
        if [ "$old_sections" != "$new_sections" ]; then
            echo -e "${YELLOW}  📋 Section structure changed${NC}"
        fi
        
        # Check for placeholder changes
        local old_placeholders=$(extract_placeholders "$latest_version_file")
        local new_placeholders=$(extract_placeholders "$template_file")
        
        if [ "$old_placeholders" != "$new_placeholders" ]; then
            echo -e "${YELLOW}  🏷️  Placeholder structure changed${NC}"
        fi
    fi
}

# Prompt for version update
prompt_version_update() {
    local template_file="$1"
    local template_name=$(basename "$template_file" .md)
    
    echo -e "${CYAN}🔄 Template has changed. Update version? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}What type of change is this?${NC}"
        echo "1) Patch (bug fixes, typos) - 1.0.1"
        echo "2) Minor (new features, backwards compatible) - 1.1.0"
        echo "3) Major (breaking changes) - 2.0.0"
        read -r change_type
        
        case "$change_type" in
            1) increment_version "$template_file" "patch" ;;
            2) increment_version "$template_file" "minor" ;;
            3) increment_version "$template_file" "major" ;;
            *) echo -e "${YELLOW}Invalid choice, skipping version update${NC}" ;;
        esac
    fi
}

# Increment template version
increment_version() {
    local template_file="$1"
    local increment_type="$2"
    local template_name=$(basename "$template_file" .md)
    
    # Get current version
    local current_version=$(jq -r ".templates[\"$template_name\"].version // \"1.0.0\"" "$TEMPLATE_REGISTRY")
    
    # Parse version components
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Increment based on type
    case "$increment_type" in
        "patch")
            patch=$((patch + 1))
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
    esac
    
    local new_version="$major.$minor.$patch"
    
    echo -e "${GREEN}📈 Updating version: $current_version → $new_version${NC}"
    
    # Create snapshot
    echo "Enter version message:"
    read -r version_message
    create_template_snapshot "$template_file" "$new_version" "$version_message"
    
    # Update registry
    local temp_registry=$(mktemp)
    jq --arg name "$template_name" --arg version "$new_version" --arg hash "$(sha256sum "$template_file" | cut -d' ' -f1)" --arg timestamp "$(date -Iseconds)" \
       '.templates[$name].version = $version | .templates[$name].hash = $hash | .templates[$name].updated_at = $timestamp' \
       "$TEMPLATE_REGISTRY" > "$temp_registry"
    
    mv "$temp_registry" "$TEMPLATE_REGISTRY"
    
    echo -e "${GREEN}✅ Version updated to $new_version${NC}"
}

# Generate template status report
generate_template_report() {
    local output_file="${1:-template-status-report.md}"
    
    echo -e "${BLUE}📊 Generating template status report...${NC}"
    
    cat > "$output_file" << EOF
# Template Status Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Registry:** $(basename "$TEMPLATE_REGISTRY")

## Template Overview

EOF

    # Process each template
    if [ -f "$TEMPLATE_REGISTRY" ]; then
        jq -r '.templates | keys[]' "$TEMPLATE_REGISTRY" | while read -r template_name; do
            local version=$(jq -r ".templates[\"$template_name\"].version" "$TEMPLATE_REGISTRY")
            local updated_at=$(jq -r ".templates[\"$template_name\"].updated_at" "$TEMPLATE_REGISTRY")
            local template_path=$(jq -r ".templates[\"$template_name\"].path" "$TEMPLATE_REGISTRY")
            
            echo "### $template_name" >> "$output_file"
            echo "- **Version:** $version" >> "$output_file"
            echo "- **Last Updated:** $updated_at" >> "$output_file"
            echo "- **Path:** \`$template_path\`" >> "$output_file"
            
            # Check if template file exists and is valid
            if [ -f "$template_path" ]; then
                echo "- **Status:** ✅ Active" >> "$output_file"
                
                # Run validation
                if validate_template "$template_path" >/dev/null 2>&1; then
                    echo "- **Validation:** ✅ Passed" >> "$output_file"
                else
                    echo "- **Validation:** ❌ Failed" >> "$output_file"
                fi
            else
                echo "- **Status:** ❌ Missing File" >> "$output_file"
            fi
            
            # Count versions
            local version_count=0
            if [ -d "$TEMPLATE_VERSIONS_DIR/$template_name" ]; then
                version_count=$(find "$TEMPLATE_VERSIONS_DIR/$template_name" -name "*.md" | wc -l)
            fi
            echo "- **Version History:** $version_count versions" >> "$output_file"
            
            echo "" >> "$output_file"
        done
    fi
    
    cat >> "$output_file" << EOF

## Health Summary

$(if [ -f "$TEMPLATE_REGISTRY" ]; then
    local total_templates=$(jq -r '.templates | keys | length' "$TEMPLATE_REGISTRY")
    local valid_templates=0
    
    jq -r '.templates | keys[]' "$TEMPLATE_REGISTRY" | while read -r template_name; do
        local template_path=$(jq -r ".templates[\"$template_name\"].path" "$TEMPLATE_REGISTRY")
        if [ -f "$template_path" ] && validate_template "$template_path" >/dev/null 2>&1; then
            valid_templates=$((valid_templates + 1))
        fi
    done
    
    echo "- **Total Templates:** $total_templates"
    echo "- **Valid Templates:** $valid_templates"
    echo "- **Health Score:** $(( (valid_templates * 100) / total_templates ))%"
fi)

## Actions Required

$(jq -r '.templates | to_entries[] | select(.value.hash != (.value.path | @sh | "sha256sum " + . + " | cut -d\" \" -f1" | @sh)) | "- Update version for: " + .key' "$TEMPLATE_REGISTRY" 2>/dev/null || echo "- No immediate actions required")

---

*This report is generated automatically by the Template Guardian system.*
EOF

    echo -e "${GREEN}✅ Template report generated: $output_file${NC}"
}

# Main execution logic
main() {
    local command="${1:-status}"
    local template_file="$2"
    
    echo -e "${PURPLE}🛡️  Template Guardian${NC}"
    echo "===================="
    
    case "$command" in
        "init")
            init_template_registry
            ;;
        "register")
            if [ -z "$template_file" ]; then
                echo -e "${RED}❌ Template file required${NC}"
                echo "Usage: $0 register <template-file>"
                exit 1
            fi
            register_template "$template_file"
            ;;
        "validate")
            if [ -n "$template_file" ]; then
                validate_template "$template_file"
            else
                # Validate all templates
                echo -e "${BLUE}🔍 Validating all templates...${NC}"
                for template in "$TEMPLATES_DIR"/*.md; do
                    if [ -f "$template" ]; then
                        echo ""
                        validate_template "$template"
                    fi
                done
            fi
            ;;
        "check")
            if [ -n "$template_file" ]; then
                detect_template_changes "$template_file"
            else
                # Check all templates
                echo -e "${BLUE}🔍 Checking all templates for changes...${NC}"
                for template in "$TEMPLATES_DIR"/*.md; do
                    if [ -f "$template" ]; then
                        echo ""
                        detect_template_changes "$template"
                    fi
                done
            fi
            ;;
        "report")
            generate_template_report "$template_file"
            ;;
        "status")
            if [ -f "$TEMPLATE_REGISTRY" ]; then
                echo -e "${BLUE}📋 Template Registry Status${NC}"
                echo "Templates registered: $(jq -r '.templates | keys | length' "$TEMPLATE_REGISTRY")"
                echo "Last updated: $(jq -r '.last_updated' "$TEMPLATE_REGISTRY")"
                echo ""
                echo "Templates:"
                jq -r '.templates | to_entries[] | "  - " + .key + " v" + .value.version' "$TEMPLATE_REGISTRY"
            else
                echo -e "${YELLOW}⚠️  Template registry not initialized${NC}"
                echo "Run: $0 init"
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [TEMPLATE-FILE]"
            echo ""
            echo "Commands:"
            echo "  init              Initialize template registry"
            echo "  register FILE     Register a template"
            echo "  validate [FILE]   Validate template(s)"
            echo "  check [FILE]      Check for template changes"
            echo "  report [OUTPUT]   Generate template status report"
            echo "  status            Show registry status"
            echo "  help              Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 validate ../cortex/00-Templates/ADR-Enhanced.md"
            echo "  $0 check"
            echo "  $0 report templates.md"
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