#!/bin/bash
cd ~
workerSetup(){
    
    echo "========================================"
    echo " Starting Termux Environment Setup..."
    echo "========================================"
    
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
    else
        echo "npm is good to go, moving on"
    fi
    echo "upgrading Termux packages ..."
    echo "***NOTICE***"
    echo "if prompted during the upgrade, please choose y"
    echo "***^^^^***"
    sleep 4
    if ! pkg upgrade -y; then
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
}

gasSetup(){
    

    echo "========================================"
    echo " Starting Termux Environment Setup..."
    echo "========================================"
    
    # Update packages and install/update proot-distro
    echo "[*] Updating repositories and checking proot-distro..."
    echo "if you don't have proot-distro installed it will need to download packages"
    echo "they will come up to 100mb of download if you haven't used termux before"
    echo "the next time you run this script it will skip the download"
    echo "do you wish to continue?"
    
    choice2=""
    until [[ "$choice2" =~ ^[yYnN]$ ]]; do
        read -p "Continue? (y/n): " choice2
        [[ "$choice2" =~ ^[nN]$ ]] && exit 1
    done
    
    if ! pkg update -y;then
    echo "failed to update packages, please check your internet connection or run termux-change-repo "
    exit 1
    fi
    if ! pkg install proot-distro -y;then
    echo "failed to update packages, please check your internet connection or run termux-change-repo "
    exit 1
    fi
    
    
    BACKUP_URL="https://github.com/CaffeineDependency/zyrln_deployer/releases/download/assets/alpineReadyglasp.tar.xz"
    REPO_URL="https://github.com/CaffeineDependency/zyrln_deployer.git"
    BACKUP_FILE="alpineReadyglasp.tar.xz"
    
    # Check if the Alpine container exists
    if ! proot-distro list 2>&1 | grep -q "alpine"; then
        echo "[*] Alpine container not found. Downloading backup..."
        if ! curl -L -o "$BACKUP_FILE" "$BACKUP_URL"; then
            echo "Error: Failed to download the backup file."
            echo "Please check your internet connection and try again."
            exit 1
        fi
  
        echo "[*] Installing Alpine..."
        if ! proot-distro restore "$BACKUP_FILE"; then
            echo "Error: Failed to restore the Alpine container."
            rm -f "$BACKUP_FILE"
            exit 1
        fi
        
        rm "$BACKUP_FILE"
    else
        echo "[*] Alpine container is already installed."
    fi
    
    # Log into Alpine, handle the git repo, and run the deployer
    echo "[*] Booting into Alpine to deploy..."
    
    proot-distro login alpine -- sh -c '
        cd ~
        export PATH="/root/.local/bin:$PATH"
        
        # Try to enter the directory; suppress the error if it fails
        if ! cd ~/zyrln_deployer 2>/dev/null; then
            echo "[*] Repository not found. Cloning..."
            git clone "'"$REPO_URL"'" ~/zyrln_deployer
            
            # Move into the newly cloned directory
            cd ~/zyrln_deployer
        else
            echo "[*] Repository exists. Resetting and pulling..."
            # We are already in the directory because the "cd" in the "if" statement succeeded
            git reset --hard HEAD
            git clean -fd
            git pull
        fi
        
        # Make deployer executable and run it
        echo "[*] Running the deployer..."
        chmod +x gasDeployer.sh
        ./gasDeployer.sh
    '
    

}

show_menu() {
    echo ""
    echo "================================"
    echo "What would you like to deploy?"
    echo "1) Google Apps Script"
    echo "2) Cloudflare worker"
    echo "q) quit"
    echo "if you're new to zyrln deploy your Cloudflare worker first "
    echo "================================"
}

main() {
    while true; do
        show_menu
        read -p "Choice: " choice
        
        case $choice in
            1)
                gasSetup || exit 1
                ;;
            2)
                workerSetup || exit 1
                ;;
            q|Q)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice"
                ;;
        esac
    done
}

main
