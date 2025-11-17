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
for package in $PACKAGES; do
  if ! stow -R -v -t "$HOME" -d "$DOTFILES_DIR" "$package" 2>&1; then
    echo "⚠️  Warning: Could not stow $package (conflicts may exist)"
  fi
done

# Setup git local configuration (user email and name)
setup_git_local_config() {
  local gitconfig_local="$HOME/.gitconfig.local"

  if [ ! -f "$gitconfig_local" ]; then
    echo ""
    echo "⚙️  Git configuration setup"
    echo "Please enter your git user information (this will be stored locally and not committed):"
    echo ""

    # Prompt for email
    read -p "Git email address: " git_email
    while [ -z "$git_email" ]; do
      echo "Email cannot be empty."
      read -p "Git email address: " git_email
    done

    # Prompt for name
    read -p "Git user name: " git_name
    while [ -z "$git_name" ]; do
      echo "Name cannot be empty."
      read -p "Git user name: " git_name
    done

    # Create .gitconfig.local
    cat > "$gitconfig_local" << EOF
[user]
	email = $git_email
	name = $git_name
EOF

    echo "✅ Git configuration saved to $gitconfig_local"
  else
    echo "ℹ️  Git local configuration already exists at $gitconfig_local (skipping)"
  fi
}
setup_git_local_config

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

