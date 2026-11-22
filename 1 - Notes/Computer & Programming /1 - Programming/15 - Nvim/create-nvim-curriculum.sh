
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_pack() {
    local pack="$1"
    shift

    local directory="$ROOT/$pack"
    mkdir -p "$directory"

    local index=0
    local note
    local filename
    local filepath

    for note in "$@"; do
        # Filesystem-safe filenames
        note="${note//\// - }"
        note="${note//:/ -}"

        printf -v filename "%02d - %s.md" "$index" "$note"
        filepath="$directory/$filename"

        if [[ ! -e "$filepath" ]]; then
            printf '[[Neovim]]\n[[LazyVim]]\n' > "$filepath"
            echo "[CREATED] $pack/$filename"
        else
            echo "[SKIPPED] $pack/$filename"
        fi

        ((index += 1))
    done
}

# ==================================================
# PACK 1 - TERMINAL AND VIM FUNDAMENTALS
# ==================================================

create_pack "Pack 1 - Terminal and Vim Fundamentals" \
    "What is Vim and Neovim" \
    "Why Use Modal Editing" \
    "Vim Modes" \
    "Normal Mode" \
    "Insert Mode" \
    "Visual Mode" \
    "Visual Line Mode" \
    "Visual Block Mode" \
    "Command Mode" \
    "Entering and Leaving Modes" \
    "Opening Files from Terminal" \
    "Basic Navigation" \
    "Character and Word Motions" \
    "Line Navigation" \
    "File Navigation" \
    "Scrolling" \
    "Basic Editing Commands" \
    "Deleting Text" \
    "Changing Text" \
    "Copying and Pasting" \
    "Undo and Redo" \
    "Search and Replace" \
    "Buffers" \
    "Windows" \
    "Splits" \
    "Tabs" \
    "Registers" \
    "Macros" \
    "Marks and Jumps" \
    "Text Objects" \
    "Vim Motions and Operators" \
    "Vim Help System"

# ==================================================
# PACK 2 - NEOVIM FUNDAMENTALS
# ==================================================

create_pack "Pack 2 - Neovim Fundamentals" \
    "Neovim Architecture" \
    "Neovim vs Vim" \
    "Neovim Runtime Paths" \
    "Neovim Configuration Directory" \
    "init.lua" \
    "Neovim Configuration Structure" \
    "Lua Configuration Basics" \
    "vim.opt" \
    "vim.o and vim.bo" \
    "vim.g" \
    "Setting Editor Options" \
    "Keymaps" \
    "vim.keymap.set" \
    "Keymap Modes" \
    "Leader Key" \
    "Local Leader Key" \
    "Custom Commands" \
    "User Commands" \
    "Autocommands" \
    "Autocommand Groups" \
    "User Events" \
    "Neovim Notifications" \
    "Command Line Interface" \
    "Neovim Built-in Terminal" \
    "Neovim Health Checks" \
    "Neovim Documentation"

# ==================================================
# PACK 3 - LUA FOR NEOVIM
# ==================================================

create_pack "Pack 3 - Lua for Neovim" \
    "Introduction to Lua" \
    "Lua Variables and Data Types" \
    "Lua Operators" \
    "Lua Conditional Statements" \
    "Lua Loops" \
    "Lua Functions" \
    "Lua Tables" \
    "Lua Table Manipulation" \
    "Lua Iteration" \
    "Lua Scope and Closures" \
    "Lua Modules" \
    "require and Module Loading" \
    "Lua Error Handling" \
    "Lua Metatables" \
    "Lua Coroutines" \
    "Lua Patterns" \
    "Lua Standard Libraries" \
    "Neovim Lua Runtime" \
    "vim Namespace" \
    "vim.api" \
    "vim.fn" \
    "vim.cmd" \
    "vim.keymap" \
    "vim.loop and vim.uv" \
    "Working with Buffers Using Lua" \
    "Working with Windows Using Lua" \
    "Working with Autocommands Using Lua"

# ==================================================
# PACK 4 - PLUGIN MANAGEMENT
# ==================================================

