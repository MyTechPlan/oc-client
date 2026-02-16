# Python Sandbox — Safe Code Execution

Execute Python code safely without filesystem, network, or system access.

## When to use

Use this skill when you need to:
- Do math calculations (sums, percentages, IVA, margins, conversions)
- Analyze data (lists, statistics, comparisons)
- Format or transform text/data
- Generate tables or structured output
- Any computation that needs verified results (not LLM estimation)

## How to use

Run code via exec tool with the sandbox script:

```bash
echo 'print(100 * 1.21)' | python3 /home/node/.openclaw/workspace/skills/python-sandbox/sandbox.py
```

Or with --code flag:

```bash
python3 /home/node/.openclaw/workspace/skills/python-sandbox/sandbox.py --code 'print(100 * 1.21)'
```

For multi-line code, use stdin:

```bash
python3 /home/node/.openclaw/workspace/skills/python-sandbox/sandbox.py --code '
prices = [100, 250, 75, 320]
iva = 0.21
total = sum(p * (1 + iva) for p in prices)
print(f"Subtotal: {sum(prices):.2f}€")
print(f"IVA (21%): {sum(prices) * iva:.2f}€")
print(f"Total: {total:.2f}€")
'
```

## Available modules

math, statistics, decimal, fractions, datetime, json, re, string,
textwrap, collections, itertools, functools, random, hashlib, base64, csv, io

## Blocked (security)

- **Filesystem:** os, shutil, pathlib, glob, open()
- **Network:** socket, urllib, requests, http
- **System:** subprocess, multiprocessing, exec(), eval()
- **Code loading:** importlib, pip, __import__ (restricted)

## Limits

- **Timeout:** 10 seconds (configurable with --timeout)
- **Output:** 50KB max
- **No persistent state** between executions
