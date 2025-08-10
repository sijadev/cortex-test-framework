# Test Results Directory

This directory contains generated test results and reports:

## File Types
- `broken_links_*.json/md` - Link validation results
- `pipeline_*.log` - Pipeline execution logs  
- `python_*.xml/html/json` - Python test results
- `*.log` - Various test logs

## Retention Policy
- Latest 5 results of each type are kept
- Older results are automatically cleaned by `cleanup.sh`
- Files are ignored by git but directory structure is preserved

## Manual Cleanup
Run `../cleanup.sh` to clean old results while preserving recent data.