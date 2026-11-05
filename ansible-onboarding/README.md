# Ansible Workstation Setup

## Completed By

Maneetta Antony

## Project Objective

This project sets up a consistent Ansible controller workstation. The goal is a repeatable local environment where Ansible, its linters, and the Git hooks are installed in one isolated place, so every change is checked the same way before it is committed. The workstation is also set up so it can be used for the controlled training environment in later labs.

## Controller Environment

- **Operating system:** macOS 27.0 (build 26A428)
- **Environment type:** Native macOS (not Ubuntu, WSL2, VMware, VirtualBox, or a cloud VM)
- **Python version:** Python 3.14.3 (inside the project virtual environment)
- **Shell:** zsh

## Installed Tools

| Tool | Version | Purpose |
|---|---|---|
| Ansible (ansible-core) | 2.21.6 | Automation engine |
| Ansible Lint | 26.10.1 | Checks playbooks and roles for best practices |
| YAML Lint (yamllint) | 1.38.0 | Checks YAML syntax and formatting |
| pre-commit | 4.7.0 | Runs the configured checks before each commit |
| Git | 2.54.0 | Version control |
| OpenSSH | 10.3p1 | Secure shell access to managed hosts |

All Python tools are pinned in `requirements.txt` so that everyone installs the same versions.

## Python Virtual Environment

The project uses a virtual environment in `.venv/`. It keeps the Ansible and lint tools separate from the system Python and from other projects, so a global upgrade cannot break this project and different projects can use different versions. The `.venv/` folder is listed in `.gitignore`, so it is never committed.

To activate it:

```bash
cd ~/ansible-onboarding
source .venv/bin/activate
```

> This repository is currently located at `~/Workspaces/DMI-C3-G3/dmi-c3-g3-demo-apps/ansible-onboarding`. Use that path in place of `~/ansible-onboarding` if you cloned it there.

To install the pinned tools into the environment:

```bash
pip install -r requirements.txt
```

## VS Code Configuration

### Installed extensions

- **Ansible** (Red Hat) - Ansible syntax support and linting
- **YAML** (Red Hat) - YAML validation and formatting
- **Python** (Microsoft) - Python language support

### How VS Code uses `.venv`

`.vscode/settings.json` points both the Python extension and the Ansible extension to `${workspaceFolder}/.venv/bin/python`. VS Code therefore uses the project's virtual environment instead of the system Python, so the editor's linting and the command-line tools use the same versions. The file also enables Ansible linting, YAML validation, trailing-whitespace trimming, and format-on-save.

## Ansible Configuration

`ansible.cfg` holds project-wide Ansible settings so no one has to pass them on the command line. It sets:

- `inventory = inventories/`: the default location of host inventory files
- `roles_path = roles:./.ansible/roles`: where Ansible looks for roles
- `interpreter_python = auto_silent`: lets Ansible find a suitable Python on managed hosts
- Connection settings such as `forks`, `timeout`, `pipelining`, and SSH multiplexing

`host_key_checking = False` skips SSH host-key verification. This is acceptable **only** for the controlled training environment, where the hosts are known and temporary. On any real or shared network, set it to `True` so that Ansible verifies each host's identity.

## SSH Configuration

- **Key location:** `~/.ssh/`. The workstation key is `id_ed25519`, with its public half in `id_ed25519.pub`. Lab-specific keys are stored alongside it in the same folder.
- **SSH agent:** `ssh-agent` keeps the decrypted private key in memory for the session, so you enter the key's passphrase once rather than for every connection. Load a key with `ssh-add ~/.ssh/id_ed25519`.
- **`known_hosts`:** `~/.ssh/known_hosts` records the fingerprint of each host you have connected to. SSH uses it to confirm that a host is the same machine as before, which protects against impersonation. Do not delete it to clear a warning without first confirming the host has changed.

The private key contents are never stored in this repository. `.gitignore` excludes common private-key file names and patterns.

## Git and Pre-commit

### How `.gitignore` protects local files

`.gitignore` keeps machine-specific and sensitive files out of version control:

- `.venv/` - the local virtual environment
- `__pycache__/`, `*.pyc` - Python cache files
- `.ansible/`, `*.retry` - Ansible temporary and retry files
- `.cache/` - tool caches
- `.DS_Store` - macOS folder metadata
- `id_rsa`, `id_ed25519`, `*.pem`, `*.key` - private keys and certificates

### Configured pre-commit hooks

Defined in `.pre-commit-config.yaml`:

1. **yamllint** (v1.38.0) - checks YAML syntax and formatting
2. **ansible-lint** (v26.8.0) - checks Ansible content for best practices

### When the hooks run

The hooks run automatically on `git commit`, and only on the files being committed. If a hook fails, the commit is blocked until the issue is fixed. You can also run all hooks on every file at any time with `pre-commit run --all-files`.

## Verification Commands

Run these from the project folder with the virtual environment active:

```bash
# Ansible
ansible --version

# Linting tools
ansible-lint --version
yamllint --version

# Pre-commit
pre-commit --version
pre-commit run --all-files

# SSH agent
ssh-add -l
```

`ssh-add -l` lists the keys loaded in the agent. If it reports "The agent has no identities," load your key with `ssh-add ~/.ssh/id_ed25519`.

## Team-Friendly Feature

The pinned `requirements.txt` and the shared `.vscode/settings.json` together mean every team member gets the same tool versions and the same editor behavior. A new team member runs `pip install -r requirements.txt` and gets the same Ansible and lint results as everyone else, with no per-person setup.

## Pitfall Avoided

**Committing the virtual environment or private keys.** Without `.gitignore`, `git add .` would stage the whole `.venv/` folder and could expose local key files to the repository. The ignore rules keep these out, and the README documents that private-key contents never belong in the repo.

## New Machine? Do This

- [ ] Update macOS and install the Xcode Command Line Tools (`xcode-select --install`) so that Git and the compiler tools are available.
- [ ] Confirm that Python 3, Git, and OpenSSH are installed and working (`python3 --version`, `git --version`, `ssh -V`).
- [ ] Create the project workspace folder and move into it.
- [ ] Initialize a Git repository in the project folder with `git init`.
- [ ] Create a `.gitignore` that excludes `.venv/`, cache files, Ansible retry files, macOS metadata, and private keys.
- [ ] Create the virtual environment with `python3 -m venv .venv`, then activate it with `source .venv/bin/activate`.
- [ ] Install the pinned tools with `pip install -r requirements.txt`, which brings in Ansible, Ansible Lint, yamllint, and pre-commit.
- [ ] Install the Ansible, YAML, and Python extensions in VS Code, and confirm `.vscode/settings.json` points to `.venv`.
- [ ] Create `ansible.cfg` with the inventory path, roles path, and connection settings for the training environment.
- [ ] Generate an Ed25519 SSH key, load it into `ssh-agent` with `ssh-add`, and confirm that `~/.ssh/known_hosts` exists.
- [ ] Add the Git hooks by running `pre-commit install` from the project folder.
- [ ] Run the verification commands (`ansible --version`, `ansible-lint --version`, `yamllint --version`, `pre-commit run --all-files`, `ssh-add -l`) and confirm they all succeed.
