function dot-lazy --description 'Lazygit wrapper for dotfiles'
    # Default to $HOME/.cfg if not set
    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.cfg

    lazygit --git-dir=$DOTFILES_DIR --work-tree=$HOME $argv
end
