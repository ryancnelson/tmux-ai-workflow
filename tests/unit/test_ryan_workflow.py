#!/usr/bin/env python3

"""
Unit tests for the Ryan Workflow AI-collaborative coding system
Tests all components: setup, recovery, parsing, and safety protocols
"""

import unittest
import subprocess
import tempfile
import os
import json
import sys
from unittest.mock import patch, MagicMock

# Add the parent directory to path to import phi3-simulator
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Import the phi3 simulator
import importlib.util
phi3_spec = importlib.util.spec_from_file_location("phi3_simulator", "../phi3-simulator.py")
phi3_module = importlib.util.module_from_spec(phi3_spec)
phi3_spec.loader.exec_module(phi3_module)

class TestPhi3Simulator(unittest.TestCase):
    """Test the phi3 natural language parsing and output cleaning"""
    
    def setUp(self):
        self.simulator = phi3_module.Phi3Simulator()
    
    def test_parse_natural_language_basic(self):
        """Test basic command parsing"""
        request = "Run make clean in the top pane"
        result = self.simulator.parse_natural_language(request)
        
        self.assertEqual(result['pane'], 'top')
        self.assertEqual(result['command'], 'make clean')
        self.assertEqual(result['timeout_category'], 'build')
        self.assertEqual(result['timeout_seconds'], 300)
    
    def test_parse_natural_language_execute_verb(self):
        """Test parsing with 'execute' verb"""
        request = "Execute ./configure --prefix=/tmp in the left pane"
        result = self.simulator.parse_natural_language(request)
        
        self.assertEqual(result['pane'], 'left')
        self.assertEqual(result['command'], './configure --prefix=/tmp')
        self.assertEqual(result['timeout_category'], 'build')
    
    def test_parse_natural_language_quoted_command(self):
        """Test parsing commands with quotes"""
        request = 'Run "ls -la" in the bottom pane'
        result = self.simulator.parse_natural_language(request)
        
        self.assertEqual(result['pane'], 'bottom')
        self.assertEqual(result['command'], 'ls -la')
        self.assertEqual(result['timeout_category'], 'quick')
    
    def test_parse_natural_language_test_commands(self):
        """Test parsing test suite commands"""
        request = "Run npm test in the top pane"
        result = self.simulator.parse_natural_language(request)
        
        self.assertEqual(result['timeout_category'], 'test')
        self.assertEqual(result['timeout_seconds'], 600)
    
    def test_parse_natural_language_pane_detection(self):
        """Test various pane detection patterns"""
        test_cases = [
            ("Run ls in top", "top"),
            ("Execute cd in the left pane", "left"),
            ("Run make in bottom pane", "bottom"),
            ("Execute test", "left"),  # default
        ]
        
        for request, expected_pane in test_cases:
            with self.subTest(request=request):
                result = self.simulator.parse_natural_language(request)
                self.assertEqual(result['pane'], expected_pane)
    
    def test_generate_tmux_command_quick(self):
        """Test tmux command generation for quick commands"""
        parsed = {
            'pane': 'left',
            'command': 'ls -la',
            'timeout_category': 'quick',
            'timeout_seconds': 10
        }
        
        result = self.simulator.generate_tmux_command(parsed)
        expected = "tmux send-keys -t ryan-workflow:0.0 \"ls -la ; echo ; echo 'program execution done. exit_code=$?'\" Enter"
        self.assertEqual(result, expected)
    
    def test_generate_tmux_command_build(self):
        """Test tmux command generation for build commands"""
        parsed = {
            'pane': 'top',
            'command': 'make clean',
            'timeout_category': 'build',
            'timeout_seconds': 300
        }
        
        result = self.simulator.generate_tmux_command(parsed)
        expected = "tmux send-keys -t ryan-workflow:0.1 \"timeout 300 make clean ; echo ; echo 'program execution done. exit_code=$?'\" Enter"
        self.assertEqual(result, expected)
    
    def test_clean_tmux_output_success(self):
        """Test cleaning successful command output"""
        raw_output = """ryan-workflow-bash:top $ make test
Running tests...
All tests passed
program execution done. exit_code=0"""
        
        result = self.simulator.clean_tmux_output(raw_output)
        
        self.assertEqual(result['output_type'], 'success')
        self.assertEqual(result['exit_code'], 0)
        self.assertEqual(result['summary'], 'Command completed successfully')
        self.assertIn('Running tests...', result['cleaned_output'])
        self.assertNotIn('ryan-workflow-bash:', result['cleaned_output'])
    
    def test_clean_tmux_output_error(self):
        """Test cleaning failed command output"""
        raw_output = """ryan-workflow-bash:left $ make build
Building...
make: *** Error 1
program execution done. exit_code=2"""
        
        result = self.simulator.clean_tmux_output(raw_output)
        
        self.assertEqual(result['output_type'], 'error')
        self.assertEqual(result['exit_code'], 2)
        self.assertEqual(result['summary'], 'Command failed with exit code 2')
    
    def test_clean_tmux_output_timeout(self):
        """Test cleaning timed-out command output"""
        raw_output = """ryan-workflow-bash:bottom $ long-running-command
Starting long process...
program execution done. exit_code=124"""
        
        result = self.simulator.clean_tmux_output(raw_output)
        
        self.assertEqual(result['output_type'], 'timeout')
        self.assertEqual(result['exit_code'], 124)
        self.assertEqual(result['summary'], 'Command timed out')

