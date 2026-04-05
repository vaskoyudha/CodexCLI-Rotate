# codex-rotate demo — recorded with charmbracelet/vhs
# Install VHS: https://github.com/charmbracelet/vhs
# Run: vhs demo.tape

Output demo.gif
Output demo.mp4

# Terminal styling
Set FontSize 20
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Catppuccin Frappe"
Set WindowBar Colorful
Set TypingSpeed 60ms

# Clean slate
Hide
Type "export HOME=$(mktemp -d) && export PATH=$PWD/bin:$PATH"
Enter
Type "codex-rotate init 2>/dev/null"
Enter
Sleep 500ms
Show

# Title
Type "# codex-rotate — Multi-account manager for Codex CLI"
Sleep 1s
Enter
Sleep 500ms

# Show help
Type "codex-rotate help"
Sleep 500ms
Enter
Sleep 3s

# List accounts (demo with pre-seeded data)
Type "codex-rotate list"
Sleep 500ms
Enter
Sleep 2s

# Check quota
Type "codex-rotate quota"
Sleep 500ms
Enter
Sleep 3s

# Check email
Type "codex-rotate email"
Sleep 500ms
Enter
Sleep 2s

# Show status dashboard
Type "codex-rotate status"
Sleep 500ms
Enter
Sleep 3s

# Run doctor
Type "codex-rotate doctor"
Sleep 500ms
Enter
Sleep 3s

# Run with auto-rotation
Type "codex-rotate auto exec \"Write a snake game in Python\""
Sleep 500ms
Enter
Sleep 4s

# Final pause
Sleep 3s
