# Fish Dotfiles Manager

A simple, robust dotfiles management tool for Fish shell users, leveraging a bare git repository, lazygit, and a custom TUI for managing untracked files.

## Requirements

- **Shell**: `fish`
- **Core**: `git`
- **UI**: `lazygit`, `broot`
- **Utilities**: `bat` (optional, for preview)

## Features

1.  **Dotfiles Management**: Wraps a bare git repository to manage configuration files from any location.
    -   **Configurable**: Set your preferred dotfiles directory.
2.  **Lazygit Integration**: Seamless interface to review changes, stage files, and commit using `lazygit`.
3.  **Unmanaged File Explorer**: A TUI (via `broot`) to browse files in a tree structure and easily add them.
4.  **Flexible Deployment**: Bootstrap script supports both cloning existing repos and initializing new ones.

## Workflow

- **Command**: `dot` (wraps git)
- **Visual Git**: `dot-lazy` (or similar alias)
- **Add Files**: `dot-add` (launches `broot` tree view)

## Installation / Setup

### Prerequisites
Ensure `git`, `fish`, `broot`, and `lazygit` are installed (the setup script will attempt to install them using `pacman` if missing).

### One-liner Installation

```fish
curl -sL https://raw.githubusercontent.com/mystster/dotfiles-fish/main/setup.fish | fish
```

> **Important**: You must fork this repository and update the `REPO_USER` variables in `setup.fish` to point to your fork before running the one-liner!

### Interactive Setup
The script will prompt you to:
1.  **Initialize new repository**: Creates a bare repo, whitelisted `.gitignore`, and downloads the necessary tool functions (`dot`, `dot-add`, etc.) from GitHub.
2.  **Clone existing repository**: Clones your repo and sets up the environment.

## Usage

### Managing Files
- **Add new file**: Run `dot-add`. Select files in the tree and press `Ctrl+a`.
  - This automatically updates `.gitignore` (un-ignores the file) and stages it.
- **Commit changes**: Run `dot-lazy` (or `dot commit ...`).

### Manual Git Operations
Use the `dot` command just like `git`:
```fish
dot status
dot add .gitignore
dot commit -m "update config"
dot push
```