create_pack "Pack 4 - Plugin Management" \
    "Neovim Plugin Ecosystem" \
    "What is a Neovim Plugin" \
    "Plugin Managers" \
    "Lazy.nvim Introduction" \
    "Installing Lazy.nvim" \
    "Lazy.nvim Configuration" \
    "Plugin Specifications" \
    "Plugin Repository Specifications" \
    "Plugin Options" \
    "Plugin Dependencies" \
    "Plugin Loading" \
    "Lazy Loading" \
    "Event-Based Loading" \
    "Command-Based Loading" \
    "Key-Based Loading" \
    "Filetype-Based Loading" \
    "Plugin Configuration Functions" \
    "Plugin Versioning" \
    "Lockfiles" \
    "Lazy.nvim Commands" \
    "Updating Plugins" \
    "Troubleshooting Plugins"

# ==================================================
# PACK 5 - LAZYVIM FUNDAMENTALS
# ==================================================

create_pack "Pack 5 - LazyVim Fundamentals" \
    "What is LazyVim" \
    "LazyVim Architecture" \
    "LazyVim vs Lazy.nvim" \
    "LazyVim Installation" \
    "LazyVim Directory Structure" \
    "LazyVim Configuration Files" \
    "lua/config/options.lua" \
    "lua/config/keymaps.lua" \
    "lua/config/autocmds.lua" \
    "lua/config/lazy.lua" \
    "lua/plugins Directory" \
    "Custom Plugin Specifications" \
    "Overriding Default Plugins" \
    "Extending Plugin Configuration" \
    "LazyVim Defaults" \
    "LazyVim Extras" \
    "Enabling and Disabling Extras" \
    "LazyVim Keymaps" \
    "LazyVim Commands" \
    "LazyVim Dashboard" \
    "LazyVim Updates" \
    "LazyVim Troubleshooting"

# ==================================================
# PACK 6 - EDITING AND NAVIGATION
# ==================================================

create_pack "Pack 6 - Editing and Navigation" \
    "Which-Key" \
    "Telescope Introduction" \
    "Telescope File Search" \
    "Telescope Live Grep" \
    "Telescope Buffers" \
    "Telescope Diagnostics" \
    "Telescope Extensions" \
    "Oil.nvim" \
    "File Explorer Workflows" \
    "Nvim-Tree and Neo-tree" \
    "Nvim-Treesitter" \
    "Treesitter Parsers" \
    "Treesitter Syntax Highlighting" \
    "Treesitter Text Objects" \
    "Treesitter Incremental Selection" \
    "Surround Editing" \
    "Flash.nvim" \
    "Leap Navigation" \
    "Search and Navigation Workflows" \
    "Multiple Cursors" \
    "Indentation and Formatting" \
    "Folding" \
    "Code Navigation"

# ==================================================
# PACK 7 - LSP AND CODE INTELLIGENCE
# ==================================================

create_pack "Pack 7 - LSP and Code Intelligence" \
    "Language Server Protocol" \
    "How LSP Works" \
    "Neovim LSP Client" \
    "LSP Configuration" \
    "Mason.nvim" \
    "Mason LSPConfig" \
    "Installing Language Servers" \
    "LSP Capabilities" \
    "LSP Attach Lifecycle" \
    "Go to Definition" \
    "Go to Declaration" \
    "Go to References" \
    "Hover Documentation" \
    "Rename Symbols" \
    "Code Actions" \
    "Diagnostics" \
    "Diagnostic Signs" \
    "Diagnostic Navigation" \
    "Completion Fundamentals" \
    "nvim-cmp and Completion" \
    "LuaSnip" \
    "Snippet Management" \
    "Formatting with Conform.nvim" \
    "Linting with nvim-lint" \
    "LSP Troubleshooting"

# ==================================================
# PACK 8 - DEVELOPMENT WORKFLOWS
# ==================================================

create_pack "Pack 8 - Development Workflows" \
    "Java Development in Neovim" \
    "JDTLS Introduction" \
    "Java Language Server Configuration" \
    "Java Project Import" \
    "Java Code Navigation" \
    "Java Refactoring" \
    "Java Debugging Integration" \
    "Spring Boot Development Workflow" \
    "Maven Integration" \
    "Gradle Integration" \
    "Running Java Applications" \
    "JavaScript Development in Neovim" \
    "TypeScript Language Server" \
    "JavaScript Completion and Diagnostics" \
    "Node.js Development Workflow" \
    "PostgreSQL and SQL Development" \
    "SQL Language Server" \
    "Database Client Plugins" \
    "Bash Development in Neovim" \
    "YAML and JSON Support" \
    "Dockerfile Support" \
    "Git and Configuration File Editing"

