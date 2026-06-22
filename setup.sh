#!/bin/bash

cd ~

echo "=> Updating and upgrading Termux packages..."
if ! pkg update -y && pkg upgrade -y; then
    echo "Error: pkg update or upgrade failed."
    echo "Please check your internet connection or run 'termux-change-repo' to change your Termux mirror."
    exit 1
fi

echo "=> Checking nodejs, npm, and git..."
# Check if all three exist
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    echo "=> Missing packages. Installing core dependencies (nodejs, git)..."
    if ! pkg install -y nodejs git; then
        echo "Error: Core pkg installation failed."
        echo "Please check your internet connection or run 'termux-change-repo' to change your Termux mirror."
        exit 1
    fi

    # Check if npm is now available (usually comes with nodejs)
    if ! command -v npm >/dev/null 2>&1; then
        echo "=> npm not found after nodejs installation. Installing npm..."
        if ! pkg install -y npm; then
            echo "Error: npm is missing and could not be installed."
            echo "Please check your internet connection or run 'termux-change-repo' to change your Termux mirror."
            exit 1
        fi
    else
        echo "npm is available (bundled with nodejs). Proceeding..."
    fi
else
    echo "=> nodejs, npm, and git are already installed. Current versions:"
    node -v
    npm -v
    git --version
fi

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

echo "=> Checking Clasp version..."
INSTALL_CLASP=true
if command -v clasp >/dev/null 2>&1; then
    CLASP_VER=$(clasp --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    if [ -n "$CLASP_VER" ]; then
        CLASP_MAJOR=$(echo "$CLASP_VER" | cut -d. -f1)
        CLASP_MINOR=$(echo "$CLASP_VER" | cut -d. -f2)

        if [ "$CLASP_MAJOR" -ge 3 ] && [ "$CLASP_MINOR" -ge 3 ]; then
            INSTALL_CLASP=false
        fi
    fi
fi

if [ "$INSTALL_CLASP" = true ]; then
    echo "=> Installing/updating Clasp..."
    if ! npm install -g @google/clasp; then
        echo "Error: Clasp installation failed."
        echo "Please check your internet connection."
        exit 1
    fi
else
    echo "=> Clasp version $CLASP_VER is already up to date (>= 3.3)."
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