class TestBase64Safety(unittest.TestCase):
    """Test base64 encoding safety protocols"""
    
    def test_base64_encoding_basic(self):
        """Test basic base64 encoding/decoding"""
        content = "Hello, world!"
        encoded = subprocess.check_output(['base64'], input=content.encode()).decode().strip()
        decoded = subprocess.check_output(['base64', '-d'], input=encoded.encode()).decode()
        
        self.assertEqual(content, decoded)
    
    def test_base64_encoding_special_chars(self):
        """Test base64 with special characters"""
        content = "Special chars: $USER @home 'quotes' \"double quotes\" `backticks`"
        encoded = subprocess.check_output(['base64'], input=content.encode()).decode().strip()
        decoded = subprocess.check_output(['base64', '-d'], input=encoded.encode()).decode()
        
        self.assertEqual(content, decoded)
    
    def test_base64_encoding_multiline(self):
        """Test base64 with multiline content"""
        content = """Line 1
Line 2 with $variables
Line 3 with 'quotes' and "double quotes"
Final line"""
        encoded = subprocess.check_output(['base64'], input=content.encode()).decode().strip()
        decoded = subprocess.check_output(['base64', '-d'], input=encoded.encode()).decode()
        
        self.assertEqual(content, decoded)
    
    def test_heredoc_problems_simulation(self):
        """Demonstrate why heredocs are problematic"""
        # This test shows the problems heredocs would cause
        problematic_content = '''Content with "quotes" and $variables and `backticks`
EOF on its own line
More content after EOF'''
        
        # With base64, this content is safe
        encoded = subprocess.check_output(['base64'], input=problematic_content.encode()).decode().strip()
        decoded = subprocess.check_output(['base64', '-d'], input=encoded.encode()).decode()
        
        self.assertEqual(problematic_content, decoded)

