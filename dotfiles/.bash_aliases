# Replaces default ls with an opinionated exa command
alias ls="exa --time-style=long-iso --group-directories-first --icons -l --git"

# Shows a file tree with exa
alias ts="exa --time-style=long-iso --group-directories-first -Tal --git"

# Function that uses fzf to checkout an existing branch and can be used with -a or -r to
# include both local and remote branches or just remote branches respectively.
gco() {
    local opt=$1
    if [[ "$opt" == "main" ]]; then
        git checkout main
        return 0
    fi

    # Capture git branch output and check for errors
    local branch_output
    if ! branch_output=$(git branch $opt 2>&1); then
        echo "$branch_output" >&2
        return 1
    fi

    # Filter and pipe to fzf only if git branch succeeded
    local selected_branch=$(echo "$branch_output" | grep -v "^\*" | sed 's/^[[:space:]]*//' | fzf --reverse --info=inline)

    if [[ -n "$selected_branch" ]]; then
        # Extract clean branch name from the selected entry
        local clean_branch=""

        if [[ "$selected_branch" =~ ^remotes/origin/ ]]; then
            # Remote branch - extract name after remotes/origin/
            clean_branch="${selected_branch#remotes/origin/}"
            git checkout "$clean_branch"
        elif [[ "$selected_branch" =~ ^origin/ ]]; then
            # Remote branch - extract name after remotes/origin/
            clean_branch="${selected_branch#origin/}"
            git checkout "$clean_branch"
        else
            # Local branch - use as-is
            git checkout "$selected_branch"
        fi
    fi
}

# Uses fzf to select a local branch in git to delete
gdlb() {
    # Capture git branch output and check for errors
    local branch_output
    if ! branch_output=$(git branch $opt 2>&1); then
        echo "$branch_output" >&2
        return 1
    fi

    # Filter and pipe to fzf only if git branch succeeded
    local lb=$(echo "$branch_output" | grep -v "^\*" | sed 's/^[[:space:]]*//' | fzf --reverse --info=inline)
    if [[ -n "$lb" ]]; then
        git branch -D "$lb"
    fi
}

# Shorthand for a clean git fetch: fetches and prunes both branches and tags
alias gfp="git fetch -pPt"
