# Zyrln Deployer
This project provides an automated script to deploy zyrln google apps script and cloudflare worker.
By leveraging proot-distro, it sets up a pre-configured Alpine Linux container so you don't have to manually wrestle with dependencies and environment configurations.
##  (Quick Start)
If you just want to get your project deployed without worrying about the technical details, follow these simple steps.
**Requirements:**
 * An Android device.(aarch64)
 * this will only work on an aarch64 device (most modern androids are aarch64)
 * The **Termux** app installed (download it from F-Droid or github , not Google Play Store).
**Installation & Deployment:**
Open Termux, paste the following command, and hit enter:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaffeineDependency/zyrln_deployer/refs/heads/main/setup.sh)"

```
**What to Expect:**
 * **First Run:** The script will download a required environment file (about **180MB**). Make sure you have a stable internet connection.
 * **Storage:** Once everything is unpacked and ready, it will use about **800MB** of storage space on your device.
 * **Future Runs:** If you run the command again later, it will skip the large download and deploy much faster.
 
**Storage & Uninstallation**

The pre-configured Alpine container is heavy. Uncompressed, the rootfs expands to approximately **800MB**.
If you need to free up storage space on your device after your deployments are finished, you can completely remove the environment by running this command in Termux:
```bash
proot-distro remove alpine

```
**Note:** If you run the uninstallation command, the deployer will need to re-download the **180MB** backup file the next time you use the one-liner setup script.

## (Under the Hood)
If you want to know exactly what this one-liner is doing to your Termux environment, here is the technical breakdown.
### How It Works
Instead of compiling or installing dependencies one by one inside Termux, this setup script uses a pre-built environment strategy:
 1. **Environment Check:** The script checks if an alpine container already exists in your proot-distro setup.
 2. **Rootfs Restoration:** If the container is missing, it downloads a custom tar.xz Alpine backup file directly from this repository's Releases. It then restores this backup using proot-distro restore.
 3. **Project Cloning:** Once the environment is up, it clones the deployment repository.
 4. **Execution:** Finally, it runs the deployment script inside the Alpine container to push your code to either Google Apps Script or Cloudflare Workers.
### Pre-installed Tooling
The downloaded Alpine image acts as a ready-to-go deployment image. It comes strictly pre-configured with:
 * nodejs
 * @google/clasp (for Google Apps Script)
 * wrangler (for Cloudflare Workers)
### ⚠️ Important Caveat: Existing Alpine Containers
The script checks for the existence of an alpine container to save bandwidth and skip the **180MB** download on subsequent runs.
> **Warning:** If you are a power user who already has a standard alpine container installed via proot-distro for other projects, this script will detect it and **skip the download**. If your existing container does not already have nodejs, clasp, and wrangler installed, the deployment script will fail.
> 

