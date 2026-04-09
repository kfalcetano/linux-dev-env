# Replaces default ls with an opinionated exa command
alias ls="exa --time-style=long-iso --group-directories-first --icons -l --git"

# Shows a file tree with exa
alias lt="exa --time-style=long-iso --group-directories-first -Tl --git"

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
        # Check if this is a worktree (has "+ " prefix)
        if [[ "$selected_branch" =~ ^\+[[:space:]] ]]; then
            # Extract branch name (remove "+ " prefix)
            local worktree_branch="${selected_branch#+ }"

            # Get the worktree path for this branch
            local worktree_path=$(git worktree list --porcelain | awk -v branch="$worktree_branch" '
                /^worktree / { path=$2 }
                /^branch / { if ($2 == "refs/heads/" branch) { print path; exit } }
            ')

            if [[ -n "$worktree_path" ]]; then
                # Get git repo root and current relative path
                local repo_root=$(git rev-parse --show-toplevel)
                local current_path=$(pwd)
                local relative_path="${current_path#$repo_root}"
                relative_path="${relative_path#/}"  # Remove leading slash if present

                # Construct target path in worktree
                local target_path="$worktree_path"
                if [[ -n "$relative_path" ]]; then
                    target_path="$worktree_path/$relative_path"
                fi

                # cd to target path, or fall back to worktree root
                if [[ -d "$target_path" ]]; then
                    cd "$target_path"
                else
                    cd "$worktree_path"
                fi
            else
                echo "Error: Could not find worktree path for branch '$worktree_branch'" >&2
                return 1
            fi
        else
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
    fi
}

# Function that uses fzf to add a worktree for an existing branch. Can be used with -a
# to include remote branches. Requires a path argument for the worktree location.
# Usage: gwt <path> [-a]
#   If path is an existing directory, creates worktree in <path>/<branch_name>
#   If path doesn't exist, uses it directly as the worktree path
gwt() {
    # Parse arguments to separate path and flags
    local worktree_base_path=""
    local opt=""

    for arg in "$@"; do
        if [[ "$arg" == "-a" ]]; then
            opt="-a"
        else
            worktree_base_path="$arg"
        fi
    done

    # Check if path argument was provided
    if [[ -z "$worktree_base_path" ]]; then
        echo "Error: Path argument required" >&2
        echo "Usage: gwt <path> [-a]" >&2
        return 1
    fi

    # Capture git branch output and check for errors
    local branch_output
    if ! branch_output=$(git branch $opt 2>&1); then
        echo "$branch_output" >&2
        return 1
    fi

    # Filter and pipe to fzf only if git branch succeeded
    local selected_branch=$(echo "$branch_output" | sed 's/^[[:space:]]*//' | fzf --reverse --info=inline)

    if [[ -n "$selected_branch" ]]; then
        # Extract clean branch name and determine worktree command
        local clean_branch=""
        local worktree_path=""

        # First, determine the clean branch name
        if [[ "$selected_branch" =~ ^remotes/origin/ ]]; then
            # Remote branch - extract name after remotes/origin/
            clean_branch="${selected_branch#remotes/origin/}"
        elif [[ "$selected_branch" =~ ^origin/ ]]; then
            # Remote branch - extract name after origin/
            clean_branch="${selected_branch#origin/}"
        elif [[ "$selected_branch" =~ ^\+[[:space:]] ]]; then
            # Already a worktree - show error
            echo "Error: Branch '${selected_branch#+ }' is already checked out in a worktree" >&2
            return 1
        elif [[ "$selected_branch" =~ ^\*[[:space:]] ]]; then
            # Current branch - show error
            echo "Error: Cannot create worktree for currently checked out branch" >&2
            return 1
        else
            # Local branch - use as-is
            clean_branch="$selected_branch"
        fi

        # Determine worktree path based on whether base path exists
        if [[ -d "$worktree_base_path" ]]; then
            # Existing directory - create subdirectory with branch name
            # Replace forward slashes with dashes to avoid nested directories
            local safe_branch_name="${clean_branch//\//-}"
            worktree_path="$worktree_base_path/$safe_branch_name"
        else
            # Non-existent path - use as-is
            worktree_path="$worktree_base_path"
        fi

        # Execute appropriate git worktree add command
        if [[ "$selected_branch" =~ ^remotes/origin/ ]] || [[ "$selected_branch" =~ ^origin/ ]]; then
            # Remote branch
            git worktree add -b "$clean_branch" "$worktree_path" "origin/$clean_branch"
        else
            # Local branch
            git worktree add "$worktree_path" "$clean_branch"
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
        # Check if this is a worktree (has "+ " prefix)
        if [[ "$lb" =~ ^\+[[:space:]] ]]; then
            # Extract branch name (remove "+ " prefix)
            local worktree_branch="${lb#+ }"

            # Get the worktree path for this branch
            local worktree_path=$(git worktree list --porcelain | awk -v branch="$worktree_branch" '
                /^worktree / { path=$2 }
                /^branch / { if ($2 == "refs/heads/" branch) { print path; exit } }
            ')

            if [[ -n "$worktree_path" ]]; then
                # Remove the worktree first
                git worktree remove "$worktree_path"
                # Then delete the local branch
                git branch -D "$worktree_branch"
            else
                echo "Error: Could not find worktree path for branch '$worktree_branch'" >&2
                return 1
            fi
        else
            # Regular branch - use git branch -D
            git branch -D "$lb"
        fi
    fi
}

# Shorthand for a clean git fetch: fetches and prunes both branches and tags
alias gfp="git fetch -pPt"
