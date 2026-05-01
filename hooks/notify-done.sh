#!/usr/bin/env bash
# Plays a subtle sound when Claude finishes
# Works on macOS, Linux, and degrades gracefully elsewhere

# Read the JSON input from stdin
input=$(cat)

# Find a working Python interpreter
find_python() {
  for cmd in python3 python; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "$cmd"
      return
    fi
  done
}

PYTHON=$(find_python)
if [ -z "$PYTHON" ]; then
  exit 0
fi

# Check if this is a stop hook already active (prevent loops)
active=$(echo "$input" | "$PYTHON" -c "import sys,json; print(json.load(sys.stdin).get('stop_hook_active', False))" 2>/dev/null)
if [ "$active" = "True" ]; then
  exit 0
fi

# Play a notification sound (best-effort, no voice)
case "$(uname -s 2>/dev/null)" in
  Darwin)
    afplay /System/Library/Sounds/Submarine.aiff 2>/dev/null &
    ;;
  Linux)
    if command -v paplay >/dev/null 2>&1; then
      paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
    elif command -v aplay >/dev/null 2>&1; then
      aplay /usr/share/sounds/sound-icons/glass-water-1.wav 2>/dev/null &
    fi
    ;;
  *)
    if command -v powershell.exe >/dev/null 2>&1; then
      powershell.exe -NoProfile -Command "[System.Media.SystemSounds]::Asterisk.Play()" 2>/dev/null &
    fi
    ;;
esac
