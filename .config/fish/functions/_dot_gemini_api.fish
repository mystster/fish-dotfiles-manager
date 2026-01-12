function _dot_gemini_api
    set -l prompt $argv[1]
    set -l model $argv[2] # Optional, defaults to gemini-3-flash-preview
    
    # Default model if not provided
    if test -z "$model"
        set model "gemini-3-flash-preview" 
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

    # Execute curl request with retry
    set -l response
    set -l max_retries 3
    set -l attempt 1
    
    while test $attempt -le $max_retries
        set response (curl -s -H 'Content-Type: application/json' \
            -d "$json_payload" \
            "$api_url")
            
        # Check if response contains candidates (success)
        if echo "$response" | grep -q "candidates"
            break
        end

        # Check if it is a specific error that is worth retrying
        # "Visibility check was unavailable" or 503s often come as error json
        set -l err_msg (echo "$response" | jq -r '.error.message // empty')
        if test -n "$err_msg"
             echo "API Error (Attempt $attempt/$max_retries): $err_msg" >&2
        else if test -z "$response"
             echo "No response (Attempt $attempt/$max_retries)" >&2
        end
        
        if test $attempt -lt $max_retries
            set attempt (math $attempt + 1)
            sleep 2
        else
            break
        end
    end

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
