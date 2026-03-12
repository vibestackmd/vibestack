#!/usr/bin/env bash
# Plays a chime and announces the project name when Claude finishes
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

# Get the project name from cwd (parent folder name)
project=$(echo "$input" | "$PYTHON" -c "
import sys, json, os
cwd = json.load(sys.stdin).get('cwd', '')
print(os.path.basename(cwd))
" 2>/dev/null)

# Play a notification sound (best-effort)
case "$(uname -s 2>/dev/null)" in
  Darwin)
    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
    [ -n "$project" ] && say "Finished ${project} tasks" 2>/dev/null &
    ;;
  Linux)
    # Try common Linux sound players
    if command -v paplay >/dev/null 2>&1; then
      paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
    elif command -v aplay >/dev/null 2>&1; then
      aplay /usr/share/sounds/sound-icons/glass-water-1.wav 2>/dev/null &
    fi
    # Try text-to-speech
    if [ -n "$project" ]; then
      if command -v spd-say >/dev/null 2>&1; then
        spd-say "Finished ${project} tasks" 2>/dev/null &
      elif command -v espeak >/dev/null 2>&1; then
        espeak "Finished ${project} tasks" 2>/dev/null &
      fi
    fi
    ;;
  *)
    # Windows (Git Bash/MSYS2/WSL) or unknown — try PowerShell as a fallback
    if command -v powershell.exe >/dev/null 2>&1; then
      powershell.exe -NoProfile -Command "[System.Media.SystemSounds]::Asterisk.Play()" 2>/dev/null &
    fi
    ;;
esac
