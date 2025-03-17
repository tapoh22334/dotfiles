#!/bin/bash

set -e

BREW_LIST="./packages/brewlist-full"
DOTFILES_DIR="./config"
mapfile -t PACKAGES < <(find "$DOTFILES_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

# Check if Git is installed, install it if not
if ! command -v git &> /dev/null; then
    echo "⚙️ Installing Git..."
    if [[ "$(uname)" == "Darwin" ]]; then
        # For macOS, use the system package manager or Xcode command line tools
        xcode-select --install || brew install git
    else
        # For Linux, install Git using the package manager
        if [[ "$(uname)" == "Linux" ]]; then
            sudo apt update
            sudo apt install -y git || sudo yum install -y git
        fi
    fi
fi

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo "🚀 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Set up Homebrew environment for Linux
if [[ "$(uname)" == "Linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Install packages from the list
echo "🔧 Installing required packages..."
brew bundle

# Stow dotfiles
echo "📂 Applying dotfiles configuration..."

stow -v -t "$HOME" -d "$DOTFILES_DIR" "${PACKAGES[@]}"

echo "✨ Dotfiles setup complete!"

