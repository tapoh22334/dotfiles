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

# Install Neovim formatters and linters
setup_nvim_tools() {
  echo ""
  echo "🔧 Installing Neovim formatters and linters..."

  # Check if npm is available
  if which npm >/dev/null 2>&1; then
    echo "  📦 Installing Node.js tools..."
    npm install -g prettier eslint 2>/dev/null || echo "  ⚠️  npm install failed (may need sudo or permissions)"
  else
    echo "  ⚠️  npm not found, skipping Node.js tools (prettier, eslint)"
  fi

  # Check if pip/pip3 is available
  if which pip3 >/dev/null 2>&1; then
    echo "  🐍 Installing Python tools..."
    pip3 install --user black isort flake8 mypy cpplint 2>/dev/null || echo "  ⚠️  pip3 install failed"
  elif which pip >/dev/null 2>&1; then
    echo "  🐍 Installing Python tools..."
    pip install --user black isort flake8 mypy cpplint 2>/dev/null || echo "  ⚠️  pip install failed"
  else
    echo "  ⚠️  pip not found, skipping Python tools (black, isort, flake8, mypy, cpplint)"
  fi

  # Install system tools via brew
  echo "  🍺 Installing system tools..."
  brew install shellcheck yamllint shfmt 2>/dev/null || echo "  ⚠️  Some brew packages may have failed"

  # Rust tools (if cargo is available)
  if which cargo >/dev/null 2>&1; then
    echo "  🦀 Installing Rust tools..."
    # stylua for Lua formatting
    cargo install stylua 2>/dev/null || echo "  ⚠️  cargo install stylua failed"
  else
    echo "  ℹ️  cargo not found, skipping stylua (can use brew install stylua instead)"
    brew install stylua 2>/dev/null || echo "  ⚠️  brew install stylua failed"
  fi

  echo "  ✅ Neovim tools installation complete"
}
setup_nvim_tools

echo ""
echo "✨ Dotfiles setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Open Neovim: nvim"
echo "  3. Lazy.nvim will auto-install plugins on first run"
echo "  4. Run :checkhealth to verify everything works"
echo ""

