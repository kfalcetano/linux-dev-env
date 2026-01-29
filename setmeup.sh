#!/bin/bash

# Function to ensure .bash_aliases is sourced in .bashrc
ensure_bash_aliases_source() {
    local bashrc="$HOME/.bashrc"
    local source_block='if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi'

    if [ -f "$bashrc" ]; then
        # Check if .bash_aliases is already mentioned in the file
        if ! grep -q ".bash_aliases" "$bashrc"; then
            echo "Appending .bash_aliases sourcing block to $bashrc"
            echo -e "\n# Alias definitions\n$source_block" >> "$bashrc"
        else
            echo ".bash_aliases sourcing already present in $bashrc. Skipping."
        fi
    else
        echo ".bashrc not found. Creating it with aliases sourcing."
        echo -e "$source_block" > "$bashrc"
    fi
}

# Get the absolute path of the dotfiles directory
DOTFILES_DIR=$(dirname "$(readlink -f "$0")")/dotfiles

# 1. Create symbolic links for dotfiles
echo "📄 Linking dotfiles from $DOTFILES_DIR..."
for file in "$DOTFILES_DIR"/.[^.]*; do
    basename=$(basename "$file")
    target="$HOME/$basename"
    ln -sfv "$file" "$target"
done

echo ""
# 2. Install Tmux Plugin Manager (TPM)
echo "📦 Installing TPM to $TPM_PATH..."
TPM_PATH="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_PATH" ]; then
    echo "Existing TPM directory found. Deleting for a fresh install..."
    rm -rf "$TPM_PATH"
fi

mkdir -p "$(dirname "$TPM_PATH")"
git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"

echo ""
# 3. Install KeVim config
echo " Installing Kevim to $VIM_PATH..."
VIM_PATH="$HOME/.config/nvim"
if [ -d "$VIM_PATH" ]; then
    echo "Existing vim config directory found. Deleting for a fresh install..."
    rm -rf "$VIM_PATH"
fi
mkdir -p "$(dirname "$VIM_PATH")"
git clone https://github.com/kfalcetano/kevim "$VIM_PATH"

echo ""
# 4. Append bash aliases to bashrc if needed
echo " Ensuring .bash_aliases is sourced..."
ensure_bash_aliases_source

echo""
echo "✅ Setup complete! If changes aren't visible, run: source ~/.bashrc"
