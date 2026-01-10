function _dot_gemini_api
    set -l prompt $argv[1]
    set -l model $argv[2] # Optional, defaults to gemini-2.0-flash-exp (latest stable/fast)
    
    # Default model if not provided
    if test -z "$model"
        set model "gemini-3-flash" 
    end

    if not set -q GEMINI_API_KEY
        echo "Error: GEMINI_API_KEY is not set. Please run 'setup.fish' to configure it." >&2
        return 1
    end

    if not type -q jq
        echo "Error: 'jq' is not installed. Please install it to use AI features." >&2
        return 1
    end

    set -l api_url "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY"

    # Construct JSON payload safely using jq
    # structure: { contents: [{ parts: [{ text: "prompt" }] }] }
    set -l json_payload (jq -n --arg txt "$prompt" '{contents: [{parts: [{text: $txt}]}]}')

    # Execute curl request
    set -l response (curl -s -H 'Content-Type: application/json' \
        -d "$json_payload" \
        "$api_url")

    # Check for curl error (empty response)
    if test -z "$response"
        echo "Error: No response from Gemini API." >&2
        return 1
    end

    # Parse response using jq
    # Target path: .candidates[0].content.parts[0].text
    set -l answer (echo "$response" | jq -r '.candidates[0].content.parts[0].text')

    if test "$answer" = "null"
        # Check for error message in response
        set -l err_msg (echo "$response" | jq -r '.error.message // "Unknown error"')
        echo "Error from Gemini API: $err_msg" >&2
        return 1
    end

    echo "$answer"
end
