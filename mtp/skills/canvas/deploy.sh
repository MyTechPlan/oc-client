#!/bin/bash
set -e
MSG="${1:-update canvas}"
WORKSPACE="/home/node/.openclaw/workspace"
cd "$WORKSPACE"
git add sites/canvas/
git diff --cached --quiet && echo "Nothing to deploy." && exit 0
git commit -m "canvas: $MSG"
git push
echo "✅ Deployed! Vercel will build automatically."
