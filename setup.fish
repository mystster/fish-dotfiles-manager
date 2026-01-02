#!/usr/bin/env fish

set DOTFILES_DIR "$HOME/.dotfiles.git"
set LOG_FILE "setup.log"

# Configuration (Update these for your fork)
set REPO_USER "mystster"
set REPO_NAME "fish-dotfiles-manager"
set REPO_BRANCH "main"
set RAW_BASE_URL "https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH"

function log
    echo (date "+%Y-%m-%d %H:%M:%S") $argv | tee -a $LOG_FILE
end

function check_dependency
    if not pacman -Q $argv[1] > /dev/null 2>&1
        log "$argv[1] is not installed."
        log "Installing $argv[1] and its dependencies..."
        if not sudo pacman -S $argv[1]
            log "Error: Failed to install $argv[1]. Please install it manually."
            exit 1
        end
    end
end

check_dependency git
check_dependency lazygit
check_dependency fzf

echo "Fish Dotfiles Manager Setup"
echo "---------------------------"
echo "1. Initialize new repository (starts with whitelist mode)"
echo "2. Clone existing repository"
read -P "Select option (1/2): " option < /dev/tty

function download_file
    set -l relative_path $argv[1]
    set -l target_path $argv[2]
    set -l url "$RAW_BASE_URL/$relative_path"
    
    mkdir -p (dirname $target_path)
    
    log "Downloading $relative_path..."
    if not curl -sL "$url" -o "$target_path"
        log "Error: Failed to download $relative_path"
        exit 1
    end
end

if test "$option" = "1"

    if test -d $DOTFILES_DIR
        log "Directory $DOTFILES_DIR already exists."
        read -P "Overwrite? (y/N): " confirm < /dev/tty
        if test "$confirm" = "y"
            rm -rf $DOTFILES_DIR
        else
            exit 1
        end
    end

    git init --bare $DOTFILES_DIR
    log "Initialized bare repository at $DOTFILES_DIR"
    
    # Configure
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME config --local status.showUntrackedFiles no
    
    # Setup whitelist
    if not test -f "$HOME/.gitignore"
        echo "*" > "$HOME/.gitignore"
        echo "!*/" >> "$HOME/.gitignore"
        log "Created .gitignore with * and !*/"
    else
        if not grep -Fq "*" "$HOME/.gitignore"
            echo "*" >> "$HOME/.gitignore"
            log "Appended * to existing .gitignore"
        end
        if not grep -Fq "!*/" "$HOME/.gitignore"
            echo "!*/" >> "$HOME/.gitignore"
            log "Appended !*/ to existing .gitignore"
        end
    end
    
    # Download template files (functions and config)
    download_file ".config/fish/functions/dot.fish" "$HOME/.config/fish/functions/dot.fish"
    download_file ".config/fish/functions/dot-lazy.fish" "$HOME/.config/fish/functions/dot-lazy.fish"
    download_file ".config/fish/functions/dot-add.fish" "$HOME/.config/fish/functions/dot-add.fish"
    download_file ".config/fish/functions/_dot_add_helper.fish" "$HOME/.config/fish/functions/_dot_add_helper.fish"

    # Update whitelist for these files
    echo "!.gitignore" >> "$HOME/.gitignore"
    echo "!.config/fish/functions/dot.fish" >> "$HOME/.gitignore"
    echo "!.config/fish/functions/dot-lazy.fish" >> "$HOME/.gitignore"
    echo "!.config/fish/functions/dot-add.fish" >> "$HOME/.gitignore"
    echo "!.config/fish/functions/_dot_add_helper.fish" >> "$HOME/.gitignore"

    # Add gitignore and template files
    # Whitelist is strictly configured, so standard git add should work
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/.gitignore"
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/.config/fish/functions/dot.fish"
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/.config/fish/functions/dot-lazy.fish"
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/.config/fish/functions/dot-add.fish"
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/.config/fish/functions/_dot_add_helper.fish"

    if git --git-dir=$DOTFILES_DIR --work-tree=$HOME commit -m "Initial commit: Add whitelist and dotfiles tools"
        log "Committed initial dotfiles"
    else
        log "Warning: Initial commit failed (likely due to missing git user identity)."
        log "Please configure git user and email, then run: dot commit -m 'Initial commit'"
    end

    # Set universal variable
    set -Ux DOTFILES_DIR $DOTFILES_DIR
    log "Set DOTFILES_DIR to $DOTFILES_DIR"

else if test "$option" = "2"
    read -P "Enter repository URL: " repo_url < /dev/tty
    if test -z "$repo_url"
        log "Error: URL cannot be empty"
        exit 1
    end

    if test -d $DOTFILES_DIR
        log "Directory $DOTFILES_DIR already exists. Backing up..."
        mv $DOTFILES_DIR "$DOTFILES_DIR.bak."(date +%s)
    end

    git clone --bare $repo_url $DOTFILES_DIR
    log "Cloned repository to $DOTFILES_DIR"

    # Configure
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME config --local status.showUntrackedFiles no
    
    # Attempt checkout
    log "Attempting checkout..."
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME checkout
    if test $status -ne 0
        log "Checkout failed due to existing files."
        read -P "Backup conflicting files and retry? (y/N): " backup_confirm < /dev/tty
        if test "$backup_confirm" = "y"
            mkdir -p .dotfiles_backup
            log "Backing up conflicting files to .dotfiles_backup..."
            
            # Capture conflicting files from git checkout output
            # Note: This parsing relies on git output format (indented file list)
            git --git-dir=$DOTFILES_DIR --work-tree=$HOME checkout 2>&1 | string match -r '^\s+(.+)' | while read -l line
                set -l file (string trim $line)
                # Create parent dir in backup
                mkdir -p .dotfiles_backup/(dirname $file)
                mv $file .dotfiles_backup/$file
                log "Moved $file"
            end
            
            # Retry
            git --git-dir=$DOTFILES_DIR --work-tree=$HOME checkout
            if test $status -eq 0
                 log "Checkout successful."
            else
                 log "Checkout failed again. Please check logs and resolve manually."
            end
        else
            log "Aborted checkout."
        end
    else
        log "Checkout successful."
    end
    
    set -Ux DOTFILES_DIR $DOTFILES_DIR

else
    echo "Invalid option"
    exit 1
end

echo ""
echo "Setup complete!"
echo "Please restart your shell to load the new functions (if installed)."
