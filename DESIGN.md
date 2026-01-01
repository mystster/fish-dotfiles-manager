# Design & Architecture Document

This document summarizes the architecture, design decisions, and technical background of the Fish Dotfiles Manager. It is intended to help future developers (and AI agents) understand the context and rationale behind the implementation.

## 1. Overview
The goal of this tool is to provide a robust, shell-integrated way to manage dotfiles on an **Arch Linux + Fish** environment. It uses a **Bare Git Repository** approach to track configuration files located anywhere in the home directory without needing symlinks.

## 2. Core Concepts

### Bare Git Repository
Instead of a traditional git repo with a `.git` folder inside a working directory, we use a "bare" repository (located at `~/.cfg` by default) and treat `$HOME` as the work tree.
- **Command**: `dot` is an alias/function for `git --git-dir=$HOME/.cfg --work-tree=$HOME`.

### Whitelist Strategy
To avoid polluting the repository with unrelated home directory files, we adopt a **Whitelist** strategy:
- The `.gitignore` file contains `*` (ignore everything) by default.
- Only files explicitly "added" are tracked.
- **Logic**: When a file is added via this tool, it is automatically *un-ignored* (whitelisted) in `.gitignore` (e.g., `!path/to/file` is appended).

## 3. Technology Stack & Dependencies

| Category | Tool | Usage |
| :--- | :--- | :--- |
| **Shell** | `fish` | The primary shell environment. Scripts utilize fish syntax and autoloading features. |
| **VCS** | `git` | Core version control. |
| **TUI (Git)** | `lazygit` | Visual interface for committing, staging, and reviewing changes. |
| **TUI (Files)** | `broot` | Tree-view file explorer used to browse *unmanaged* files and add them to the repo. |
| **Package Manager** | `pacman` | Used in `setup.fish` to verify and install dependencies (Arch Linux specific). |

## 4. Architecture & Components

The file structure mirrors the standard Fish configuration layout to enable function autoloading upon installation.

### Directory Structure
```
repo_root/
├── setup.fish                          # Bootstrap/Installation script
├── .config/
│   ├── fish/
│   │   └── functions/
│   │       ├── dot.fish                # Core git wrapper
│   │       ├── dot-lazy.fish           # Lazygit wrapper
│   │       ├── dot-add.fish            # TUI entry point
│   │       └── _dot_add_helper.fish    # Helper logic (whitelist handling)
│   └── dotfiles/
│       └── broot.conf.hjson            # Dedicated broot configuration
```

### Key Functions
- **`dot`**: Wraps `git`. Configures completions to wrap `git` so tab-completion works.
- **`dot-lazy`**: Opens `lazygit` with the correct git-dir/work-tree context.
- **`dot-add`**: Launches `broot` with a custom configuration file (`broot.conf.hjson`).
    - Uses `pushd`/`popd` to preserve the user's directory context.
- **`_dot_add_helper`**: Invoked by `broot` when a file is selected.
    - Updates `.gitignore` to whitelist the file (`!filename`).
    - Runs `git add` for both the target file and `.gitignore`.

### Configuration
- **Environment Variable**: `DOTFILES_DIR` stores the location of the bare repo.
- **Syntax**: `set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.cfg` is used consistently to ensure the variable is universal (`-U`) and exported (`-x`) but respects existing values.

## 5. Design Decisions & Policies (Session History)

During the initial development, the following decisions were made based on user requirements:

1.  **TUI Selection**:
    - Initially planned with `fzf`, but switched to **`broot`** because a "tree view" was explicitly requested for browsing unmanaged files.
    - A dedicated config file (`broot.conf.hjson`) is used to isolate the tool's settings from the user's personal `broot` config.

2.  **Deployment**:
    - **One-Liner**: Installation via `curl ... | fish` is supported.
    - **Download Logic**: The setup script downloads individual function files from the GitHub repository ("raw" URLs) instead of cloning the entire repo for the setup process itself (though option 2 clones the bare repo).
    - **Dependency Handling**: If dependencies (`git`, `lazygit`, `broot`) are missing, the script attempts to install them using `sudo pacman -S`.

3.  **Setup Workflow**:
    - **Initialize (Option 1)**: Creates a new bare repo, creates the `.gitignore` with `*`, and downloads the tool functions.
    - **Clone (Option 2)**: Clones an existing repo and attempts checkout. If conflicts exist, it offers to backup conflicting files to `.dotfiles_backup`.

4.  **Code Style**:
    - Use `pushd`/`popd` instead of `cd` in functions to be polite to the user's session.
    - Standardized variable setting syntax.
    - Dependencies checked via `pacman -Q`.

## 6. Future Improvements
- Support for other package managers (apt, dnf) if expanding beyond Arch.
- More robust error handling for network requests in `setup.fish`.
- Validation of `REPO_USER` variables in the setup script.
