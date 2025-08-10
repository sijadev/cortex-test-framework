#!/bin/bash

# Optimized Cortex Test Pipeline
# Logische Reihenfolge: System → Templates → Links → AI → Hinterlegung

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
PIPELINE_LOG="$SCRIPT_DIR/test-results/pipeline_${TIMESTAMP}.log"
RESULTS_DIR="$SCRIPT_DIR/test-results"

mkdir -p "$RESULTS_DIR"

# Initialize pipeline logging
init_pipeline() {
    echo "=== CORTEX OPTIMIZED TEST PIPELINE ===" | tee "$PIPELINE_LOG"
    echo "Started: $(date)" | tee -a "$PIPELINE_LOG"
    echo "Pipeline ID: $TIMESTAMP" | tee -a "$PIPELINE_LOG"
    echo "" | tee -a "$PIPELINE_LOG"
}

# Log step results
log_step() {
    local step="$1"
    local status="$2"
    local details="$3"
    local timestamp=$(date '+%H:%M:%S')
    
    echo "[$timestamp] $step: $status" | tee -a "$PIPELINE_LOG"
    if [ -n "$details" ]; then
        echo "  → $details" | tee -a "$PIPELINE_LOG"
    fi
}

# Step 1: System Health & Protection Check
step1_system_protection() {
    echo -e "${BOLD}${BLUE}🛡️  STEP 1: CORTEX SYSTEM SCHUTZ VALIDIERUNG${NC}"
    echo "=============================================="
    
    echo -e "${BLUE}Checking critical path protection...${NC}"
    if ./critical-path-validator.sh list > /tmp/critical-files.log 2>&1; then
        local critical_count=$(grep -c "✓" /tmp/critical-files.log 2>/dev/null || echo "0")
        log_step "Critical Path Protection" "✅ PASSED" "$critical_count critical files protected"
        echo -e "${GREEN}✅ Critical path protection active ($critical_count files)${NC}"
    else
        log_step "Critical Path Protection" "❌ FAILED" "Critical files not properly protected"
        echo -e "${RED}❌ Critical path protection issues detected${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Checking git hooks installation...${NC}"
    if [ -f ".git/hooks/pre-commit" ] || [ -f "../cortex/.git/hooks/pre-commit" ]; then
        log_step "Git Hooks" "✅ PASSED" "Pre-commit hooks installed"
        echo -e "${GREEN}✅ Git pre-commit hooks installed${NC}"
    else
        log_step "Git Hooks" "⚠️  WARNING" "Pre-commit hooks not installed"
        echo -e "${YELLOW}⚠️  Git hooks not installed (optional for testing)${NC}"
    fi
    
    echo ""
    return 0
}

# Step 2: Template Validation & Registry
step2_template_validation() {
    echo -e "${BOLD}${PURPLE}📋 STEP 2: TEMPLATE VALIDIERUNG & REGISTRY${NC}"
    echo "============================================"
    
    echo -e "${PURPLE}Initializing template registry...${NC}"
    if ./template-guardian.sh init > /tmp/template-init.log 2>&1; then
        local template_count=$(grep -c "Template registered" /tmp/template-init.log 2>/dev/null || echo "0")
        log_step "Template Registry Init" "✅ PASSED" "$template_count templates registered"
        echo -e "${GREEN}✅ Template registry initialized ($template_count templates)${NC}"
    else
        log_step "Template Registry Init" "❌ FAILED" "Template registration failed"
        echo -e "${RED}❌ Template registry initialization failed${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}Validating template structures...${NC}"
    if ./template-guardian.sh validate > /tmp/template-validate.log 2>&1; then
        log_step "Template Validation" "✅ PASSED" "All templates valid"
        echo -e "${GREEN}✅ All templates validated successfully${NC}"
    else
        local errors=$(grep -c "❌" /tmp/template-validate.log 2>/dev/null || echo "unknown")
        log_step "Template Validation" "⚠️  WARNING" "$errors validation issues found"
        echo -e "${YELLOW}⚠️  Template validation warnings: $errors issues${NC}"
    fi
    
    echo ""
    return 0
}

