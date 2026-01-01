function dot-add --description 'TUI to add unmanaged files to dotfiles'
    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.cfg
    set -l config_file "$HOME/.config/dotfiles/broot.conf.hjson"
    
    if not test -f $config_file
        echo "Configuration file not found at $config_file"
        # Fallback or exit?
        # If we are just setting up, maybe we can run from the repo dir?
        # But this function is intended to be run after installation.
        return 1
    end
    
    # Launch broot in HOME
    # We pass the config file
    pushd $HOME
    broot --conf $config_file
    popd
end
