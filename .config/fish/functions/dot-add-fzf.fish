function dot-add-fzf --description 'FZF-based TUI to add unmanaged files to dotfiles'
    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.dotfiles.git

    # Check for fzf
    if not command -sq fzf
        echo "Error: fzf is not installed."
        return 1
    end

    # Define file lister
    set -l lister
    if command -sq fd
        # --hidden: include hidden files
        # --exclude .git: exclude standard .git dirs
        # --exclude "*.git": exclude bare repos like .dotfiles.git
        set lister "fd --hidden --exclude .git --exclude '*.git' --type f"
    else
        # find fallback with exclusions for .git and directories ending in .git
        set lister "find . -maxdepth 4 -not -path '*/.git/*' -not -path '*/.git' -not -path '*.git/*' -not -path '*.git' -not -path '*/.*' -type f"
        echo "Warning: fd not found, falling back to find (less efficient)."
    end

    # Define previewer
    set -l previewer
    if command -sq bat
        set previewer "bat --style=numbers --color=always --line-range :100 {}"
    else
        set previewer "cat {} | head -n 100"
    end

    # Launch fzf in HOME
    pushd $HOME
    # -m: multi-select
    set -l selected_files (eval $lister | fzf -m --preview "$previewer")
    popd

    if test -n "$selected_files"
        # Pass all selected files to the helper
        _dot_add_helper $selected_files
    else
        echo "No files selected."
    end
end
