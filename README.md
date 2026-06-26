# Zyrln Deployer
This project provides an automated script to deploy zyrln cloudflare worker and google apps script,designed with v2 pre4 in mind .
##  (Quick Start)
If you just want to get your project deployed without worrying about the technical details, follow these simple steps.
**Requirements:**
 * The **Termux** app installed (download it from F-Droid or github , not Google Play Store).
**Installation & Deployment:**
Open Termux, paste the following command, and hit enter:
```bash
curl -fsSL -o $PREFIX/tmp/setup.sh https://raw.githubusercontent.com/CaffeineDependency/zyrln_deployer/refs/heads/main/setup2.sh && bash $PREFIX/tmp/setup.sh

```
**What to Expect:**
 * **First Run:** The script will download  required dependencies like nodejs git and wrangler for worker deployment and proot-distro and alpine backup file for google apps script deployment 
 * **Future Runs:** If you run the command again later, it will skip the download and deploy much faster.
 * if you're having trouble with the Cloudflare worker deployment you can run this command instead
 ```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaffeineDependency/zyrln_deployer/refs/heads/main/setup.sh)"

```  
 

## How It Works 
If you want to know exactly what this one-liner is doing to your Termux environment, here is the technical breakdown.
### for cf worker deployment 
 1. **Environment Check:** The script checks if nodejs,git and wrangler are installed and will install them if they are not
 2. **Project Cloning:** Once the environment ready, it clones the deployment repository.
 3. **Execution:** Finally, it runs the deployment script which will clone the zyrln git repository, navigate to the deploy folder,edit the wrangler.toml and worker.js files based on your input, and deploy using wrangler.
### for google apps script 
 1. it cheks for proot-distro and an alpine container, if they do not exist it downloads proot-distro and a alpine backup that comes pre installed with glasp(this isn't a typo,read note2), it's in the releases of this repo named alpineReadyglasp.tar.xz .
 2. the script then logs in to your proot-distro alpine container and clones this project there and runs the gasDeployer.sh script which deploys your apps script via glasp 
 

### notes
 1. this uses wrangler v2 that seems to work better on termux than newer versions, it will give a warning:(Unexpected fields found in migrations field: "new_sqlite_classes")
based on experience its not important and your worker will work the same
 2. this uses glasp instead of clasp ,because clasp doesn't work with the new nodejs security patch thats present in node versions above 20
this is the link to the glasp project:
https://github.com/takihito/glasp
its a lightweight alternative to clasp written in go that doesn't need dependencies 
 3. if you're already using proot-distro with an alpine container, either delet the alpine container or install git and glasp manually (or just manually upload your apps script at this point i don't think you'll need much help)
