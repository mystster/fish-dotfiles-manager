function dot-add --description 'Interactive TUI to add unmanaged files to dotfiles (fzf-based)'
    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.dotfiles.git

    # Check dependencies
    for cmd in fzf fd
        if not command -sq $cmd
            echo "Error: $cmd is not installed."
            return 1
        end
    end

    # Define listers
    set -l lister_default
    set -l lister_all
    
    # Use configurable default paths (fallback to .config if not set)
    set -q DOTFILES_DEFAULT_PATHS; or set -Ux DOTFILES_DEFAULT_PATHS .config

    # Check which directories exist
    set -l default_paths
    for d in $DOTFILES_DEFAULT_PATHS
        if test -d $HOME/$d; set -a default_paths $d; end
    end
    if test (count $default_paths) -eq 0; set default_paths "."; end

    set lister_default "fd --hidden --exclude .git --exclude '*.git' --type f . $default_paths"
    set lister_all "fd --hidden --exclude .git --exclude '*.git' --type f"

    # Define previewer
    set -l previewer
    if command -sq bat
        set previewer "bat --style=numbers --color=always --line-range :100 {}"
    else
        set previewer "cat {} | head -n 100"
    end

    # Use a temp file to track toggle state (0: default, 1: all)
    set -l state_file (mktemp)
    echo 0 > $state_file

    # Define the filter logic as a reusable string
    # We use single quotes to delay the execution of psub until the command is actually run.
    # We add '| sort' at the end to ensure results are always alphabetical.
    set -l filter_cmd 'grep -v -F -x -f (git --git-dir=$DOTFILES_DIR --work-tree=$HOME ls-files | psub) | sort'

    # Launch fzf in HOME
    set -l old_pwd $PWD
    builtin cd $HOME
    
    # fzf with dynamic reload
    # --layout=reverse: puts prompt at top, first line of input at top (A-Z top-down)
    # We remove --no-sort to allow fzf's internal fuzzy scoring when a query is typed.
    set -l selected_files (eval "$lister_default | $filter_cmd" | fzf -m \
        --layout=reverse \
        --header "ctrl-r: toggle filter (config+local / all)" \
        --bind "ctrl-r:reload(fish -c \"if grep -q 0 $state_file; echo 1 > $state_file; $lister_all | $filter_cmd; else; echo 0 > $state_file; $lister_default | $filter_cmd; end\")" \
        --preview "$previewer")
    
    set -l fzf_status $status
    builtin cd $old_pwd

    # Cleanup temp file
    rm -f $state_file

    if test -n "$selected_files"
        # Pass all selected files to the helper
        _dot_add_helper $selected_files
    else
        echo "No files selected."
    end
end