class TestTmuxIntegration(unittest.TestCase):
    """Test tmux session management and integration"""
    
    def setUp(self):
        self.test_session = "test-ryan-workflow"
    
    def tearDown(self):
        # Clean up test session if it exists
        try:
            subprocess.run(['tmux', 'kill-session', '-t', self.test_session], 
                         capture_output=True, check=False)
        except:
            pass
    
    def test_session_creation_logic(self):
        """Test the logic of session creation vs attachment"""
        # Test session doesn't exist
        result = subprocess.run(['tmux', 'has-session', '-t', self.test_session], 
                              capture_output=True)
        self.assertNotEqual(result.returncode, 0)  # Should fail, session doesn't exist
        
        # Create test session
        subprocess.run(['tmux', 'new-session', '-d', '-s', self.test_session], check=True)
        
        # Test session now exists
        result = subprocess.run(['tmux', 'has-session', '-t', self.test_session], 
                              capture_output=True)
        self.assertEqual(result.returncode, 0)  # Should succeed
    
    def test_pane_targeting(self):
        """Test tmux pane targeting"""
        # Create test session with panes
        subprocess.run(['tmux', 'new-session', '-d', '-s', self.test_session], check=True)
        subprocess.run(['tmux', 'split-window', '-h', '-t', self.test_session], check=True)
        
        # Test sending commands to specific panes
        subprocess.run(['tmux', 'send-keys', '-t', f'{self.test_session}:0.0', 'echo "left pane"', 'Enter'], check=True)
        subprocess.run(['tmux', 'send-keys', '-t', f'{self.test_session}:0.1', 'echo "right pane"', 'Enter'], check=True)
        
        # Capture output from both panes
        left_output = subprocess.check_output(['tmux', 'capture-pane', '-t', f'{self.test_session}:0.0', '-p']).decode()
        right_output = subprocess.check_output(['tmux', 'capture-pane', '-t', f'{self.test_session}:0.1', '-p']).decode()
        
        self.assertIn('left pane', left_output)
        self.assertIn('right pane', right_output)

class TestRecoveryProtocols(unittest.TestCase):
    """Test emergency recovery procedures"""
    
    def test_recovery_script_argument_parsing(self):
        """Test tmux-recover script argument parsing"""
        script_path = "../../tmux-recover"
        
        # Test help output
        result = subprocess.run(['bash', script_path], capture_output=True, text=True)
        self.assertIn('Usage:', result.stdout)
        self.assertIn('interrupt', result.stdout)
        self.assertIn('emergency', result.stdout)
    
    def test_pane_name_mapping(self):
        """Test pane name to target mapping"""
        mappings = {
            'left': '0.0',
            '0': '0.0',
            'top': '0.1', 
            '1': '0.1',
            'bottom': '0.2',
            '2': '0.2'
        }
        
        for pane_name, expected_target in mappings.items():
            # This tests the logic that would be in tmux-recover
            if pane_name in ['left', '0']:
                target = '0.0'
            elif pane_name in ['top', '1']:
                target = '0.1'
            elif pane_name in ['bottom', '2']:
                target = '0.2'
            else:
                target = None
            
            self.assertEqual(target, expected_target)

class TestSafetyProtocols(unittest.TestCase):
    """Test safety rule enforcement"""
    
    def test_heredoc_detection(self):
        """Test detection of problematic heredoc patterns"""
        problematic_patterns = [
            'cat << EOF',
            'cat <<EOF',
            'tee << "EOF"',
            'python << END',
        ]
        
        safe_patterns = [
            'echo "content" | base64 -d > file',
            'printf "content\\n" > file',
            'echo "encoded" | base64 -d | tee file',
        ]
        
        def is_heredoc(command):
            return any(pattern in command for pattern in ['<<', 'EOF', 'END'])
        
        for pattern in problematic_patterns:
            self.assertTrue(is_heredoc(pattern), f"Should detect heredoc in: {pattern}")
        
        for pattern in safe_patterns:
            self.assertFalse(is_heredoc(pattern), f"Should not detect heredoc in: {pattern}")
    
    def test_safety_rule_visibility(self):
        """Test that safety rules are prominently displayed"""
        # Check tmux-hello output contains safety warnings
        result = subprocess.run(['bash', '../../tmux-hello'], capture_output=True, text=True)
        
        self.assertIn('CRITICAL SAFETY RULES', result.stdout)
        self.assertIn('NEVER use heredoc', result.stdout)
        self.assertIn('base64 encoding', result.stdout)
        self.assertIn('OUTSIDE tmux', result.stdout)
    
    def test_safety_documentation_exists(self):
        """Test that all safety documentation files exist"""
        required_files = [
            '../../SAFETY-RULES.md',
            '../../AI-USAGE.md',
            '../../tmux-hello',
            '../../tmux-recover'
        ]
        
        for file_path in required_files:
            self.assertTrue(os.path.exists(file_path), f"Required safety file missing: {file_path}")

