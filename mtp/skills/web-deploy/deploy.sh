#!/bin/bash
set -e
MSG="${1:-update site}"
WORKSPACE="/home/node/.openclaw/workspace"
cd "$WORKSPACE"
git add sites/web/
git diff --cached --quiet && echo "Nothing to deploy." && exit 0
git commit -m "web: $MSG"
git push
echo "✅ Deployed! Vercel will build automatically."
