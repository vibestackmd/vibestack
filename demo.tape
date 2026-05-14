# VibeStack demo tape
# Generates the README hero GIF.  Run:  vhs demo.tape
# Install vhs first:  https://github.com/charmbracelet/vhs   (brew install vhs)
#
# How it works: the Hide block exports the non-interactive flags and runs the
# installer once off-camera, which warms the marketplace cache. The on-camera
# install is then a fast idempotent re-run showing real output, no faked
# terminal text. install.sh is safe to re-run, so regenerating the GIF never
# leaves the machine in a bad state.
#
# Tuning: if the on-camera install scrolls too fast or too slow, adjust the
# `Sleep` right after it. If "Catppuccin Mocha" is not available in your vhs
# build, swap `Set Theme` for any theme from `vhs themes`.

Output site/public/demo.gif

Require curl
Require claude

Set Shell "bash"
Set FontSize 18
Set Width 1280
Set Height 760
Set Padding 28
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms

# --- off-camera: go non-interactive, warm the marketplace cache ---
Hide
Type "export SKIP_DEVTOOLS=1 NONINTERACTIVE=1"
Enter
Type "curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash >/dev/null 2>&1"
Enter
Sleep 45s
Type "clear"
Enter
Show

# --- the pitch ---
Type "# One command. Your conventions, every project, taught to Claude."
Sleep 500ms
Enter
Sleep 900ms

# --- install (fast: cache warmed by the Hide block above) ---
Type "curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash"
Sleep 400ms
Enter
Sleep 7s

# --- the payoff: 11 skills and the Stop hook, all wired up ---
Type "claude plugin details vibestack@vibestackmd-vibestack"
Sleep 400ms
Enter
Sleep 4500ms

# --- close ---
Type "# Then run /vibestack in any project to scaffold it."
Sleep 400ms
Enter
Sleep 2s
