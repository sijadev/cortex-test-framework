#!/bin/bash
# Enhanced Cortex Template System Integration

FRAMEWORK_PATH="/Users/simonjanke/Projects/cortex-test-framework"

# Create the template system
cat > "$FRAMEWORK_PATH/cortex-template-system.sh" << 'EOF'
#!/bin/bash
# Template-Based Link Prevention System for Cortex
source /Users/simonjanke/Projects/cortex-test-framework/template-link-prevention.sh
EOF

chmod +x "$FRAMEWORK_PATH/cortex-template-system.sh"

echo "✅ Template system integration created"
echo ""
echo "🎯 NEUER WORKFLOW:"
echo ""
echo "Statt manueller Links:"
echo "  [[SomeFile]] # Risiko für Tippfehler"
echo ""  
echo "Template-basierte Erstellung:"
echo "  cortex-test template-create adr"
echo "  > Zeigt verfügbare Files"
echo "  > Validiert alle Links"
echo "  > Nur gültige Optionen"
echo ""
echo "🔗 Verfügbare Template-Commands:"
echo "  cortex-test template-create adr           # Smart ADR creation"
echo "  cortex-test template-autocomplete Project # Get valid links"
echo "  cortex-test template-validate file.md     # Validate existing"
echo "  cortex-test template-setup               # Initialize system"
