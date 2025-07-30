#!/usr/bin/env python3

"""
Stress tests for the AI handoff system
Tests performance under load, edge cases, and error conditions
"""

import time
import subprocess
import concurrent.futures
import sys
import os
import random
import string

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Import phi3 simulator
import importlib.util
phi3_spec = importlib.util.spec_from_file_location("phi3_simulator", "../phi3-simulator.py")
phi3_module = importlib.util.module_from_spec(phi3_spec)
phi3_spec.loader.exec_module(phi3_module)

class StressTester:
    def __init__(self):
        self.simulator = phi3_module.Phi3Simulator()
        self.results = {
            'parsing_times': [],
            'cleaning_times': [],
            'errors': [],
            'edge_cases_passed': 0,
            'edge_cases_failed': 0
        }
    
    def generate_random_command(self):
        """Generate random but valid commands for stress testing"""
        commands = [
            'ls -la', 'make clean', 'npm test', 'git status', 'python script.py',
            'docker build', './configure', 'make install', 'cargo build',
            'go test', 'pytest', 'eslint src/', 'tsc --build'
        ]
        panes = ['left', 'top', 'bottom']
        verbs = ['Run', 'Execute']
        
        verb = random.choice(verbs)
        command = random.choice(commands)
        pane = random.choice(panes)
        
        return f"{verb} {command} in the {pane} pane"
    
    def generate_edge_case_command(self):
        """Generate edge case commands that might break parsing"""
        edge_cases = [
            "Run 'echo \"nested \\\"quotes\\\"\"' in left pane",
            "Execute ./script.sh --arg='value with spaces' in top",
            "Run command with $USER and `backticks` in bottom pane",
            "Execute 'grep -r \"pattern\" .' in left",
            "Run echo 'single quotes with \"double\" inside' in top",
            'Execute "double quotes with \'single\' inside" in bottom',
            "Run very-long-command-name-that-might-cause-issues-with-parsing in left",
            "Execute command; echo 'multiple; commands' in top pane"
        ]
        return random.choice(edge_cases)
    
    def stress_test_parsing(self, num_commands=1000):
        """Stress test the natural language parsing"""
        print(f"🔥 Stress testing parsing with {num_commands} commands...")
        
        start_time = time.time()
        successful = 0
        failed = 0
        
        for i in range(num_commands):
            try:
                request = self.generate_random_command()
                parse_start = time.time()
                result = self.simulator.parse_natural_language(request)
                parse_end = time.time()
                
                self.results['parsing_times'].append(parse_end - parse_start)
                
                # Validate result has required fields
                required_fields = ['pane', 'command', 'timeout_category', 'timeout_seconds']
                if all(field in result for field in required_fields):
                    successful += 1
                else:
                    failed += 1
                    self.results['errors'].append(f"Missing fields in parse result: {result}")
                    
            except Exception as e:
                failed += 1
                self.results['errors'].append(f"Parse error: {str(e)}")
        
        end_time = time.time()
        total_time = end_time - start_time
        avg_time = sum(self.results['parsing_times']) / len(self.results['parsing_times'])
        
        print(f"✅ Parsing stress test completed:")
        print(f"   Total time: {total_time:.2f}s")
        print(f"   Average parse time: {avg_time*1000:.2f}ms")
        print(f"   Successful: {successful}")
        print(f"   Failed: {failed}")
        print(f"   Success rate: {(successful/(successful+failed))*100:.1f}%")
        
        return failed == 0
    
    def stress_test_output_cleaning(self, num_outputs=500):
        """Stress test the output cleaning functionality"""
        print(f"🧹 Stress testing output cleaning with {num_outputs} outputs...")
        
        # Generate various types of output
        output_templates = [
            "ryan-workflow-bash:{pane} $ {command}\n{output}\nprogram execution done. exit_code={exit_code}",
            "ryan-workflow-bash:{pane} $ timeout 300 {command}\n{output}\nTimeout reached\nprogram execution done. exit_code=124",
            "ryan-workflow-bash:{pane} $ {command}\n{output}\nError: Command failed\nprogram execution done. exit_code=1"
        ]
        
        successful = 0
        failed = 0
        
        for i in range(num_outputs):
            try:
                # Generate random output
                template = random.choice(output_templates)
                pane = random.choice(['left', 'top', 'bottom'])
                command = random.choice(['make', 'test', 'build', 'run'])
                output_lines = [f"Output line {j}" for j in range(random.randint(1, 10))]
                exit_code = random.choice([0, 1, 2, 124])
                
                raw_output = template.format(
                    pane=pane,
                    command=command,
                    output='\n'.join(output_lines),
                    exit_code=exit_code
                )
                
                clean_start = time.time()
                result = self.simulator.clean_tmux_output(raw_output)
                clean_end = time.time()
                
                self.results['cleaning_times'].append(clean_end - clean_start)
                
                # Validate result
                required_fields = ['output_type', 'exit_code', 'summary', 'cleaned_output']
                if all(field in result for field in required_fields):
                    successful += 1
                else:
                    failed += 1
                    self.results['errors'].append(f"Missing fields in clean result: {result}")
                    
            except Exception as e:
                failed += 1
                self.results['errors'].append(f"Clean error: {str(e)}")
        
        avg_time = sum(self.results['cleaning_times']) / len(self.results['cleaning_times'])
        
        print(f"✅ Output cleaning stress test completed:")
        print(f"   Average clean time: {avg_time*1000:.2f}ms")
        print(f"   Successful: {successful}")
        print(f"   Failed: {failed}")
        print(f"   Success rate: {(successful/(successful+failed))*100:.1f}%")
        
        return failed == 0
    
    def test_edge_cases(self):
        """Test problematic edge cases that might break the system"""
        print("🎯 Testing edge cases and boundary conditions...")
        
        edge_cases = [
            "Run 'echo \"nested \\\"quotes\\\"\"' in left pane",
            "Execute ./script.sh --arg='value with spaces' in top",
            "Run command with $USER and `backticks` in bottom pane",
            "Execute 'grep -r \"pattern\" .' in left",
            "Run echo 'single quotes with \"double\" inside' in top",
            'Execute "double quotes with \'single\' inside" in bottom',
            "Run very-long-command-name-that-might-cause-issues-with-parsing-and-could-potentially-break-things in left",
            "Execute command; echo 'multiple; commands' in top pane",
            "Run echo 'unicode: 🎯 🔥 ✅ ❌' in bottom",
            "Execute 'python -c \"print(\\\"hello\\\")\"' in left pane"
        ]
        
        for case in edge_cases:
            try:
                result = self.simulator.parse_natural_language(case)
                if result and 'command' in result and result['command']:
                    self.results['edge_cases_passed'] += 1
                    print(f"   ✅ Passed: {case[:50]}...")
                else:
                    self.results['edge_cases_failed'] += 1
                    print(f"   ❌ Failed: {case[:50]}...")
            except Exception as e:
                self.results['edge_cases_failed'] += 1
                print(f"   ❌ Error: {case[:50]}... ({str(e)})")
        
        success_rate = (self.results['edge_cases_passed'] / 
                       (self.results['edge_cases_passed'] + self.results['edge_cases_failed'])) * 100
        
        print(f"✅ Edge case testing completed:")
        print(f"   Success rate: {success_rate:.1f}%")
        
        return success_rate > 80  # 80% pass rate for edge cases
    
    def concurrent_load_test(self, num_workers=10, commands_per_worker=100):
        """Test system under concurrent load"""
        print(f"⚡ Concurrent load test: {num_workers} workers, {commands_per_worker} commands each...")
        
        def worker_task(worker_id):
            worker_results = {'successful': 0, 'failed': 0, 'times': []}
            
            for i in range(commands_per_worker):
                try:
                    request = self.generate_random_command()
                    start_time = time.time()
                    result = self.simulator.parse_natural_language(request)
                    end_time = time.time()
                    
                    if result and 'command' in result:
                        worker_results['successful'] += 1
                        worker_results['times'].append(end_time - start_time)
                    else:
                        worker_results['failed'] += 1
                except Exception:
                    worker_results['failed'] += 1
            
            return worker_results
        
        start_time = time.time()
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=num_workers) as executor:
            futures = [executor.submit(worker_task, i) for i in range(num_workers)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        end_time = time.time()
        
        # Aggregate results
        total_successful = sum(r['successful'] for r in results)
        total_failed = sum(r['failed'] for r in results)
        all_times = []
        for r in results:
            all_times.extend(r['times'])
        
        total_commands = num_workers * commands_per_worker
        total_time = end_time - start_time
        throughput = total_commands / total_time
        avg_time = sum(all_times) / len(all_times) if all_times else 0
        
        print(f"✅ Concurrent load test completed:")
        print(f"   Total commands: {total_commands}")
        print(f"   Total time: {total_time:.2f}s")
        print(f"   Throughput: {throughput:.1f} commands/second")
        print(f"   Average response time: {avg_time*1000:.2f}ms")
        print(f"   Successful: {total_successful}")
        print(f"   Failed: {total_failed}")
        print(f"   Success rate: {(total_successful/total_commands)*100:.1f}%")
        
        return total_failed == 0 and throughput > 100  # Should handle >100 commands/second
    
    def memory_usage_test(self):
        """Test for memory leaks under sustained load"""
        print("🧠 Memory usage test...")
        
        import psutil
        import gc
        
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # Run sustained operations
        for i in range(5000):
            request = self.generate_random_command()
            self.simulator.parse_natural_language(request)
            
            # Generate and clean output
            raw_output = f"ryan-workflow-bash:left $ {request}\nOutput\nprogram execution done. exit_code=0"
            self.simulator.clean_tmux_output(raw_output)
            
            if i % 1000 == 0:
                gc.collect()  # Force garbage collection
        
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_growth = final_memory - initial_memory
        
        print(f"✅ Memory usage test completed:")
        print(f"   Initial memory: {initial_memory:.1f} MB")
        print(f"   Final memory: {final_memory:.1f} MB")
        print(f"   Memory growth: {memory_growth:.1f} MB")
        
        # Should not grow by more than 50MB
        return memory_growth < 50
    
    def run_all_stress_tests(self):
        """Run all stress tests"""
        print("🚀 Starting comprehensive stress test suite...")
        print("=" * 60)
        
        tests = [
            ("Parsing Stress Test", lambda: self.stress_test_parsing(1000)),
            ("Output Cleaning Stress Test", lambda: self.stress_test_output_cleaning(500)),
            ("Edge Cases Test", self.test_edge_cases),
            ("Concurrent Load Test", lambda: self.concurrent_load_test(10, 100)),
            ("Memory Usage Test", self.memory_usage_test)
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            print(f"\n🧪 Running {test_name}...")
            try:
                if test_func():
                    print(f"✅ {test_name} PASSED")
                    passed += 1
                else:
                    print(f"❌ {test_name} FAILED")
            except Exception as e:
                print(f"💥 {test_name} CRASHED: {str(e)}")
        
        print("\n" + "=" * 60)
        print(f"🏁 STRESS TEST SUMMARY:")
        print(f"   Passed: {passed}/{total}")
        print(f"   Success Rate: {(passed/total)*100:.1f}%")
        
        if self.results['errors']:
            print(f"\n⚠️  Errors encountered:")
            for error in self.results['errors'][:5]:  # Show first 5 errors
                print(f"   • {error}")
            if len(self.results['errors']) > 5:
                print(f"   ... and {len(self.results['errors']) - 5} more")
        
        return passed == total

if __name__ == '__main__':
    print("🔥 AI HANDOFF SYSTEM STRESS TESTS 🔥")
    print("=" * 60)
    
    tester = StressTester()
    success = tester.run_all_stress_tests()
    
    if success:
        print("\n🎉 ALL STRESS TESTS PASSED! 🎉")
        print("The system is ready for high-load production use.")
        sys.exit(0)
    else:
        print("\n❌ SOME STRESS TESTS FAILED ❌")
        print("Review the failures before deploying under load.")
        sys.exit(1)
