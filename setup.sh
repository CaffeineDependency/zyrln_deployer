#!/bin/bash

set -e

echo "========================================"
echo " Starting Termux Environment Setup..."
echo "========================================"

# Update packages and install/update proot-distro
echo "[*] Updating repositories and checking proot-distro..."
pkg update -y
pkg install proot-distro -y

BACKUP_URL="https://github.com/CaffeineDependency/zyrln_deployer/releases/download/assets/alpineReadyDeploy.tar.xz"
REPO_URL="https://github.com/CaffeineDependency/zyrln_deployer.git"
BACKUP_FILE="alpineReadyDeploy.tar.xz"

# Check if the Alpine container exists

if ! proot-distro list 2>&1 | grep -q "alpine"; then
    echo "[*] Alpine container not found. Downloading backup..."
    curl -L -o "$BACKUP_FILE" "$BACKUP_URL"
    
    echo "[*] Installing Alpine ..."
    proot-distro restore "$BACKUP_FILE"
    
    rm "$BACKUP_FILE"
else
    echo "[*] Alpine container is already installed ."
fi

# Log into Alpine, handle the git repo, and run the deployer
echo "[*] Booting into Alpine to deploy..."

proot-distro login alpine -- sh -c '
    cd ~
    
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
    chmod +x deployer.sh
    ./deployer.sh
'

echo "========================================"
echo " Setup and Deployment Complete!"
echo "========================================"
echo ""
echo "You can clean your Termux data by running:"
echo "proot-distro remove alpine"
echo "The deployer will have to download the asset file again if you run it."
echo "I suggest not running the clean-up command if you plan to make more deployments."
