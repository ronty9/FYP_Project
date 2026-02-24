#!/usr/bin/env bash
# Start the Pet AI backend server.
# Usage:  ./backend/start.sh
#
# Prerequisites (first run only):
#   cd backend && pip install -r requirements.txt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

echo "Starting Pet Breed AI server on http://0.0.0.0:8000"
echo "Press Ctrl+C to stop."
echo ""
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
