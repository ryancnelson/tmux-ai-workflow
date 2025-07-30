#!/usr/bin/env python3

"""
phi3-simulator.py - Simulates what phi3 would do for command parsing and output cleaning
This demonstrates the tactical layer that would save Claude tokens
"""

import json
import re
import subprocess
import sys
from typing import Dict, Tuple

class Phi3Simulator:
    """Simulates phi3's role in the AI handoff pattern"""
    
    def __init__(self):
        self.pane_mapping = {
            'left': 'ryan-workflow:0.0',
            'top': 'ryan-workflow:0.1', 
            'bottom': 'ryan-workflow:0.2'
        }
        
        self.timeout_defaults = {
            'quick': 10,      # ls, cd, etc
            'build': 300,     # make, configure
            'test': 600,      # test suites
            'long': 1800      # complex builds
        }
    
    def parse_natural_language(self, request: str) -> Dict:
        """Parse natural language into structured command info"""
        request_lower = request.lower()
        
        # Extract pane
        pane = 'left'  # default
        if 'top pane' in request_lower or 'in top' in request_lower:
            pane = 'top'
        elif 'bottom pane' in request_lower or 'in bottom' in request_lower:
            pane = 'bottom'
        elif 'left pane' in request_lower or 'in left' in request_lower:
            pane = 'left'
        
        # Extract command
        command = ""
        for verb in ['run', 'execute']:
            if f'{verb} ' in request_lower:
                # Extract everything after verb
                run_match = re.search(rf'{verb}\s+[\'"`]([^\'"`]+)[\'"`]', request, re.IGNORECASE)
                if run_match:
                    command = run_match.group(1)
                    break
                else:
                    # Try without quotes
                    run_match = re.search(rf'{verb}\s+(.+?)(?:\s+in\s+|$)', request, re.IGNORECASE)
                    if run_match:
                        command = run_match.group(1).strip()
                        break
        
        # Determine timeout category
        timeout_category = 'quick'
        if any(word in command.lower() for word in ['make', 'configure', 'cmake', 'build']):
            timeout_category = 'build'
        elif any(word in command.lower() for word in ['test', 'check']):
            timeout_category = 'test'
        elif any(word in command.lower() for word in ['compile', 'link']):
            timeout_category = 'long'
        
        return {
            'original_request': request,
            'pane': pane,
            'command': command,
            'timeout_category': timeout_category,
            'timeout_seconds': self.timeout_defaults[timeout_category]
        }
    
    def generate_tmux_command(self, parsed: Dict) -> str:
        """Convert parsed request into tmux command"""
        pane_target = self.pane_mapping[parsed['pane']]
        command = parsed['command']
        timeout = parsed['timeout_seconds']
        
        # Add completion marker for commands expected to finish
        if parsed['timeout_category'] != 'quick':
            command_with_marker = f"timeout {timeout} {command} ; echo ; echo 'program execution done. exit_code=$?'"
        else:
            command_with_marker = f"{command} ; echo ; echo 'program execution done. exit_code=$?'"
        
        return f'tmux send-keys -t {pane_target} "{command_with_marker}" Enter'
    
    def clean_tmux_output(self, raw_output: str) -> Dict:
        """Clean raw tmux output into structured results"""
        lines = raw_output.strip().split('\n')
        
        # Look for completion marker
        completion_match = None
        for line in reversed(lines):
            if 'program execution done. exit_code=' in line:
                match = re.search(r'exit_code=(\d+)', line)
                if match:
                    completion_match = int(match.group(1))
                break
        
        # Remove prompt lines and completion markers
        cleaned_lines = []
        for line in lines:
            if not line.startswith('ryan-workflow-bash:') and \
               'program execution done' not in line and \
               line.strip():
                cleaned_lines.append(line)
        
        # Classify output
        output_type = 'unknown'
        if completion_match is not None:
            if completion_match == 0:
                output_type = 'success'
            elif completion_match == 124:
                output_type = 'timeout'
            else:
                output_type = 'error'
        
        # Extract key information
        summary = ""
        if output_type == 'success':
            summary = f"Command completed successfully"
        elif output_type == 'timeout':
            summary = f"Command timed out"
        elif output_type == 'error':
            # Try to extract error info
            error_indicators = ['error:', 'failed', 'cannot', 'permission denied']
            for line in cleaned_lines[-10:]:  # Check last 10 lines
                if any(indicator in line.lower() for indicator in error_indicators):
                    summary = f"Error: {line.strip()}"
                    break
            if not summary:
                summary = f"Command failed with exit code {completion_match}"
        
        return {
            'output_type': output_type,
            'exit_code': completion_match,
            'summary': summary,
            'cleaned_output': '\n'.join(cleaned_lines),
            'line_count': len(cleaned_lines)
        }

def main():
    if len(sys.argv) < 2:
        print("Usage: ./phi3-simulator.py <natural_language_request>")
        print("       ./phi3-simulator.py --clean <raw_output_file>")
        print()
        print("Examples:")
        print('  ./phi3-simulator.py "Run make clean in the top pane"')
        print('  ./phi3-simulator.py "Execute ./configure --prefix=/tmp in left pane"')
        print('  ./phi3-simulator.py --clean output.txt')
        return
    
    simulator = Phi3Simulator()
    
    if sys.argv[1] == '--clean':
        # Clean output mode
        if len(sys.argv) < 3:
            print("Error: --clean requires a file argument")
            return
        
        try:
            with open(sys.argv[2], 'r') as f:
                raw_output = f.read()
        except FileNotFoundError:
            print(f"Error: File {sys.argv[2]} not found")
            return
        
        print("=== PHI3 OUTPUT CLEANING ===")
        cleaned = simulator.clean_tmux_output(raw_output)
        print(json.dumps(cleaned, indent=2))
        
    else:
        # Parse natural language mode
        request = ' '.join(sys.argv[1:])
        
        print("=== PHI3 NATURAL LANGUAGE PARSING ===")
        print(f"Input: {request}")
        print()
        
        # Step 1: Parse natural language
        parsed = simulator.parse_natural_language(request)
        print("Parsed structure:")
        print(json.dumps(parsed, indent=2))
        print()
        
        # Step 2: Generate tmux command
        tmux_cmd = simulator.generate_tmux_command(parsed)
        print("Generated tmux command:")
        print(tmux_cmd)
        print()
        
        print("=== WHAT HAPPENS NEXT ===")
        print("1. This tmux command would be executed")
        print("2. phi3 would monitor the output")
        print("3. phi3 would clean the results using clean_tmux_output()")
        print("4. Claude would receive clean, structured results")

if __name__ == '__main__':
    main()
