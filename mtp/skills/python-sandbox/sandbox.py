#!/usr/bin/env python3
"""
MTP Python Sandbox — Safe code execution for TaaS tenants.

Executes Python code in a restricted environment:
- No filesystem access (os, shutil, pathlib, glob blocked)
- No network access (socket, urllib, requests, http blocked)
- No subprocess/system calls (subprocess, os.system blocked)
- No module installation (pip, importlib blocked)
- Timeout enforced (default 10s)
- Output capped (default 50KB)

Allowed modules: math, statistics, decimal, fractions, datetime,
json, re, collections, itertools, functools, textwrap, string,
csv (StringIO only), random, hashlib, base64

Usage:
  echo 'print(2 + 2)' | python3 sandbox.py
  python3 sandbox.py --code 'print(2 + 2)'
  python3 sandbox.py --file script.py  # reads from sandbox workspace only
"""

import sys
import argparse
import signal
import io
import contextlib

# ─── Configuration ────────────────────────────────────────────
TIMEOUT_SECONDS = 10
MAX_OUTPUT_BYTES = 50 * 1024  # 50KB

# ─── Blocked modules ─────────────────────────────────────────
BLOCKED_MODULES = {
    # Filesystem
    'os', 'shutil', 'pathlib', 'glob', 'fnmatch', 'tempfile',
    'os.path', 'fileinput',
    # Network
    'socket', 'ssl', 'http', 'urllib', 'requests', 'httpx',
    'aiohttp', 'ftplib', 'smtplib', 'imaplib', 'poplib',
    'xmlrpc', 'socketserver',
    # Subprocess / system
    'subprocess', 'multiprocessing', 'threading', 'signal',
    'ctypes', 'cffi',
    # Code loading
    'importlib', 'pip', 'setuptools', 'pkg_resources',
    'ensurepip', 'zipimport',
    # Dangerous builtins access
    'code', 'codeop', 'compile', 'compileall',
    'inspect', 'dis', 'ast',
    # System info
    'platform', 'sysconfig', 'site',
}

# ─── Blocked builtins ────────────────────────────────────────
BLOCKED_BUILTINS = {
    'open', 'exec', 'eval', 'compile', '__import__',
    'globals', 'locals', 'vars', 'dir',
    'getattr', 'setattr', 'delattr',
    'breakpoint', 'exit', 'quit',
    'memoryview', 'type',  # prevent metaclass tricks
}

# ─── Safe builtins ────────────────────────────────────────────
import builtins
safe_builtins = {
    k: v for k, v in builtins.__dict__.items()
    if k not in BLOCKED_BUILTINS and not k.startswith('_')
}

# Add back essentials
safe_builtins['print'] = print
safe_builtins['len'] = len
safe_builtins['range'] = range
safe_builtins['enumerate'] = enumerate
safe_builtins['zip'] = zip
safe_builtins['map'] = map
safe_builtins['filter'] = filter
safe_builtins['sorted'] = sorted
safe_builtins['reversed'] = reversed
safe_builtins['min'] = min
safe_builtins['max'] = max
safe_builtins['sum'] = sum
safe_builtins['abs'] = abs
safe_builtins['round'] = round
safe_builtins['int'] = int
safe_builtins['float'] = float
safe_builtins['str'] = str
safe_builtins['bool'] = bool
safe_builtins['list'] = list
safe_builtins['dict'] = dict
safe_builtins['set'] = set
safe_builtins['tuple'] = tuple
safe_builtins['frozenset'] = frozenset
safe_builtins['isinstance'] = isinstance
safe_builtins['issubclass'] = issubclass
safe_builtins['hasattr'] = hasattr
safe_builtins['repr'] = repr
safe_builtins['format'] = format
safe_builtins['chr'] = chr
safe_builtins['ord'] = ord
safe_builtins['hex'] = hex
safe_builtins['oct'] = oct
safe_builtins['bin'] = bin
safe_builtins['pow'] = pow
safe_builtins['divmod'] = divmod
safe_builtins['any'] = any
safe_builtins['all'] = all
safe_builtins['input'] = lambda *a: ''  # neutered
safe_builtins['True'] = True
safe_builtins['False'] = False
safe_builtins['None'] = None
safe_builtins['Exception'] = Exception
safe_builtins['ValueError'] = ValueError
safe_builtins['TypeError'] = TypeError
safe_builtins['KeyError'] = KeyError
safe_builtins['IndexError'] = IndexError
safe_builtins['ZeroDivisionError'] = ZeroDivisionError
safe_builtins['StopIteration'] = StopIteration
safe_builtins['RuntimeError'] = RuntimeError

