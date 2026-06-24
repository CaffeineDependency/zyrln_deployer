#!/bin/bash

cd ~

echo "=> Updating and upgrading Termux packages..."
if ! pkg update; then
    echo "Error: pkg update failed."
    echo "Please check your internet connection or run 'termux-change-repo' to change your Termux mirror."
    exit 1
fi

# Track missing dependencies
MISSING_PKGS=""

# Check node
if ! command -v node >/dev/null 2>&1; then
    MISSING_PKGS="$MISSING_PKGS nodejs-lts"
fi

# Check git
if ! command -v git >/dev/null 2>&1; then
    MISSING_PKGS="$MISSING_PKGS git"
fi

# Install missing packages
if [ -n "$MISSING_PKGS" ]; then
    echo "=> Missing packages detected. Installing:${MISSING_PKGS}..."
    if ! pkg install -y $MISSING_PKGS; then
        echo "Error: Package installation failed."
        echo "Please check your internet connection or run 'termux-change-repo' to change your Termux mirror."
        exit 1
    fi
fi

# Separate check for npm (usually bundled with nodejs, only install if still missing)
if ! command -v npm >/dev/null 2>&1; then
    echo "=> npm not found. Installing npm..."
    if ! pkg install -y npm; then
        echo "Error: npm is missing and could not be installed."
        echo "Please check your internet connection or run 'termux-change-repo' to change your Termux mirror."
        exit 1
    fi
fi
if !pkg upgrade -y;then
    echo "Error: pkg upgrade failed."
    echo "Please check your internet connection or run 'termux-change-repo' to change your Termux mirror."
    exit 1
fi

# Final status
if [ -z "$MISSING_PKGS" ] && command -v npm >/dev/null 2>&1; then
    echo "=> nodejs, npm, and git are already installed. Current versions:"
    node -v
    npm -v
    git --version
else
    echo "=> All dependencies installed successfully!"
fi

echo ""
echo "=> Checking Wrangler version..."
if command -v wrangler >/dev/null 2>&1; then
    WRANGLER_VER=$(wrangler --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    WRANGLER_MAJOR=$(echo "$WRANGLER_VER" | cut -d. -f1)
else
    WRANGLER_MAJOR="none"
fi

# If wrangler is not exactly version 2, or doesn't exist
if [ "$WRANGLER_MAJOR" != "2" ]; then
    echo "=> Wrangler is version '$WRANGLER_MAJOR' (not 2) or missing. Installing wrangler@2..."
    npm install -g wrangler@2
else
    echo "=> Wrangler version 2.x ($WRANGLER_VER) is already installed."
fi


REPO_DIR="$HOME/zyrln_deployer"
if [ -d "$REPO_DIR" ]; then
    echo "=> Repository exists. Updating..."
    cd "$REPO_DIR" || exit 1
    git reset --hard HEAD
    git clean -fd
    git pull
else 
    echo "=> Cloning repository..."
    cd ~ || exit 1
    git clone https://github.com/CaffeineDependency/zyrln_deployer
fi

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR" || exit 1
    if [ ! -f deployer.sh ]; then
        echo "Error: deployer.sh not found. Something went wrong with the git cloning process."
        exit 1
    else 
        echo "running the deployer"
        chmod +x deployer.sh 
        ./deployer.sh
    fi
else
    echo "Error: Failed to create/access repository directory."
    exit 1
fi