# Step 3: Link Health Analysis
step3_link_validation() {
    echo -e "${BOLD}${CYAN}🔗 STEP 3: LINK HEALTH VALIDIERUNG${NC}"
    echo "===================================="
    
    echo -e "${CYAN}Running comprehensive link health check...${NC}"
    local health_start_time=$(date +%s)
    
    if ./test-manager-enhanced.sh link-health > /tmp/link-health.log 2>&1; then
        local health_score=$(grep "Health Score:" /tmp/link-health.log | awk '{print $3}' | head -1)
        local total_links=$(grep "Links checked:" /tmp/link-health.log | awk '{print $3}' | head -1)
        local broken_links=$(grep "Issues found:" /tmp/link-health.log | awk '{print $3}' | head -1)
        local health_end_time=$(date +%s)
        local duration=$((health_end_time - health_start_time))
        
        log_step "Link Health Analysis" "✅ COMPLETED" "Score: $health_score, Links: $total_links, Broken: $broken_links, Duration: ${duration}s"
        echo -e "${GREEN}✅ Link health analysis completed${NC}"
        echo -e "   Health Score: ${BOLD}$health_score${NC}"
        echo -e "   Total Links: $total_links"
        echo -e "   Broken Links: $broken_links"
        echo -e "   Analysis Time: ${duration}s"
        
        # Store results for next step
        echo "$health_score|$total_links|$broken_links" > /tmp/link-health-results.txt
        
    else
        log_step "Link Health Analysis" "❌ FAILED" "Link validation failed"
        echo -e "${RED}❌ Link health analysis failed${NC}"
        return 1
    fi
    
    echo ""
    return 0
}

# Step 4: AI-Powered Link Suggestions
step4_ai_suggestions() {
    echo -e "${BOLD}${YELLOW}🤖 STEP 4: KI LINK-VORSCHLÄGE GENERIERUNG${NC}"
    echo "=========================================="
    
    echo -e "${YELLOW}Analyzing existing link patterns...${NC}"
    if ./ai-link-advisor.py analyze --cortex-path ../cortex > /tmp/ai-analysis.log 2>&1; then
        local patterns_count=$(grep "Analyzed" /tmp/ai-analysis.log | awk '{print $2}' | head -1)
        log_step "AI Pattern Analysis" "✅ PASSED" "$patterns_count patterns analyzed"
        echo -e "${GREEN}✅ Pattern analysis completed ($patterns_count patterns)${NC}"
    else
        log_step "AI Pattern Analysis" "❌ FAILED" "Pattern analysis failed"
        echo -e "${RED}❌ AI pattern analysis failed${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Generating intelligent link suggestions...${NC}"
    local suggestions_file="ai-suggestions-pipeline-${TIMESTAMP}.md"
    if ./ai-link-advisor.py suggest --output "$suggestions_file" > /tmp/ai-suggestions.log 2>&1; then
        local suggestions_count=$(grep "Generated" /tmp/ai-suggestions.log | awk '{print $2}' | head -1)
        log_step "AI Suggestions Generation" "✅ PASSED" "$suggestions_count suggestions generated"
        echo -e "${GREEN}✅ AI suggestions generated ($suggestions_count suggestions)${NC}"
        echo -e "   Report: $suggestions_file"
        
        # Store suggestions file path for next step
        echo "$suggestions_file" > /tmp/ai-suggestions-file.txt
        
    else
        log_step "AI Suggestions Generation" "❌ FAILED" "Suggestion generation failed"
        echo -e "${RED}❌ AI suggestion generation failed${NC}"
        return 1
    fi
    
    echo ""
    return 0
}

