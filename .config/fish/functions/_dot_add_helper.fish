function _dot_add_helper --description 'Helper to add files to dotfiles and whitelist'
    if test (count $argv) -eq 0
        echo "No file specified"
        return 1
    end

    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.dotfiles.git
    set -l gitignore_file "$HOME/.gitignore"

    # Ensure .gitignore exists
    if not test -f $gitignore_file
        echo "*" > $gitignore_file
        git --git-dir=$DOTFILES_DIR --work-tree=$HOME add $gitignore_file
    end

    for target_file in $argv
        # Check if already whitelisted
        if not grep -Fq "!$target_file" $gitignore_file
            echo "!$target_file" >> $gitignore_file
            echo "Whitelisted $target_file"
        end

        # Add file
        git --git-dir=$DOTFILES_DIR --work-tree=$HOME add $target_file
        echo "Added $target_file to dotfiles"
    end

    # Always add .gitignore at the end if files were processed
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add $gitignore_file
end
