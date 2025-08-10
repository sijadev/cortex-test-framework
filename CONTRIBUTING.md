# Contributing to Cortex Test Framework

Thank you for your interest in contributing to the Cortex Test Framework! This document provides guidelines for contributing to this intelligent knowledge base link health management system.

## Development Setup

### Prerequisites
- **Shell:** Bash or Zsh
- **Python:** 3.7+ for AI components
- **Tools:** jq, sqlite3, bc (for data processing)
- **Optional:** markdownlint, shellcheck (for development)

### Quick Start
```bash
git clone https://github.com/sijadev/cortex-test-framework.git
cd cortex-test-framework
./quick-pipeline-demo.sh  # Test the system
```

## Framework Architecture

### Core Components
1. **Test Manager** (`test-manager-enhanced.sh`) - Main orchestration
2. **AI Link Advisor** (`ai-link-advisor.py`) - Intelligent suggestions  
3. **Template Guardian** (`template-guardian.sh`) - Template protection
4. **Critical Path Validator** (`critical-path-validator.sh`) - System protection
5. **Monitoring Dashboard** (`link-health-dashboard.sh`) - Real-time monitoring
6. **Optimized Pipeline** (`optimized-test-pipeline.sh`) - Logical test sequence

### Development Phases
- ✅ **Phase 1:** Sofortiger Schutz (Complete)
- ✅ **Phase 2:** Intelligenter Schutz (Complete)  
- 🔄 **Phase 3:** Präventive Evolution (Open for contributions)

## Contributing Guidelines

### Code Style
- **Shell Scripts:** Follow existing patterns, use proper error handling
- **Python:** Follow PEP 8, use type hints where appropriate
- **Documentation:** Update README and inline comments
- **Testing:** Test with `./quick-pipeline-demo.sh` before submitting

### Commit Message Format
```
type: brief description

Detailed explanation if needed

- Bullet points for key changes
- Reference issues with #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Process
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test thoroughly
4. Update documentation if needed
5. Submit pull request with clear description

### Testing Requirements
- [ ] Run `./quick-pipeline-demo.sh` successfully
- [ ] Test individual components affected
- [ ] Verify no breaking changes
- [ ] Update tests if adding new features

## Areas for Contribution

### High Priority (Phase 3)
- **Predictive Analytics:** Health score trend prediction
- **Auto-Healing:** Automated fix application for safe patterns
- **Architecture Validation:** Proactive system health checking

### Medium Priority
- **Performance:** Optimize large knowledge base scanning
- **Integrations:** VS Code, Obsidian plugin compatibility
- **UI/UX:** Enhanced dashboard visualizations

### Low Priority  
- **Documentation:** More examples and tutorials
- **Testing:** Extended test coverage
- **Cleanup:** Code refactoring and optimization

## Development Workflow

### Local Testing
```bash
# Test individual components
./template-guardian.sh status
./critical-path-validator.sh list
./link-health-dashboard.sh status

# Test full pipeline
./optimized-test-pipeline.sh full

# Run cleanup
./cleanup.sh
```

### Before Submitting
1. **Lint your code:** Use shellcheck for shell scripts
2. **Test thoroughly:** All components should work together
3. **Update documentation:** Keep README and docs current
4. **Check health impact:** Document any changes to health scoring

## Issue Reporting

### Bug Reports
Use the bug report template and include:
- Clear reproduction steps
- Expected vs actual behavior
- Environment details (OS, shell, version)
- Output from `./quick-pipeline-demo.sh`

### Feature Requests  
Use the feature request template and specify:
- Problem being solved
- Proposed solution
- Which framework phase it belongs to
- Implementation ideas if any

## Questions and Support

- **Discussions:** Use GitHub Discussions for questions
- **Issues:** File issues for bugs and feature requests
- **Security:** Report security issues privately via email

## Recognition

Contributors will be recognized in:
- README.md contributor section
- Release notes for significant contributions
- Special recognition for Phase 3 implementations

## Development Resources

### Useful Commands
```bash
# Framework status
./quick-pipeline-demo.sh

# Component testing
./optimized-test-pipeline.sh [1-5]

# Database inspection
sqlite3 ai_link_advisor.db ".tables"
sqlite3 link-health-metrics.db ".schema"

# Log analysis
tail -f test-results/*.log
```

### Code Patterns
- Error handling: Always use `set -e` in shell scripts  
- Logging: Use colored output with consistent format
- Configuration: YAML/JSON for structured config
- Data storage: SQLite for persistence, JSON for interchange

Thank you for contributing to the Cortex Test Framework! 🚀