import os, re, time, shutil, subprocess

PROJECT = "/root/my_app/orixon"
os.chdir(PROJECT)

GH_USER = "SkRamjan9615"
GH_REPO = "orixon"
FNAME = "google0bd7234e6b90e7f7.html"
CONTENT = f"google-site-verification: {FNAME}"

TOKEN = ""
if os.path.exists("/root/.orixon_gh_token"):
    TOKEN = open("/root/.orixon_gh_token").read().strip()

if not TOKEN:
    rem = subprocess.run(["git", "remote", "get-url", "origin"], capture_output=True, text=True).stdout.strip()
    m = re.search(r"(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})", rem)
    if m:
        TOKEN = m.group(1)

if not TOKEN:
    TOKEN = input("\nPaste your GitHub Token (ghp_...) and press Enter: ").strip()

if not TOKEN:
    print("[!] GitHub Token ছাড়া ফাইল আপলোড হবে না।")
    raise SystemExit(1)

open("/root/.orixon_gh_token", "w").write(TOKEN)
os.makedirs("docs", exist_ok=True)
open(f"docs/{FNAME}", "w").write(CONTENT)
open(FNAME, "w").write(CONTENT)
open("docs/.nojekyll", "w").close()

auth_url = "https://" + GH_USER + ":" + TOKEN + "@github.com/" + GH_USER + "/" + GH_REPO + ".git"
subprocess.run(["git", "remote", "set-url", "origin", auth_url], check=False)

subprocess.run(["git", "add", f"docs/{FNAME}", FNAME, "docs/.nojekyll"], check=False)
subprocess.run(["git", "commit", "-m", "Add Google Search Console verification file"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("[*] Uploading verification file to main branch...")
subprocess.run(["git", "push", "-f", auth_url, "main"], check=False)

gh_tmp = "/tmp/orixon_gsc_live"
shutil.rmtree(gh_tmp, ignore_errors=True)
shutil.copytree("docs", gh_tmp)
open(f"{gh_tmp}/{FNAME}", "w").write(CONTENT)
open(f"{gh_tmp}/.nojekyll", "w").close()
subprocess.run(["git", "init"], cwd=gh_tmp, stdout=subprocess.DEVNULL)
subprocess.run(["git", "checkout", "-b", "gh-pages"], cwd=gh_tmp, stdout=subprocess.DEVNULL)
subprocess.run(["git", "config", "user.name", "ORIXON"], cwd=gh_tmp)
subprocess.run(["git", "config", "user.email", "noreply@orixon.org"], cwd=gh_tmp)
subprocess.run(["git", "add", "-A"], cwd=gh_tmp, stdout=subprocess.DEVNULL)
subprocess.run(["git", "commit", "-m", "Deploy Google verification file"], cwd=gh_tmp, stdout=subprocess.DEVNULL)
print("[*] Uploading verification file to gh-pages branch...")
subprocess.run(["git", "push", "-f", auth_url, "gh-pages"], cwd=gh_tmp, check=False)
shutil.rmtree(gh_tmp, ignore_errors=True)

check_url = "https://skramjan9615.github.io/orixon/" + FNAME
print("[*] Waiting for GitHub Pages to go live...")
for i in range(1, 25):
    out = subprocess.run(["curl", "-sL", check_url + "?v=" + str(int(time.time()))], capture_output=True, text=True).stdout.strip()
    if "google-site-verification" in out:
        print("\n=======================================================")
        print("[100% LIVE ON WEBSITE] ফাইলটি ওয়েবসাইটে লাইভ হয়ে গেছে!")
        print("এখন ব্রাউজারে গিয়ে শুধু VERIFY বাটনে ট্যাপ করুন!")
        print("=======================================================")
        raise SystemExit(0)
    print(f"    Checking ({i}/24)... অপেক্ষা করুন (4s)")
    time.sleep(4)
