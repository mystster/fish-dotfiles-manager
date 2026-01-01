function _dot_add_helper --description 'Helper to add files to dotfiles and whitelist'
    set -l target_file $argv[1]
    
    if test -z "$target_file"
        echo "No file specified"
        return 1
    end

    set -q DOTFILES_DIR; or set -Ux DOTFILES_DIR $HOME/.cfg

    # Relative path from HOME (assuming we are running in HOME or target is full path?)
    # broot passes full path or relative? "execution": "_dot_add_helper {file}" usually passes full path or relative to CWD.
    # As we launch broot in $HOME, it should be relative or full. PROBABLY full if we don't specify.
    # Let's standardize on relative path for .gitignore.
    
    # We assume CWD is HOME when this is run via the tool, but let's be safe.
    # Actually checking path relativity in simple shell script without realpath is tricky if we don't rely on `path` utility of fish (available in newer fish).
    # Since I cannot verify fish version, I will assume $HOME is the base.
    
    # Simplify: strict requirement for dot-add is "listing unmanaged files in HOME".
    # so input is likely relative to HOME if we run from HOME.
    
    # Update .gitignore
    set -l gitignore_file "$HOME/.gitignore"
    if not test -f $gitignore_file
        echo "*" > $gitignore_file
        # dot add immediately?
        git --git-dir=$DOTFILES_DIR --work-tree=$HOME add $gitignore_file
    end

    # Check if already whitelisted?
    # grep -Fq "!$target_file" $gitignore_file
    # Simple append is safer to avoid complexity, sort/uniq later if needed.
    # But let's avoid duplicates.
    if not grep -Fq "!$target_file" $gitignore_file
        echo "!$target_file" >> $gitignore_file
        echo "Whitelisted $target_file"
    end

    # Add file and .gitignore
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add $target_file
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add $gitignore_file
    
    echo "Added $target_file to dotfiles"
end
