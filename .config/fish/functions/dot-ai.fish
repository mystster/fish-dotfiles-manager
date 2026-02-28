function dot-ai
    if test (count $argv) -eq 0
        echo "Usage: dot-ai \"prompt description\""
        echo "Example: dot-ai \"Create a fish alias for ls -la\""
        return 1
    end

    set -l prompt $argv[1]
    
    echo "Gathering context (this may take a moment)..."

    # --- Context Gathering ---
    set -l context_data ""

    # 1. Repo Structure (limit to 2 deep to avoid noise, or filtered list)
    # Using 'dot ls-tree' to see what's actually tracked
    set -l tracked_files (dot ls-tree -r --name-only HEAD | head -n 50)
    set context_data "$context_data\n\n## Repository Structure (Tracked Files):\n$tracked_files"

    # 2. Heuristic: Read 'config.fish' if "fish" or "alias" is mentioned
    if string match -q -i "*fish*" "$prompt"; or string match -q -i "*alias*" "$prompt"
        if test -f "$HOME/.config/fish/config.fish"
            set -l content (head -n 50 "$HOME/.config/fish/config.fish")
            set context_data "$context_data\n\n## .config/fish/config.fish (First 50 lines):\n$content"
        end
    end

    # 3. Heuristic: Read 'gitconfig' if "git" is mentioned
    if string match -q -i "*git*" "$prompt"
        if test -f "$HOME/.gitconfig"
             set -l content (cat "$HOME/.gitconfig")
             set context_data "$context_data\n\n## .gitconfig:\n$content"
        end
    end

    # --- System Prompt Construction ---
    set -l system_instructions "You are an expert dotfiles manager for Arch Linux using Fish shell.
    The user uses a BARE GIT REPOSITORY approach where \$HOME is the worktree.
    
    Your goal is to suggest file content or commands based on the User Prompt.

    CONTEXT:
    $context_data
    
    INSTRUCTIONS:
    1. Analyze the Context to understand the user's existing config style, variable naming, and directory structure.
    2. Suggest a specific file path and the content for that file.
    3. Output format must be strictly JSON for machine parsing:
    {
      \"file\": \"path/to/file\",
      \"content\": \"file content here\",
      \"explanation\": \"brief explanation\"
    }
    4. If the request involves running a command, set \"file\" to \"COMMAND\" and \"content\" to the command.
    "

    # Call Gemini
    # Note: _dot_gemini_api expects a single prompt string. We combine system and user prompt.
    set -l full_prompt "$system_instructions\n\nUSER PROMPT: $prompt"
    
    echo "Asking Gemini..."
    set -l response (_dot_gemini_api "$full_prompt" "gemini-3-pro-preview")

    if test $status -ne 0
        echo "AI Request Failed."
        return 1
    end

    # Clean response (sometimes MD code blocks are included)
    set response (string replace -r '^```json' '' "$response")
    set response (string replace -r '^```' '' "$response")
    set response (string replace -r '```$' '' "$response")

    # Parse JSON
    set -l suggested_file (echo "$response" | jq -r '.file')
    set -l suggested_content (echo "$response" | jq -r '.content')
    set -l explanation (echo "$response" | jq -r '.explanation')

    if test "$suggested_file" = "null"
        echo "Could not parse AI response."
        echo "Raw response: $response"
        return 1
    end

    echo "--------------------------------------------------"
    echo "AI Suggestion:"
    echo "File: $suggested_file"
    echo "Explanation: $explanation"
    echo "--------------------------------------------------"
    echo "$suggested_content" | bat --language fish --style=plain 2>/dev/null; or echo "$suggested_content"
    echo "--------------------------------------------------"

    read -P "Apply this change? (y/N): " confirm < /dev/tty
    if test "$confirm" = "y"
        if test "$suggested_file" = "COMMAND"
             eval "$suggested_content"
        else
             set -l abs_path "$HOME/$suggested_file"
             mkdir -p (dirname "$abs_path")
             echo "$suggested_content" > "$abs_path"
             echo "Applied changes to $abs_path"
             
             # Auto-add if it's new
             dot-add "$abs_path"
        end
    else
        echo "Discarded."
    end
end
