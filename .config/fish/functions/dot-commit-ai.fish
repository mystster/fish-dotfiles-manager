function dot-commit-ai
    set -l commit_mode "staged"
    set -l diff_content ""
    argparse --name=dot-commit-ai 'out-file=' 'overwrite' 'append' -- $argv
    
    if not set -q _flag_out_file
        echo "Error: --out-file is required."
        return 1
    end

    if set -q _flag_overwrite; and set -q _flag_append
        echo "Error: Cannot specify both --overwrite and --append."
        return 1
    end

    if not set -q _flag_overwrite; and not set -q _flag_append
        echo "Error: Must specify either --overwrite or --append."
        return 1
    end

    set -l out_file $_flag_out_file

    # Check if there are staged changes
    if not dot diff --cached --quiet
        # There are staged changes
        set diff_content (dot diff --cached)
    else
        # No staged changes, check for unstaged changes
        if not dot diff --quiet
             # There are unstaged changes
             echo "No staged changes found. Using unstaged changes..."
             set commit_mode "all"
             set diff_content (dot diff)
        else
             echo "No changes to commit."
             return 1
        end
    end

    echo "Generating commit message..."
    echo ""

    # Prompt construction
    set -l system_instructions "You are a specialized commit message generator. Your ONLY job is to describe the changes in the provided diff. Do NOT hallucinate features or context not present in the diff. Do NOT mention 'AI', 'Gemini', or 'dotfiles manager' unless these specific words are added or modified in the code."
    set -l user_prompt "Generate a single line commit message following Conventional Commits specification (e.g., 'feat: add feature', 'fix: resolve bug') based EXCLUSIVELY on the following diff. Ignore any file path context unless relevant to the change. Only return the commit message itself, nothing else.\n\nDiff:\n$diff_content"

    set -l full_prompt "$system_instructions\n\nUSER PROMPT: $user_prompt"

    # Call Gemini API
    # Using gemini-3-flash-preview for speed
    set -l commit_msg (_dot_gemini_api "$full_prompt" "gemini-3-flash-preview")

    if test $status -ne 0
        echo "Failed to generate commit message."
        return 1
    end

    # Sanitize message (remove newlines if any, though prompt asks for single line)
    set commit_msg (string trim $commit_msg)

    if set -q _flag_overwrite
        echo "$commit_msg" > "$out_file"
    else
        echo "$commit_msg" >> "$out_file"
    end

    echo "AI Commit message written to $out_file"
    echo "Use 'c' in lazygit to paste and commit."
    return 0
end
