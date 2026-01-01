function dot --description 'Manage dotfiles with a bare git repository'
    # Default to $HOME/.cfg if not set
    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.dotfiles.git

    git --git-dir=$DOTFILES_DIR --work-tree=$HOME $argv
end

# Inherit git completions
complete --command dot --wraps git
