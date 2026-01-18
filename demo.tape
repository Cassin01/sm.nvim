# sm.nvim Demo - VHS Tape File
# Run with: vhs demo.tape

# Output settings
Output assets/demo.gif
# Set FontSize 16
Set Width 2000
Set Height 1000
Set Theme "Catppuccin Mocha"
Set Shell "bash"
# Set FontFamily "JetBrains Mono"
Set FontFamily "Hack Nerd Font"
Set Padding 20
Set Framerate 30
Set PlaybackSpeed 1

# Start Neovim with sm.nvim loaded
Type "nvim -c 'set laststatus=2'"
Enter
Sleep 1s

# Scene 1: Create memo B (project ideas) first
Type ":SmNew Project Ideas"
Enter
Sleep 2s

# Move to bottom
Type "G"
Sleep 500ms

Type "o"
Type@100ms "## Features"
Enter
Enter
Type@80ms "- Feature A"
Enter
Type@80ms "- Feature B"
Escape
Type ":wq"
Enter
Sleep 1s

# Scene 2: Create memo A (meeting notes) with link to project-ideas
Type ":SmNew Meeting Notes"
Enter
Sleep 2s

# Move to bottom
Type "G"
Sleep 500ms

Type "o"
Sleep 300ms
Type@100ms "## Today's Meeting"
Enter
Enter
Type@80ms "Discussed project timeline and next steps."
Enter
Enter
Type@80ms "Related: [[project-ideas]]"
Escape
Sleep 1.5s

# Scene 3: Save memo A
Type ":w"
Enter
Sleep 500ms

# Scene 4: Move cursor to link and follow with gf
Type "f["
Sleep 500ms
Type "gf"
Sleep 2s

# Scene 5: Add a tag
Type ":SmAddTag work"
Enter
Sleep 1.5s

# Scene 6: Close window
Type ":q"
Enter
Sleep 500ms

# Scene 6: Close window
Type ":q"
Enter
Sleep 500ms

# Demonstrate memo picker
Type "\xl"
Sleep 2s
Type "aproject"
Sleep 500ms
Enter
Sleep 1.5s

# End
Type ":q!"
Enter
Sleep 500ms