# ==================================================
# PACK 9 - GIT INTEGRATION
# ==================================================

create_pack "Pack 9 - Git Integration" \
    "Git Integration in Neovim" \
    "Gitsigns.nvim" \
    "Git Signs and Hunk Navigation" \
    "Stage and Reset Hunks" \
    "Git Blame" \
    "Git Diff Workflow" \
    "Diffview.nvim" \
    "Lazygit" \
    "Lazygit Integration" \
    "Git Branch Management" \
    "Merge Conflict Resolution" \
    "Git Commit Workflow" \
    "Git Status and History"

# ==================================================
# PACK 10 - DEBUGGING AND TESTING
# ==================================================

create_pack "Pack 10 - Debugging and Testing" \
    "Debug Adapter Protocol" \
    "nvim-dap Introduction" \
    "DAP Configuration" \
    "DAP Adapters" \
    "Breakpoints" \
    "Stepping Through Code" \
    "Variables and Watch Expressions" \
    "Debug Console" \
    "Java Debugging with DAP" \
    "JavaScript Debugging with DAP" \
    "Test Runner Integration" \
    "Neotest" \
    "Running Tests Inside Neovim" \
    "Test Result Navigation" \
    "Debugging Configuration Issues"

# ==================================================
# PACK 11 - CUSTOMIZATION
# ==================================================

create_pack "Pack 11 - Customization" \
    "Colorschemes" \
    "TokyoNight Theme" \
    "Catppuccin Theme" \
    "Theme Configuration" \
    "Statuslines" \
    "Lualine" \
    "Bufferline" \
    "Icons and Nerd Fonts" \
    "Snippets and Templates" \
    "Custom Keymaps" \
    "Custom Commands" \
    "Custom Autocommands" \
    "Custom User Interfaces" \
    "Floating Windows" \
    "Custom Notifications" \
    "Custom Plugin Development" \
    "Writing a Neovim Plugin" \
    "Plugin Configuration Best Practices"

# ==================================================
# PACK 12 - ADVANCED NEOVIM
# ==================================================

create_pack "Pack 12 - Advanced Neovim" \
    "Neovim Event System" \
    "Advanced Autocommands" \
    "Neovim API Architecture" \
    "Extmarks" \
    "Namespaces" \
    "Decorations and Virtual Text" \
    "Floating Windows API" \
    "Terminal Job Control" \
    "RPC and Remote Plugins" \
    "Neovim Performance Optimization" \
    "Profiling Startup Time" \
    "Plugin Performance Analysis" \
    "Sessions and Workspaces" \
    "Persistent Undo" \
    "Swap and Backup Files" \
    "Advanced Registers and Macros" \
    "Neovim State Management" \
    "Headless Neovim" \
    "Neovim Scripting and Automation"

# ==================================================
# PACK 13 - DEBIAN 13 AND SYSTEM INTEGRATION
# ==================================================

create_pack "Pack 13 - Debian 13 and System Integration" \
    "Installing Neovim on Debian 13" \
    "Neovim Version Management" \
    "Neovim Dependencies" \
    "Git Integration on Debian" \
    "Clipboard Integration with Debian" \
    "X11 and Wayland Clipboard" \
    "xclip and xsel" \
    "wl-clipboard" \
    "Nerd Fonts Installation" \
    "Terminal Emulator Configuration" \
    "True Color Support" \
    "Shell Integration" \
    "Environment Variables" \
    "PATH and Executable Resolution" \
    "External Tools and Executables" \
    "ripgrep and fd" \
    "GNU Make and Build Tools" \
    "Java Development Dependencies" \
    "Node.js Development Dependencies" \
    "Neovim Backup and Restore" \
    "Managing Multiple Configurations" \
    "Troubleshooting Debian Integration"

echo
echo "======================================"
echo " Neovim / LazyVim curriculum created"
echo "======================================"
echo "Location: $ROOT"
echo "Packs: 13"
echo
echo "Total Markdown files: $(find "$ROOT" -type f -name '*.md' | wc -l)"
