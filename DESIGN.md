# Design & Architecture Document

This document summarizes the architecture, design decisions, and technical background of the Fish Dotfiles Manager. It is intended to help future developers (and AI agents) understand the context and rationale behind the implementation.

## 1. Overview
The goal of this tool is to provide a robust, shell-integrated way to manage dotfiles on an **Arch Linux + Fish** environment. It uses a **Bare Git Repository** approach to track configuration files located anywhere in the home directory without needing symlinks.

## 2. Core Concepts

### Bare Git Repository
Instead of a traditional git repo with a `.git` folder inside a working directory, we use a "bare" repository (located at `~/.dotfiles.git` by default) and treat `$HOME` as the work tree.
- **Command**: `dot` is an alias/function for `git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME`.

### Whitelist Strategy
To avoid polluting the repository with unrelated home directory files, we adopt a **Whitelist** strategy:
- The `.gitignore` file initially contains:
    ```
    *
    !*/
    ```
- **`*`**: Ignores everything by default.
- **`!*/`**: Un-ignores directories. This is **critical** because Git cannot track a file if its parent directory is ignored. This allows Git to traverse the directory tree.
- Only files explicitly "added" are tracked by appending `!/path/to/file` (anchored to the repository root) to `.gitignore`. The leading slash is used to prevent ambiguous matches in subdirectories.

## 3. Technology Stack & Dependencies

| Category | Tool | Usage |
| :--- | :--- | :--- |
| **Shell** | `fish` | The primary shell environment. Scripts utilize fish syntax and autoloading features. |
| **VCS** | `git` | Core version control. |
| **TUI (Git)** | `lazygit` | Visual interface for committing, staging, and reviewing changes. |
| **TUI (Files)** | `fzf` | Interactive fuzzy finder used to browse *unmanaged* files and add them to the repo. |
| **Utilities** | `fd`, `bat`, `sort` | High-performance file searching, syntax-highlighted previews, and organized listing. |
| **AI Integration** | `curl`, `jq` | Used to communicate with Google Gemini API safely. |
| **Package Manager** | `pacman` | Used in `setup.fish` to verify and install dependencies (Arch Linux specific). |

## 4. Architecture & Components

The file structure mirrors the standard Fish configuration layout to enable function autoloading upon installation.

### Directory Structure
```
repo_root/
├── setup.fish                          # Bootstrap/Installation/Update script
├── .config/
│   └── fish/
│       └── functions/
│           ├── dot.fish                # Core git wrapper
│           ├── dot-lazy.fish           # Lazygit wrapper
│           ├── dot-add.fish            # Interactive file addition (fzf-based)
│           └── _dot_add_helper.fish    # Helper logic (whitelist & git-add)
```

### Key Functions
- **`dot`**: Wraps `git`. Configures completions to wrap `git` so tab-completion works.
- **`dot-lazy`**: Opens `lazygit` with the correct git-dir/work-tree context.
- **`dot-add`**: Launches an interactive `fzf` TUI to find and add unmanaged files.
    - **Hybrid Sorting**: Initial listing is alphabetical (A-Z); searching re-sorts by fuzzy relevance.
    - **Directory Toggle**: `Ctrl-R` switches between a focused view (`.config`, `.local/share`) and a full home search.
    - **Automatic Filtering**: Always excludes files already tracked by the Git repository.
    - Updates `.gitignore` to whitelist the files using root-anchored paths (`!/filename`).
    - Stages the target files and the updated `.gitignore` in the Git repository.
- **`dot-commit-ai`**: Generates conventional commit messages using Gemini Flash.
- **`dot-ai`**: Generates or modifies dotfiles using Gemini Pro.
    - **Context Awareness**: Scans the repository structure and reads content of relevant tracked files to understand the user's specific configuration style before making suggestions.
    - **Safety**: Outputs JSON to avoid parsing errors and asks for user confirmation before applying changes.

### Configuration
- **Environment Variable**: `DOTFILES_DIR` stores the location of the bare repo.
- **Syntax**: `set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.dotfiles.git` is used consistently to ensure persistence and flexibility.

## 5. Design Decisions & Policies

### TUI Selection: Transition from Broot to FZF
Initially, `broot` was chosen for its tree-style exploration. However, based on user feedback and practical efficiency, the project transitioned to a custom **`fzf`** TUI.
- **Why?**: `fzf` offers superior fuzzy search speed, more robust multi-selection, and a cleaner interactive experience when managing specific files across deep directory structures.
- **Innovation**: The implementation uses a "Hybrid Sorting" approach and a "Delayed Filter" (via `psub`) to ensure high performance and intuitive organization.

### Tool Update & Automated Cleanup Strategy
`setup.fish` serves as both an installer and a maintenance tool.
- **Centralized Management**: Managed tools and obsolete tools are defined in lists.
- **Update Logic**: Option `3. Update tools` synchronizes local scripts with the latest GitHub versions.
- **Automated Cleanup**: The script automatically removes legacy files (like `dot-add-fzf.fish` or `broot.conf.hjson`) and handles Git index purging, ensuring the user's environment stays clean and synchronized with the project's evolution.

## 6. User-Requested Policies
- **Minimize User Input**: Automated setup with reasonable defaults.
- **Robust Variables**: Use universal variables (`-Ux`) to preserve configuration across shell sessions.
- **Directory Politeness**: Use `pushd`/`popd` instead of `cd` in functions to respect the user's working directory stack.
- **Verification Before Commit**: Detailed explanation and approval required before making non-trivial changes to the repository.
- **Documentation Synchronization**: README.md and DESIGN.md must be updated simultaneously upon completion of any code changes or bug fixes to ensure documentation stays in sync with the implementation.

## 7. Future Improvements
- Support for multiple package managers (beyond `pacman`).
- Validation of repository configuration during the update process.
