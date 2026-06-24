# Zyrln Deployer
This project provides an automated script to deploy zyrln cloudflare worker,designed with v2 pre4 in mind .
##  (Quick Start)
If you just want to get your project deployed without worrying about the technical details, follow these simple steps.
**Requirements:**
 * The **Termux** app installed (download it from F-Droid or github , not Google Play Store).
**Installation & Deployment:**
Open Termux, paste the following command, and hit enter:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaffeineDependency/zyrln_deployer/refs/heads/main/setup.sh)"

```
**What to Expect:**
 * **First Run:** The script will download a required dependencies like nodejs git and wrangler
 * **Future Runs:** If you run the command again later, it will skip the download and deploy much faster.
 

## (Under the Hood)
If you want to know exactly what this one-liner is doing to your Termux environment, here is the technical breakdown.
### How It Works
 1. **Environment Check:** The script checks if nodejs,git and wrangler are installed and will install them if they are not
 2. **Project Cloning:** Once the environment ready, it clones the deployment repository.
 3. **Execution:** Finally, it runs the deployment script which will clone the zyrln git repository, navigate to the deploy folder,edit the wrangler.toml and worker.js files based on your input, and deploy using wrangler. 
**note:**
this uses wrangler v2 that seems to work better on termux than newer versions, it will give a warning
    - Unexpected fields found in migrations field:
  "new_sqlite_classes"
based on experience its not important and your worker will work the same
**note:**
this was originally supposed to also deploy your google apps script using clasp ,but clasp login broke at some point.i think it was because of the new nodejs security patch. i even tried using a ready made alpine proot-distro container that had an older version of nodejs, but clasp login broke after 2 runs.
if you know how to fix clasp login please contact me @CaffeineDependency on telegram. 
