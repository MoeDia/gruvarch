if status is-interactive
    # Remove the greeting
    set fish_greeting
    
    # Aliases (The "ls" upgrades)
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'

    # Initialize Starship Prompt
    starship init fish | source
    
    # Run Fastfetch on launch
    fastfetch
end
