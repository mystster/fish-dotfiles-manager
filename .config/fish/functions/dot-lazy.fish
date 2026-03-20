function dot-lazy --description 'Lazygit wrapper for dotfiles'
    # Default to $HOME/.cfg if not set
    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.dotfiles.git
    set lazy_config "$HOME/.config/fish/functions/dot-lazy.yml"

    lazygit --git-dir=$DOTFILES_DIR --work-tree=$HOME $argv -ucf $lazy_config
end
