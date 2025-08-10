# 🔗 Cortex Test Framework

*Intelligent Knowledge Base Link Health Management System*

[![GitHub Actions](https://github.com/sijadev/cortex-test-framework/workflows/Cortex%20Test%20Framework%20CI/badge.svg)](https://github.com/sijadev/cortex-test-framework/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Health Score](https://img.shields.io/badge/Health%20Score-83.7%25-green)](https://github.com/sijadev/cortex-test-framework)

## 🎯 Overview

The Cortex Test Framework is a production-ready intelligent link health management system designed for knowledge bases using Obsidian, Markdown, or similar tools. It provides comprehensive link validation, AI-powered suggestions, template protection, and real-time monitoring with a 3-phase architecture.

### Key Features

- ✅ **AI-Powered Link Analysis** - 111 intelligent suggestions with confidence scoring
- ✅ **Template Protection System** - Semantic versioning for 10+ templates
- ✅ **Real-time Monitoring** - Interactive dashboards with trend analysis  
- ✅ **Critical Path Protection** - Enhanced validation for 20+ system files
- ✅ **Optimized Pipeline** - Logical test sequence with comprehensive reporting
- ✅ **Community Ready** - Open source with CI/CD and contribution guidelines

### Health Score Achievement

**Current:** 83.7% (↗️ +18.0% improvement from 65.8% baseline)

## 🚀 Quick Start

### Prerequisites

- **Shell:** Bash or Zsh
- **Python:** 3.7+ for AI components  
- **Tools:** jq, sqlite3, bc
- **Knowledge Base:** Markdown files with WikiLinks `[[target]]`

### Installation

```bash
git clone https://github.com/sijadev/cortex-test-framework.git
cd cortex-test-framework
chmod +x *.sh
```

### Basic Usage

```bash
# Quick system demonstration
./quick-pipeline-demo.sh

# Run optimized test pipeline  
./optimized-test-pipeline.sh full

# Generate health dashboard
./link-health-dashboard.sh dashboard

# Get AI suggestions for broken links
./ai-link-advisor.py suggest --output suggestions.md
```

## 📊 System Architecture

### 3-Phase Design

```
┌─────────────────────────────────────────────────────────────┐
│                CORTEX LINK HEALTH SYSTEM                   │
├─────────────────────────────────────────────────────────────┤
│  Phase 1: Sofortiger Schutz ✅                            │
│  ├── Template Placeholder Exclusion                        │
│  ├── Git Pre-commit Hooks                                  │
│  └── Critical Path Protection                              │
│                                                             │
│  Phase 2: Intelligenter Schutz ✅                         │
│  ├── AI-powered Link Analysis                              │
│  ├── Template Versioning System                            │
│  └── Real-time Monitoring Dashboards                       │
│                                                             │
│  Phase 3: Präventive Evolution 🔄                         │
│  ├── Predictive Link Health Analysis                       │
│  ├── Auto-Healing for Standard Patterns                    │
│  └── Proactive Architecture Validation                     │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

| Component | File | Purpose |
|-----------|------|---------|
| **Test Manager** | `test-manager-enhanced.sh` | Main orchestration and validation |
| **AI Link Advisor** | `ai-link-advisor.py` | Intelligent suggestions with learning |
| **Template Guardian** | `template-guardian.sh` | Template protection and versioning |
| **Critical Validator** | `critical-path-validator.sh` | System file protection |
| **Health Dashboard** | `link-health-dashboard.sh` | Real-time monitoring and reporting |
| **Pipeline Manager** | `optimized-test-pipeline.sh` | Logical test sequence execution |

## 🧠 AI-Powered Features

### Intelligent Link Suggestions

The AI Link Advisor provides contextual suggestions using:

- **Fuzzy Matching** - String similarity for typos and variations
- **Semantic Analysis** - Concept overlap between content and targets  
- **Pattern Learning** - Historical data from existing valid links
- **Confidence Scoring** - 60-90% confidence range with detailed reasoning

### Learning System

```python
# Pattern analysis with SQLite storage
./ai-link-advisor.py analyze --cortex-path ../cortex  # Learn from existing links
./ai-link-advisor.py suggest --output suggestions.md  # Generate recommendations
```

### Success Metrics

- **111 AI Suggestions** generated with confidence scoring
- **72 Link Patterns** analyzed and learned
- **Pattern-based Matching** for contextual recommendations
- **SQLite Knowledge Base** for persistent learning

## 🛡️ Template Protection

### Semantic Versioning System

```bash
# Initialize template protection
./template-guardian.sh init

# Validate template structures  
./template-guardian.sh validate

# Check for template changes
./template-guardian.sh check

# Generate template status report
./template-guardian.sh report
```

### Features

- **10 Templates Protected** with version control
- **Automated Change Detection** via hash comparison
- **Interactive Version Management** with user prompts
- **Template-specific Validation** (ADR, Project templates)
- **Version History Snapshots** with metadata

## 📈 Real-time Monitoring

### Interactive Dashboard

```bash
# Generate HTML dashboard with charts
./link-health-dashboard.sh dashboard health-report.html

# Check health alerts  
./link-health-dashboard.sh alerts

# Export metrics for external systems
./link-health-dashboard.sh export metrics.json

# Generate monitoring report
./link-health-dashboard.sh report weekly-report.md 7
```

### Dashboard Features

- **Interactive Charts** with Chart.js visualization
- **Health Score Trends** over time
- **Alert System** (85% warning, 70% critical thresholds)
- **File-level Health** breakdown
- **Multi-format Export** (JSON/CSV)

## 🔧 Optimized Pipeline

### Logical Test Sequence

The optimized pipeline ensures proper order:

1. **🛡️ System Protection** - Validate critical files and hooks
2. **📋 Template Validation** - Check template registry and structure
3. **🔗 Link Health Analysis** - Comprehensive link scanning  
4. **🤖 AI Suggestions** - Generate intelligent recommendations
5. **💾 Results Storage** - Archive results and update dashboard

### Pipeline Commands

```bash
# Run complete pipeline
./optimized-test-pipeline.sh full

# Run individual steps
./optimized-test-pipeline.sh system      # Step 1
./optimized-test-pipeline.sh templates   # Step 2  
./optimized-test-pipeline.sh links       # Step 3
./optimized-test-pipeline.sh ai          # Step 4
./optimized-test-pipeline.sh storage     # Step 5
```

## 📊 Current Metrics

### System Health
- **Health Score:** 83.7% (↗️ +18.0% from baseline)
- **Total Links:** 158 monitored across knowledge base
- **Broken Links:** 39 identified (down from 61)
- **Templates Protected:** 10 with semantic versioning
- **Critical Files:** 20 system files under enhanced protection

### AI Performance  
- **Suggestions Generated:** 111 with confidence scoring
- **Pattern Recognition:** 72 learned link patterns
- **Success Rate:** High-confidence suggestions >80%
- **Learning Database:** SQLite with persistent knowledge

### Monitoring Coverage
- **Dashboard Updates:** Real-time with trend analysis
- **Alert Thresholds:** 85% warning, 70% critical
- **Export Formats:** JSON, CSV, HTML
- **Retention Policy:** 30-day metrics storage

## 🎯 Usage Examples

### Daily Operations

```bash
# Quick system health check
./quick-pipeline-demo.sh

# Generate daily suggestions  
./ai-link-advisor.py suggest --output daily-$(date +%Y%m%d).md

# Update monitoring dashboard
./link-health-dashboard.sh dashboard
```

### Weekly Maintenance

```bash
# Run comprehensive validation
./optimized-test-pipeline.sh full

# Clean old data and optimize databases
./cleanup.sh

# Generate weekly health report
./link-health-dashboard.sh report weekly-report.md 7
```

### Development Workflow

```bash
# Install git hooks for validation
./install-git-hooks.sh

# Validate critical files before commit
./critical-path-validator.sh validate System-Workflows.md

# Check template changes
./template-guardian.sh check
```

## 🛠️ Configuration

### Critical Files Protection

Edit `.cortex-critical.yml` to define protected files:

```yaml
critical_files:
  - "**/System-Workflows*"
  - "**/Confidence Calculator*"  
  - "**/Auth-System*"
  - "**/ADR-001-JWT-vs-Sessions*"

health_thresholds:
  critical_files: 95
  overall_system: 80
  warning_level: 85
```

### AI Learning Configuration

The AI system learns from your knowledge base structure automatically:

- **Pattern Recognition** from existing valid links
- **Concept Extraction** from file names and headers
- **Semantic Matching** based on content analysis
- **Confidence Scoring** based on pattern frequency and success

## 📚 Documentation

### Complete Guides

- **[Installation Guide](CONTRIBUTING.md#development-setup)** - Complete setup instructions
- **[Architecture Guide](CONTRIBUTING.md#framework-architecture)** - System design and components
- **[Pipeline Guide](optimized-test-pipeline.sh)** - Test execution workflow
- **[AI Guide](ai-link-advisor.py)** - AI suggestions and learning system

### API Reference

- **[Test Manager](test-manager-enhanced.sh)** - Main orchestration commands
- **[Dashboard API](link-health-dashboard.sh)** - Monitoring and export functions
- **[Template API](template-guardian.sh)** - Template protection functions
- **[Validator API](critical-path-validator.sh)** - Critical path protection

## 🤝 Contributing

We welcome contributions! This project is designed for community collaboration.

### Phase 3 Development Opportunities

- **Predictive Analytics** - Health score trend forecasting
- **Auto-Healing** - Automated link repair for safe patterns
- **Architecture Validation** - Proactive system health checking

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test with `./quick-pipeline-demo.sh`
4. Submit a pull request with clear description

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for detailed guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Success Story

### Before Framework
- **Manual Link Checking** - Time-consuming and error-prone
- **No Template Protection** - Templates could break without notice  
- **Reactive Problem Solving** - Issues discovered after damage
- **Limited Visibility** - No health metrics or trends

### After Framework (Current)
- **83.7% Health Score** - Continuous monitoring and improvement
- **AI-Powered Suggestions** - 111 intelligent recommendations  
- **Template Protection** - 10 templates with version control
- **Real-time Dashboards** - Interactive monitoring and alerts
- **Community Ready** - Open source with CI/CD pipeline

### Roadmap (Phase 3)
- **Predictive Health Analysis** - Trend forecasting and early warnings
- **Auto-Healing Capabilities** - Automated fixes for common patterns
- **Proactive Validation** - Architecture health automation

---

## 🚀 Get Started

```bash
# Clone and test the system
git clone https://github.com/sijadev/cortex-test-framework.git
cd cortex-test-framework
./quick-pipeline-demo.sh
```

**Transform your knowledge base into an intelligent, self-monitoring system!**

---

*Cortex Test Framework v2.0 | Intelligent Knowledge Base Protection | Community Driven*