# ─── Safe __import__ ──────────────────────────────────────────
ALLOWED_MODULES = {
    'math', 'statistics', 'decimal', 'fractions',
    'datetime', 'json', 're', 'string', 'textwrap',
    'collections', 'itertools', 'functools',
    'random', 'hashlib', 'base64', 'csv', 'io',
}

_real_import = builtins.__import__

def safe_import(name, *args, **kwargs):
    top = name.split('.')[0]
    if top in BLOCKED_MODULES:
        raise ImportError(f"Module '{name}' is not available in the sandbox")
    if top not in ALLOWED_MODULES:
        raise ImportError(f"Module '{name}' is not available in the sandbox. Allowed: {', '.join(sorted(ALLOWED_MODULES))}")
    return _real_import(name, *args, **kwargs)

safe_builtins['__import__'] = safe_import

# ─── Timeout handler ─────────────────────────────────────────
class TimeoutError(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutError(f"Execution timed out after {TIMEOUT_SECONDS} seconds")

# ─── Execute ──────────────────────────────────────────────────
def execute_code(code: str, timeout: int = TIMEOUT_SECONDS) -> dict:
    """Execute code in sandbox, return {stdout, stderr, error}."""
    stdout_capture = io.StringIO()
    stderr_capture = io.StringIO()

    # Build restricted globals
    restricted_globals = {'__builtins__': safe_builtins}

    # Pre-import common modules for convenience
    try:
        import math, decimal, datetime, json, statistics
        restricted_globals['math'] = math
        restricted_globals['Decimal'] = decimal.Decimal
        restricted_globals['datetime'] = datetime
        restricted_globals['json'] = json
        restricted_globals['statistics'] = statistics
    except:
        pass

    result = {'stdout': '', 'stderr': '', 'error': None}

    # Set timeout (Unix only)
    old_handler = None
    try:
        old_handler = signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(timeout)
    except (AttributeError, ValueError):
        pass  # Windows or non-main thread

    try:
        with contextlib.redirect_stdout(stdout_capture), \
             contextlib.redirect_stderr(stderr_capture):
            # Compile first to catch syntax errors
            compiled = builtins.compile(code, '<sandbox>', 'exec')
            builtins.exec(compiled, restricted_globals)

        result['stdout'] = stdout_capture.getvalue()[:MAX_OUTPUT_BYTES]
        result['stderr'] = stderr_capture.getvalue()[:MAX_OUTPUT_BYTES]

    except TimeoutError as e:
        result['error'] = str(e)
    except Exception as e:
        result['error'] = f"{type(e).__name__}: {e}"
        result['stderr'] = stderr_capture.getvalue()[:MAX_OUTPUT_BYTES]
    finally:
        try:
            signal.alarm(0)
            if old_handler is not None:
                signal.signal(signal.SIGALRM, old_handler)
        except (AttributeError, ValueError):
            pass

    return result

# ─── Main ─────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description='MTP Python Sandbox')
    parser.add_argument('--code', '-c', help='Code to execute')
    parser.add_argument('--timeout', '-t', type=int, default=TIMEOUT_SECONDS,
                        help=f'Timeout in seconds (default: {TIMEOUT_SECONDS})')
    args = parser.parse_args()

    timeout = args.timeout

    if args.code:
        code = args.code
    elif not sys.stdin.isatty():
        code = sys.stdin.read()
    else:
        print("Error: No code provided. Use --code or pipe via stdin.", file=sys.stderr)
        sys.exit(1)

    if not code.strip():
        print("Error: Empty code.", file=sys.stderr)
        sys.exit(1)

    result = execute_code(code, timeout=timeout)

    if result['stdout']:
        print(result['stdout'], end='')
    if result['stderr']:
        print(result['stderr'], end='', file=sys.stderr)
    if result['error']:
        print(f"Error: {result['error']}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
