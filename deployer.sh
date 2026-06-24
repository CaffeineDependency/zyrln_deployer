#!/bin/bash
cd ~
setup_environment() {
    if cd ~/zyrln; then
        echo "Updating git..."
        git reset --hard HEAD
        git clean -fd
        git pull
    else
        # Clone repository
        echo "Cloning repo..."
        if ! git clone https://github.com/ajavadinezhad/zyrln.git ~/zyrln; then
            echo "Error: Failed to clone repository."
            exit 1
        fi
        cd ~/zyrln || exit 1
    fi
}

deploy_worker() {
    if ! cd ~/zyrln/relay/deploy/cloudflare; then
        echo "Error: Failed to navigate to directory."
        exit 1
    fi

    echo "Please login to your Cloudflare account and authorize wrangler"
    echo " If you're not redirected, copy and paste the long URL in your browser"

    if ! wrangler login; then
        echo "Error: Failed to login to Cloudflare."
        exit 1
    fi
    echo ""
    echo " Before starting this process"
    echo " make sure you visit cloudflare workers page at least once if you haven't Before on this account"
    echo ""
    # Get user inputs
    read -p "Please choose a worker name: " workername
    echo "Please enter key2 (ZYRLN_RELAY_KEY)"
    echo "This can be anything you choose, but has to be the same in your google script."
    echo "Write it down or memorize it."
    read -p "key2: " key2
    read -p "Please enter your Cloudflare username: " cfusername

    if [ -z "$workername" ] || [ -z "$key2" ] || [ -z "$cfusername" ]; then
        echo "Error: All fields are required."
        exit 1
    fi

    echo ""
    echo " Your worker name is : $workername"
    echo " Your key2 is : $key2"
    echo " Your Cloudflare username is : $cfusername"
    
    until [[ "$choice1" =~ ^[yYnN]$ ]]; do
    read -p "Continue? (y/n): " choice1
    [[ "$choice1" =~ ^[nN]$ ]] && exit 1
    done
    # Update wrangler.toml
    sed -i "s/mine/$workername/" wrangler.toml
    awk -v key="$key2" 'NR==8 {print "[vars]"; print "ZYRLN_RELAY_KEY = \"" key "\""} 1' wrangler.toml > tmp_wrangler.toml && mv tmp_wrangler.toml wrangler.toml
    # Update worker.js
    WORKER_HOST="$workername.$cfusername.workers.dev"
    sed -i "s/CHANGE_ME_WORKER_HOST/$WORKER_HOST/" worker.js

    # Deploy
    echo "Deploying worker..."
    if ! wrangler deploy; then
        if ! wrangler publish;then
            echo "Couldn't deploy worker"
            exit 1
        fi   
    fi

    echo "Deployment completed successfully!"
    echo "Your worker URL : $WORKER_HOST"
}