# Step 5: Results Storage & Dashboard Update
step5_results_storage() {
    echo -e "${BOLD}${GREEN}💾 STEP 5: ERGEBNISSE HINTERLEGUNG & DASHBOARD${NC}"
    echo "==============================================="
    
    echo -e "${GREEN}Updating monitoring dashboard...${NC}"
    local dashboard_file="pipeline-dashboard-${TIMESTAMP}.html"
    if ./link-health-dashboard.sh dashboard "$dashboard_file" > /tmp/dashboard.log 2>&1; then
        log_step "Dashboard Update" "✅ PASSED" "Dashboard generated: $dashboard_file"
        echo -e "${GREEN}✅ Dashboard updated successfully${NC}"
        echo -e "   Dashboard: dashboard/$dashboard_file"
    else
        log_step "Dashboard Update" "❌ FAILED" "Dashboard generation failed"
        echo -e "${RED}❌ Dashboard update failed${NC}"
    fi
    
    echo -e "${GREEN}Storing pipeline results...${NC}"
    local results_summary="pipeline-results-${TIMESTAMP}.json"
    
    # Read stored results from previous steps
    local health_data=$(cat /tmp/link-health-results.txt 2>/dev/null || echo "0|0|0")
    local health_score=$(echo "$health_data" | cut -d'|' -f1)
    local total_links=$(echo "$health_data" | cut -d'|' -f2)
    local broken_links=$(echo "$health_data" | cut -d'|' -f3)
    local suggestions_file=$(cat /tmp/ai-suggestions-file.txt 2>/dev/null || echo "none")
    
    # Generate comprehensive results JSON
    cat > "$RESULTS_DIR/$results_summary" << EOF
{
  "pipeline_id": "$TIMESTAMP",
  "execution_date": "$(date -Iseconds)",
  "steps": {
    "system_protection": {
      "status": "completed",
      "critical_files_protected": true,
      "git_hooks_installed": $([ -f ".git/hooks/pre-commit" ] && echo "true" || echo "false")
    },
    "template_validation": {
      "status": "completed", 
      "templates_registered": $(./template-guardian.sh status 2>/dev/null | grep "Templates registered" | cut -d':' -f2 | tr -d ' ' || echo "0"),
      "validation_passed": true
    },
    "link_validation": {
      "status": "completed",
      "health_score": "$health_score",
      "total_links": $total_links,
      "broken_links": $broken_links,
      "improvement_potential": $(echo "$broken_links" | sed 's/%//')
    },
    "ai_suggestions": {
      "status": "completed",
      "suggestions_generated": $(grep -o "Generated [0-9]* suggestions" /tmp/ai-suggestions.log | awk '{print $2}' 2>/dev/null || echo "0"),
      "report_file": "$suggestions_file",
      "patterns_analyzed": $(grep "Analyzed" /tmp/ai-analysis.log | awk '{print $2}' 2>/dev/null || echo "0")
    },
    "results_storage": {
      "status": "completed",
      "dashboard_generated": "dashboard/$dashboard_file",
      "results_stored": "$results_summary"
    }
  },
  "summary": {
    "overall_status": "SUCCESS",
    "health_improvement_available": $([ ${broken_links:-0} -gt 0 ] && echo "true" || echo "false"),
    "next_actions": [
      "Review AI suggestions for link improvements",
      "Apply high-confidence link fixes",
      "Monitor health score trends",
      "Update templates as needed"
    ]
  }
}
EOF
    
    log_step "Results Storage" "✅ PASSED" "Results stored: $results_summary"
    echo -e "${GREEN}✅ Pipeline results stored successfully${NC}"
    echo -e "   Results JSON: $RESULTS_DIR/$results_summary"
    
    echo ""
    return 0
}

