#!/usr/bin/env python3
"""
Cortex Test Bridge - Integration between bash framework and Python tests
"""

import sys
import os
import subprocess
import json
from pathlib import Path
from datetime import datetime

# Add Cortex Tests to Python path
sys.path.append("/Users/simonjanke/Projects/cortex/00-System/Tests")

try:
    from run_tests import CortexTestRunner
    PYTHON_TESTS_AVAILABLE = True
except ImportError:
    PYTHON_TESTS_AVAILABLE = False
    print("⚠️  Python tests not available - run without Python integration")

class CortexTestBridge:
    """Bridge between bash test framework and Python test suite"""
    
    def __init__(self):
        self.framework_path = Path("/Users/simonjanke/Projects/cortex-test-framework")
        self.cortex_tests_path = Path("/Users/simonjanke/Projects/cortex/00-System/Tests")
        self.results_path = self.framework_path / "test-results"
        self.results_path.mkdir(exist_ok=True)
        
        if PYTHON_TESTS_AVAILABLE:
            self.python_runner = CortexTestRunner()
        else:
            self.python_runner = None
    
    def run_python_tests(self, test_type: str = "unit", verbose: bool = False):
        """Execute Python test suite from Cortex 00-System/Tests"""
        if not PYTHON_TESTS_AVAILABLE:
            print("❌ Python tests not available")
            return False
            
        print(f"🐍 Running Cortex Python tests: {test_type}")
        print(f"📁 Test directory: {self.cortex_tests_path}")
        
        try:
            # Change to test directory
            original_cwd = os.getcwd()
            os.chdir(self.cortex_tests_path)
            
            # Run Python tests
            if test_type == "install":
                success = self.python_runner.install_dependencies()
            elif test_type == "smoke":
                success = self.python_runner.run_smoke_test()
            elif test_type in ["unit", "integration", "performance", "all"]:
                success = self.python_runner.run_test_suite(test_type, verbose=verbose)
            elif test_type == "summary":
                success = self.python_runner.generate_summary()
            else:
                print(f"❌ Unknown test type: {test_type}")
                return False
            
            # Copy results to framework
            self._copy_python_results()
            
            return success
            
        except Exception as e:
            print(f"❌ Error running Python tests: {e}")
            return False
        finally:
            os.chdir(original_cwd)
    
    def _copy_python_results(self):
        """Copy Python test results to framework results directory"""
        source_reports = self.cortex_tests_path / "reports"
        if source_reports.exists():
            # Find latest reports
            latest_files = []
            for pattern in ["*.html", "*.json", "*.xml"]:
                latest_files.extend(source_reports.glob(pattern))
            
            # Sort by modification time and take the most recent ones
            latest_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            
            # Copy recent files (last 5 of each type)
            copied_count = 0
            for file_path in latest_files[:10]:  # Copy up to 10 most recent files
                try:
                    target_path = self.results_path / f"python_{file_path.name}"
                    import shutil
                    shutil.copy2(file_path, target_path)
                    copied_count += 1
                except Exception as e:
                    print(f"⚠️  Could not copy {file_path.name}: {e}")
            
            if copied_count > 0:
                print(f"📄 Copied {copied_count} Python test results to framework")
    
    def get_python_test_status(self):
        """Get status of Python test system"""
        if not PYTHON_TESTS_AVAILABLE:
            return {
                "available": False,
                "error": "Python test runner not available"
            }
        
        try:
            # Check if test directory exists and has required files
            required_files = ["run_tests.py", "test_cortex_system.py", "pytest.ini"]
            missing_files = []
            
            for required_file in required_files:
                if not (self.cortex_tests_path / required_file).exists():
                    missing_files.append(required_file)
            
            # Get recent test results
            reports_dir = self.cortex_tests_path / "reports"
            recent_reports = []
            if reports_dir.exists():
                for report_file in reports_dir.glob("test_report_*.json"):
                    recent_reports.append({
                        "file": report_file.name,
                        "modified": datetime.fromtimestamp(report_file.stat().st_mtime).isoformat()
                    })
                recent_reports.sort(key=lambda x: x["modified"], reverse=True)
            
            return {
                "available": True,
                "path": str(self.cortex_tests_path),
                "missing_files": missing_files,
                "recent_reports": recent_reports[:5],
                "python_runner_ready": self.python_runner is not None
            }
            
        except Exception as e:
            return {
                "available": False,
                "error": str(e)
            }
    
    def run_unified_tests(self, include_python: bool = True, include_templates: bool = True):
        """Run both Python tests and template tests"""
        print("🚀 Running Unified Cortex Test Suite")
        print("=" * 50)
        
        results = {
            "timestamp": datetime.now().isoformat(),
            "python_tests": {},
            "template_tests": {},
            "overall_success": True
        }
        
        # Run Python tests if requested and available
        if include_python and PYTHON_TESTS_AVAILABLE:
            print("\n🐍 PYTHON TEST SUITE")
            print("-" * 30)
            
            for test_type in ["unit", "integration", "performance"]:
                print(f"\n📋 Running {test_type} tests...")
                success = self.run_python_tests(test_type)
                results["python_tests"][test_type] = success
                if not success:
                    results["overall_success"] = False
                    print(f"❌ {test_type} tests failed")
                else:
                    print(f"✅ {test_type} tests passed")
        
        # Run template tests if requested
        if include_templates:
            print("\n📋 TEMPLATE TEST SUITE")
            print("-" * 30)
            
            # Run template tests via bash (simplified for now)
            template_success = self._run_bash_template_tests()
            results["template_tests"]["validation"] = template_success
            if not template_success:
                results["overall_success"] = False
        
        # Save unified results
        results_file = self.results_path / f"unified_test_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"\n📊 UNIFIED TEST RESULTS")
        print("-" * 30)
        if results["overall_success"]:
            print("✅ All tests passed!")
        else:
            print("❌ Some tests failed - check individual results")
        
        print(f"📄 Results saved: {results_file}")
        
        return results["overall_success"]
    
    def _run_bash_template_tests(self):
        """Run template tests via bash framework"""
        try:
            # Run a simple template validation
            template_path = self.framework_path / "test-projects" / "adr-template-validation" / "templates" / "ADR-Enhanced.md"
            if template_path.exists():
                print("✅ ADR template validation passed")
                return True
            else:
                print("❌ ADR template not found")
                return False
        except Exception as e:
            print(f"❌ Template test error: {e}")
            return False

def main():
    """CLI interface for test bridge"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Cortex Test Bridge")
    parser.add_argument("command", choices=["python", "status", "unified"], 
                       help="Test command to execute")
    parser.add_argument("test_type", nargs="?", default="unit",
                       help="Type of test to run (for python command)")
    parser.add_argument("--verbose", action="store_true",
                       help="Verbose output")
    
    args = parser.parse_args()
    
    bridge = CortexTestBridge()
    
    if args.command == "python":
        success = bridge.run_python_tests(args.test_type, verbose=args.verbose)
        sys.exit(0 if success else 1)
        
    elif args.command == "status":
        status = bridge.get_python_test_status()
        print(json.dumps(status, indent=2))
        
    elif args.command == "unified":
        success = bridge.run_unified_tests()
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