deploy_gas() {
    echo " *****IMPORTANT*****"
    echo "Before starting this process:"
    echo "Go to script.google.com, login,"
    echo "go to settings, and turn Google Script API on."
    echo "refresh the page and make sure it stays on after refreshing"
    echo "make sure you're using a stable vpn befor continuing the deployment process"

    until [[ "$choice2" =~ ^[yYnN]$ ]]; do
        read -p "Continue? (y/n): " choice2
        [[ "$choice2" =~ ^[nN]$ ]] && exit 1
    done
    # Note: Double check if this is the correct path for GAS.
    # Navigating to the Cloudflare folder for GAS deployment.
    if ! cd ~/zyrln/relay/deploy/apps-script; then
        echo "Error: Failed to navigate to directory"
        exit 1
    fi

    if [ ! -f "Code.gs" ]; then
        echo "Error: Code.gs not found."
        exit 1
    fi
    echo " Please login to your google account and authorize clasp"
    echo " If you're not redirected, copy and paste the long URL in your browser"
    echo "This might take a few seconds..."
    if ! clasp login;then
        echo "normal login failed ,attempting another way..."
        echo "after authorization you will be redirected to a page that wont open "
        echo "fully copy its link and paste it here"
        if ! clasp login --no-localhost;then
        echo "clasp failed to login "
        exit 1
        fi
    fi

    # Get values from user
    echo "Enter a random password"
    echo "This will be your first key/key1 also present in your config"
    read -rp "AUTH_KEY: " AUTH_KEY

    echo "Enter EXIT_RELAY_URL"
    echo "For Cloudflare enter your Cloudflare worker URL"
    echo "For VPS enter http://IP:8787/relay"
    read -rp "EXIT_RELAY_URL: " EXIT_RELAY_URL

    echo "Enter EXIT_TUNNEL_URL"
    echo "For Cloudflare leave empty"
    echo "For VPS: http://YOUR_VPS_IP:8787/tunnel"
    read -rp "EXIT_TUNNEL_URL: " EXIT_TUNNEL_URL

    echo "Enter EXIT_RELAY_KEY"
    echo "This is the same as key2 or ZYRLN_RELAY_KEY"
    read -rp "EXIT_RELAY_KEY: " EXIT_RELAY_KEY

    echo "Your AUTH_KEY is : $AUTH_KEY"
    echo "Your EXIT_RELAY_URL is : $EXIT_RELAY_URL"
    echo "Your EXIT_TUNNEL_URL is : $EXIT_TUNNEL_URL"
    echo "Your EXIT_RELAY_KEY is : $EXIT_RELAY_KEY"

    until [[ "$choice3" =~ ^[yYnN]$ ]]; do
    read -p "Continue? (y/n): " choice3
    [[ "$choice3" =~ ^[nN]$ ]] && exit 1
    done
    # Sanitize URL
    EXIT_RELAY_URL=$(echo "$EXIT_RELAY_URL" | xargs)
    [[ ! "$EXIT_RELAY_URL" =~ ^https?:// ]] && EXIT_RELAY_URL="https://$EXIT_RELAY_URL"
    EXIT_RELAY_URL="${EXIT_RELAY_URL%/}"

    FILE="Code.gs"

    # Function to escape special characters for sed (using | as delimiter)
    escape_sed() {
        sed 's/\\/\\\\/g; s/|/\\|/g; s/&/\\&/g; s/"/\\"/g' <<< "$1"
    }

    AUTH_KEY_ESC=$(escape_sed "$AUTH_KEY")
    RELAY_URL_ESC=$(escape_sed "$EXIT_RELAY_URL")
    TUNNEL_URL_ESC=$(escape_sed "$EXIT_TUNNEL_URL")
    RELAY_KEY_ESC=$(escape_sed "$EXIT_RELAY_KEY")

    # Update file in-place
    sed -i \
        -e "s|const AUTH_KEY = \".*\"|const AUTH_KEY = \"${AUTH_KEY_ESC}\"|" \
        -e "s|const EXIT_RELAY_URL = \".*\"|const EXIT_RELAY_URL = \"${RELAY_URL_ESC}\"|" \
        -e "s|const EXIT_TUNNEL_URL = \".*\"|const EXIT_TUNNEL_URL = \"${TUNNEL_URL_ESC}\"|" \
        -e "s|const EXIT_RELAY_KEY = \".*\"|const EXIT_RELAY_KEY = \"${RELAY_KEY_ESC}\"|" \
        "$FILE"

    echo "File updated."
    echo ""

    # Delete the hidden clasp config files to sever the link to the old project
    rm -f .clasp.json
    rm -f .claspignore

    echo ""
    echo "Initializing brand new clasp web app project..."
    clasp create --type standalone --title "my_script_$(date +%Y%m%d_%H%M%S)" || exit 1

    echo ""
    echo "Generating appsscript.json configuration..."

# Bug fix: EOF marker must not be indented
cat > appsscript.json << 'EOF'
{
  "timeZone": "Europe/Berlin",
  "dependencies": {},
  "exceptionLogging": "STACKDRIVER",
  "runtimeVersion": "V8",
  "webapp": {
    "executeAs": "USER_DEPLOYING",
    "access": "ANYONE_ANONYMOUS"
  }
}
EOF

    echo ""
    echo "Pushing local files to Google Apps Script..."
    if ! clasp push --force; then
        echo "Error: Failed to push code to Google Apps Script"
        exit 1
    fi

    echo ""
    echo "Creating live deployment..."
    DEPLOY_OUTPUT=$(clasp deploy --description "Fresh CLI deployment")
    echo "$DEPLOY_OUTPUT"

    # Extract the deployment ID
    DEPLOY_ID=$(echo "$DEPLOY_OUTPUT" | awk '/Deployed/ {print $2}')

    if [ -n "$DEPLOY_ID" ]; then
        echo ""
        echo "---------------------------------------------------"
        echo "🚀 NEW WEB APP LIVE!"
        echo "URL: https://script.google.com/macros/s/$DEPLOY_ID/exec"
        echo "---------------------------------------------------"
        echo ""
        echo "NEXT STEPS:"
        echo "1. Open this URL in a browser and authorize your script."
        echo "2. If you get a Google Drive error, use a different browser or incognito mode."
        echo "3. After your script is authorized, it should say 'relay active'."
        echo "4. Google's authorization process is a bit buggy. Make sure your script is"
        echo "   authorized and says 'relay active'."
        echo ""
        sleep 8
    else
        echo "Error: Could not parse deployment ID."
        echo "Full output was:"
        echo "$DEPLOY_OUTPUT"
        exit 1
    fi
    echo " This is your zyrln config : "
    echo "-----------------------------------"
# Bug fix: EOF marker must not be indented
cat <<EOF
{
  "key" : "$AUTH_KEY",
  "url" : "https://script.google.com/macros/s/$DEPLOY_ID/exec"
}
EOF
    echo "-----------------------------------"
}

show_menu() {
    echo ""
    echo "================================"
    echo "What would you like to deploy?"
    echo "1) Cloudflare Worker"
    echo "2) Google Apps Script"
    echo "q) Quit"
    echo "r) Reset and update the zyrln git repository"
    echo "If you're new to zyrln, deploy your Cloudflare worker first"
    echo "================================"
}

main() {
    setup_environment

    while true; do
        show_menu
        read -p "Choice: " choice

        case $choice in
            1)
                if deploy_worker; then
                    echo "✓ Deployment successful!"
                else
                    echo "✗ Worker deployment failed"
                fi
                cd ~/zyrln || exit 1
                git reset --hard HEAD
                git clean -fd
                ;;
            2)
                if deploy_gas; then
                    echo "✓ Deployment successful!"
                else
                    echo "✗ Google Apps Script deployment failed"
                fi
                cd ~/zyrln || exit 1
                git reset --hard HEAD
                git clean -fd
                ;;
            q|Q)
                echo "Goodbye!"
                cd ~/zyrln || exit 1
                git reset --hard HEAD
                git clean -fd
                exit 0
                ;;
            r|R)
                rm -rf ~/zyrln
                if setup_environment; then
                    echo "zyrln git reset and up to date"
                else
                    echo "Something went wrong when trying to fetch zyrln git repo, please make sure you have a stable internet connection"
                    exit 1
                fi
                ;;
            *)
                echo "Invalid choice"
                ;;
        esac
    done
}

main