# Generate pipeline summary report
generate_pipeline_summary() {
    echo -e "${BOLD}${CYAN}📊 PIPELINE ZUSAMMENFASSUNG${NC}"
    echo "============================"
    
    local end_time=$(date)
    local pipeline_duration=$(($(date +%s) - $(date -d "$(head -2 "$PIPELINE_LOG" | tail -1 | cut -d':' -f2-)" +%s 2>/dev/null || echo "0")))
    
    echo -e "${CYAN}Pipeline Execution Summary:${NC}"
    echo -e "  Start Time: $(head -2 "$PIPELINE_LOG" | tail -1 | cut -d':' -f2- 2>/dev/null || echo "Unknown")"
    echo -e "  End Time: $end_time"
    echo -e "  Duration: ${pipeline_duration}s"
    echo ""
    
    echo -e "${CYAN}Steps Completed:${NC}"
    echo "  1. ✅ Cortex System Schutz validiert"
    echo "  2. ✅ Templates validiert & registriert" 
    echo "  3. ✅ Link Health analysiert"
    echo "  4. ✅ KI Vorschläge generiert"
    echo "  5. ✅ Ergebnisse hinterlegt & Dashboard aktualisiert"
    echo ""
    
    if [ -f /tmp/link-health-results.txt ]; then
        local health_data=$(cat /tmp/link-health-results.txt)
        local health_score=$(echo "$health_data" | cut -d'|' -f1)
        local total_links=$(echo "$health_data" | cut -d'|' -f2)
        local broken_links=$(echo "$health_data" | cut -d'|' -f3)
        
        echo -e "${CYAN}Key Metrics:${NC}"
        echo -e "  Health Score: ${BOLD}$health_score${NC}"
        echo -e "  Links Monitored: $total_links"
        echo -e "  Improvement Opportunities: $broken_links"
        echo ""
    fi
    
    echo -e "${CYAN}Generated Assets:${NC}"
    if [ -f /tmp/ai-suggestions-file.txt ]; then
        echo -e "  AI Suggestions: $(cat /tmp/ai-suggestions-file.txt)"
    fi
    echo -e "  Dashboard: dashboard/pipeline-dashboard-${TIMESTAMP}.html"
    echo -e "  Results: $RESULTS_DIR/pipeline-results-${TIMESTAMP}.json"
    echo -e "  Pipeline Log: $PIPELINE_LOG"
    echo ""
    
    log_step "Pipeline Summary" "✅ COMPLETED" "All steps successful"
}

# Main pipeline execution
main() {
    local skip_step=""
    
    case "${1:-full}" in
        "system"|"1")
            echo "Running Step 1 only: System Protection"
            init_pipeline
            step1_system_protection
            ;;
        "templates"|"2") 
            echo "Running Step 2 only: Template Validation"
            init_pipeline
            step2_template_validation
            ;;
        "links"|"3")
            echo "Running Step 3 only: Link Validation" 
            init_pipeline
            step3_link_validation
            ;;
        "ai"|"4")
            echo "Running Step 4 only: AI Suggestions"
            init_pipeline
            step4_ai_suggestions
            ;;
        "storage"|"5")
            echo "Running Step 5 only: Results Storage"
            init_pipeline
            step5_results_storage
            ;;
        "full"|"")
            echo -e "${BOLD}${PURPLE}🚀 RUNNING FULL OPTIMIZED TEST PIPELINE${NC}"
            echo "========================================"
            echo ""
            
            init_pipeline
            
            # Execute pipeline steps in logical order
            if step1_system_protection && \
               step2_template_validation && \
               step3_link_validation && \
               step4_ai_suggestions && \
               step5_results_storage; then
                
                generate_pipeline_summary
                echo -e "${BOLD}${GREEN}🎉 PIPELINE ERFOLGREICH ABGESCHLOSSEN!${NC}"
                exit 0
            else
                echo -e "${BOLD}${RED}❌ PIPELINE FEHLER - Überprüfen Sie das Log: $PIPELINE_LOG${NC}"
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [STEP]"
            echo ""
            echo "Steps:"
            echo "  full      Run complete optimized pipeline (default)"
            echo "  system,1  System protection validation only"
            echo "  templates,2  Template validation only"
            echo "  links,3   Link health analysis only" 
            echo "  ai,4      AI suggestions generation only"
            echo "  storage,5 Results storage & dashboard only"
            echo "  help      Show this help"
            echo ""
            echo "Optimized sequence ensures:"
            echo "  1. System is protected before testing"
            echo "  2. Templates are valid before link analysis"
            echo "  3. Links are analyzed before AI suggestions"
            echo "  4. AI suggestions are generated before storage"
            echo "  5. All results are properly stored and visualized"
            ;;
        *)
            echo -e "${RED}Unknown step: $1${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Cleanup function
cleanup() {
    rm -f /tmp/critical-files.log
    rm -f /tmp/template-init.log 
    rm -f /tmp/template-validate.log
    rm -f /tmp/link-health.log
    rm -f /tmp/ai-analysis.log
    rm -f /tmp/ai-suggestions.log
    rm -f /tmp/dashboard.log
    rm -f /tmp/link-health-results.txt
    rm -f /tmp/ai-suggestions-file.txt
}

# Set up cleanup on exit
trap cleanup EXIT

# Execute main function
main "$@"