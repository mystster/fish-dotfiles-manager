#!/usr/bin/env fish

set DOTFILES_DIR "$HOME/.dotfiles.git"
set LOG_FILE "setup.log"

# Configuration (Update these for your fork)
set REPO_USER "mystster"
set REPO_NAME "fish-dotfiles-manager"
set REPO_BRANCH "main"
set RAW_BASE_URL "https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH"

# Tool definitions
set managed_tools \
    ".config/fish/functions/dot.fish" \
    ".config/fish/functions/dot-lazy.fish" \
    ".config/fish/functions/dot-add.fish" \
    ".config/fish/functions/_dot_add_helper.fish"

set obsolete_tools \
    ".config/fish/functions/dot-add-fzf.fish" \
    ".config/dotfiles/broot.conf.hjson"

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

function update_tools
    log "Updating managed tools..."
    for tool in $managed_tools
        download_file $tool "$HOME/$tool"
        # Update .gitignore if not already whitelisted
        if not grep -Fq "!$tool" "$HOME/.gitignore"
            echo "!$tool" >> "$HOME/.gitignore"
        end
        # Stage in git if repo exists
        if test -d $DOTFILES_DIR
            git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/$tool"
        end
    end
    if test -d $DOTFILES_DIR
        git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/.gitignore"
    end
end

function cleanup_tools
    log "Cleaning up obsolete tools..."
    for tool in $obsolete_tools
        set -l full_path "$HOME/$tool"
        if test -f $full_path
            log "Removing $tool..."
            rm -f $full_path
            # Remove from git index if repo exists
            if test -d $DOTFILES_DIR
                git --git-dir=$DOTFILES_DIR --work-tree=$HOME rm --ignore-unmatch "$full_path"
            end
        end
        # Remove from .gitignore if exists
        if test -f "$HOME/.gitignore"
            # Remove the exact line "!$tool"
            sed -i "\|^!$tool\$|d" "$HOME/.gitignore"
        end
    end
    # Ensure .gitignore changes are staged
    if test -d $DOTFILES_DIR
        git --git-dir=$DOTFILES_DIR --work-tree=$HOME add "$HOME/.gitignore"
    end
end

check_dependency git
check_dependency lazygit
check_dependency fzf

echo "Fish Dotfiles Manager Setup"
echo "---------------------------"
echo "1. Initialize new repository (starts with whitelist mode)"
echo "2. Clone existing repository"
echo "3. Update tools (Download latest and cleanup)"
read -P "Select option (1/2/3): " option < /dev/tty

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
    end
    
    echo "!.gitignore" >> "$HOME/.gitignore"
    
    # Download and Stage Tools
    update_tools
    cleanup_tools

    if git --git-dir=$DOTFILES_DIR --work-tree=$HOME commit -m "Initial commit: Add whitelist and dotfiles tools"
        log "Committed initial dotfiles"
    else
        log "Warning: Initial commit failed (likely due to missing git user identity)."
    end

    # Set universal variable
    set -Ux DOTFILES_DIR $DOTFILES_DIR
    log "Set DOTFILES_DIR to $DOTFILES_DIR"

else if test "$option" = "3"
    if not test -d $DOTFILES_DIR
        log "Error: DOTFILES_DIR ($DOTFILES_DIR) not found. Please initialize or clone first."
        exit 1
    end
    
    # Check index state before updates
    set -l index_clean_before 0
    if git --git-dir=$DOTFILES_DIR --work-tree=$HOME diff --staged --quiet
        set index_clean_before 1
    end

    update_tools
    cleanup_tools
    
    # Check index state after updates
    if git --git-dir=$DOTFILES_DIR --work-tree=$HOME diff --staged --quiet
        log "No changes to tools. Everything is up-to-date."
    else
        if test $index_clean_before -eq 1
            log "Committing updates..."
            git --git-dir=$DOTFILES_DIR --work-tree=$HOME commit -m "chore: update tools via setup.fish"
            log "Tools updated and changes committed."
        else
            log "Warning: Independent changes were already staged in the repository."
            log "Tool updates have been staged but NOT committed to avoid polluting your commit."
            log "Please review changes with 'dot status' and commit manually."
        end
    end

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
