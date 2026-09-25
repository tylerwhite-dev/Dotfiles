## Generate a SSH key pair (private/public):

```bash
ssh-keygen -t rsa -C "..."
```

or even better:

```bash
ssh-keygen -t rsa -b 4096 -C "..."
```

It also possible to use ed25519. There are pros and cons, but personally I've had some issues and that is the reason I've chosen to stick to 4096 rsa for now.

### Copy the contents of the public SSH key

macOS:

```bash
pbcopy < ~/.ssh/id_rsa.pub
```

GNU/Linux
using xclip

```bash
xclip -sel clip < ~/.ssh/id_rsa.pub
```

or wl-clipboard

```bash
wl-copy < ~/.ssh/id_rsa.pub
```

Windows Command Line:

```bash
type %userprofile%\.ssh\id_rsa.pub | clip
```

Git Bash on Windows / Windows PowerShell:

```bash
cat ~/.ssh/id_rsa.pub
```

### Copy the public SSH key to GitHub

Copy the contents of the to your SSH keys to your GitHub account settings (https://github.com/settings/keys).

### Test the SSH key

```bash
ssh -T git@github.com
```

### Add the key to the ssh-agent

```bash
ssh-add ~/.ssh/id_rsa
```

You should not be asked for a username or password. If it works, your SSH key is correctly configured.

## Create a repo.

Make sure there is at least one file in it (even just the README.md)

### Remote settings

Change directory into the local clone of your repository (if you're not already there) and run:

```bash
git remote set-url origin git@github.com:username/your-repository.git
```

If the repo is under an organization the command is slightly different:

```bash
git remote set-url origin git@github.com:organization/your-repo.git
```

Now try editing a file (try the README) and then do:

```bash
git add -A
git commit -am "Update README.md"
git push
```