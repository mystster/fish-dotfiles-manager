# Fish Dotfiles Manager

A simple, robust dotfiles management tool for Fish shell users, leveraging a bare git repository, lazygit, and a custom TUI for managing untracked files.

## Requirements

- **Shell**: `fish`
- **Core**: `git`
- **UI**: `lazygit`, `fzf`
- **Utilities**: `fd` (recommended), `bat` (optional, for preview)

## Features

1.  **Dotfiles Management**: Wraps a bare git repository to manage configuration files from any location.
    -   **Configurable**: Set your preferred dotfiles directory (defaults to `~/.dotfiles.git`).
2.  **Lazygit Integration**: Seamless interface to review changes, stage files, and commit using `lazygit`.
3.  **Unmanaged File Explorer**: 
    -   `dot-add`: Interactive fuzzy finder via `fzf` with automatic filtering of already tracked files and a directory toggle (`Ctrl-R`).
4.  **Flexible Deployment**: Bootstrap script supports both cloning existing repos and initializing new ones.

## Workflow

- **Command**: `dot` (wraps git)
- **Visual Git**: `dot-lazy` (or similar alias)
- **Add Files (Fuzzy Finder)**: `dot-add` (launches `fzf`)

## Installation / Setup

### Prerequisites
Ensure `git`, `fish`, `fzf`, and `lazygit` are installed (the setup script will attempt to install them using `pacman` if missing).

### One-liner Installation

```fish
curl -sL https://raw.githubusercontent.com/mystster/fish-dotfiles-manager/main/setup.fish | fish
```

> **Note**: This will install the dotfiles management tools. You can simply verify the installation and start managing your files.

### Interactive Setup
The script will prompt you to:
1.  **Initialize new repository**: Creates a bare repo, whitelisted `.gitignore`, and downloads the necessary tool functions (`dot`, `dot-add`, etc.) from GitHub.
2.  **Clone existing repository**: Clones your repo and sets up the environment.
3.  **Update tools**: Synchronizes local scripts with the latest versions from the repository and removes obsolete files automatically.

## Usage

### Managing Files
- **Add new file**: 
  - Run `dot-add`: Fuzzy-find unmanaged files. Toggle view with `Ctrl-r`.
  - Automatically updates `.gitignore` (un-ignores the file) and stages the changes.
- **Commit changes**: Run `dot-lazy` (or `dot commit ...`).

### Manual Git Operations
Use the `dot` command just like `git`:
```fish
dot status
dot add .gitignore
dot commit -m "update config"
dot push
```