class TestWorkflowIntegration(unittest.TestCase):
    """Test end-to-end workflow scenarios"""
    
    def test_command_lifecycle(self):
        """Test complete command lifecycle: parse -> execute -> clean"""
        simulator = phi3_module.Phi3Simulator()
        
        # Step 1: Parse natural language
        request = "Run echo 'test success' in the left pane"
        parsed = simulator.parse_natural_language(request)
        
        # Step 2: Generate tmux command
        tmux_cmd = simulator.generate_tmux_command(parsed)
        
        # Step 3: Simulate execution output
        simulated_output = """ryan-workflow-bash:left $ echo 'test success' ; echo ; echo 'program execution done. exit_code=$?'
test success

program execution done. exit_code=0"""
        
        # Step 4: Clean output
        cleaned = simulator.clean_tmux_output(simulated_output)
        
        # Verify the complete lifecycle
        self.assertEqual(parsed['pane'], 'left')
        self.assertIn('echo', tmux_cmd)
        self.assertEqual(cleaned['output_type'], 'success')
        self.assertIn('test success', cleaned['cleaned_output'])
    
    def test_error_handling_workflow(self):
        """Test error handling in the complete workflow"""
        simulator = phi3_module.Phi3Simulator()
        
        # Parse a command that might fail
        request = "Run make nonexistent-target in the top pane"
        parsed = simulator.parse_natural_language(request)
        
        # Simulate failure output
        error_output = """ryan-workflow-bash:top $ timeout 300 make nonexistent-target ; echo ; echo 'program execution done. exit_code=$?'
make: *** No rule to make target 'nonexistent-target'. Stop.

program execution done. exit_code=2"""
        
        cleaned = simulator.clean_tmux_output(error_output)
        
        self.assertEqual(cleaned['output_type'], 'error')
        self.assertEqual(cleaned['exit_code'], 2)
        self.assertIn('No rule to make target', cleaned['cleaned_output'])

class TestPerformanceAndScaling(unittest.TestCase):
    """Test performance characteristics and scaling"""
    
    def test_base64_performance(self):
        """Test base64 encoding performance with large content"""
        import time
        
        # Create large content
        large_content = "Line of content\n" * 1000
        
        start_time = time.time()
        encoded = subprocess.check_output(['base64'], input=large_content.encode()).decode().strip()
        decoded = subprocess.check_output(['base64', '-d'], input=encoded.encode()).decode()
        end_time = time.time()
        
        # Should complete quickly (under 1 second for 1000 lines)
        self.assertLess(end_time - start_time, 1.0)
        self.assertEqual(large_content, decoded)
    
    def test_multiple_pane_commands(self):
        """Test handling multiple simultaneous pane operations"""
        simulator = phi3_module.Phi3Simulator()
        
        commands = [
            "Run ls in the left pane",
            "Execute pwd in the top pane", 
            "Run echo 'test' in the bottom pane"
        ]
        
        results = []
        for cmd in commands:
            parsed = simulator.parse_natural_language(cmd)
            tmux_cmd = simulator.generate_tmux_command(parsed)
            results.append((parsed, tmux_cmd))
        
        # Verify all commands were processed correctly
        self.assertEqual(len(results), 3)
        panes = [result[0]['pane'] for result in results]
        self.assertEqual(set(panes), {'left', 'top', 'bottom'})

if __name__ == '__main__':
    # Create a test suite
    unittest.main(verbosity=2)
