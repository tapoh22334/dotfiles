#!/bin/sh

set -e

BREW_LIST="./packages/brewlist-full"
DOTFILES_DIR="./config"

# Install Homebrew if not installed
if ! which brew >/dev/null 2>&1; then
    echo "🚀 Installing Homebrew..."
    /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Set up Homebrew environment for Linux
if [ "$(uname)" = "Linux" ]; then
    eval "$( /home/linuxbrew/.linuxbrew/bin/brew shellenv )"
fi

# Install packages from the list
echo "🔧 Installing required packages..."
brew bundle

# Install stow if not installed
if ! which stow >/dev/null 2>&1; then
    echo "🚀 Installing stow..."
    brew install stow
fi

# Stow dotfiles
echo "📂 Applying dotfiles configuration..."

PACKAGES=$(find "$DOTFILES_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | xargs)
stow -R -v -t "$HOME" -d "$DOTFILES_DIR" $PACKAGES

# Install tmux plugin manager (TPM) and plugins
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "🔌 Installing tmux plugin manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Install tmux plugins
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "🎨 Installing tmux plugins..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

echo "✨ Dotfiles setup complete!"

