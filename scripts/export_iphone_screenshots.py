#!/usr/bin/env python3
"""Export XCTAttachment PNGs using Xcode 15's xcresulttool for visual review."""
import json
from pathlib import Path
import subprocess
import sys

result = sys.argv[1]
output = Path(sys.argv[2])
output.mkdir(parents=True, exist_ok=True)
seen = set()

def read(identifier=None):
    cmd = ['xcrun', 'xcresulttool', 'get', '--path', result, '--format', 'json']
    if identifier: cmd += ['--id', identifier]
    return json.loads(subprocess.check_output(cmd))

def visit(value):
    if isinstance(value, list):
        for child in value: visit(child)
    elif isinstance(value, dict):
        payload = value.get('payloadRef', {}).get('id', {}).get('_value')
        name = value.get('name', {}).get('_value', '')
        if payload and value.get('uniformTypeIdentifier', {}).get('_value') == 'public.png':
            clean = ''.join(c if c.isalnum() or c in '-_' else '_' for c in name)[:100]
            path = output / (clean + '-' + str(len(list(output.glob('*.png')))) + '.png')
            subprocess.run(['xcrun', 'xcresulttool', 'export', '--path', result, '--id', payload, '--type', 'file', '--output-path', str(path)], check=True)
        for key, child in value.items():
            if key in ('testsRef', 'summaryRef'):
                identifier = child.get('id', {}).get('_value')
                if identifier and identifier not in seen:
                    seen.add(identifier); visit(read(identifier))
            else: visit(child)

visit(read())
print('Exported', len(list(output.glob('*.png'))), 'iPhone screenshots.')
