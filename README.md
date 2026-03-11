# mkalias

**Fish-first alias manager for Linux/macOS.**  
Manage aliases globally (all users) or per-user, with instant Fish shell support and optional Bash/Zsh integration.

```
  mkalias — alias list
  ─────────────────────────────────────

  [all users]
  dc                = docker-compose
  r                 = ranger
  m                 = micro

  [vladick]
  da                = cd /projects/boars

  [nikita]
  alias list is empty
```

---

## Install

```bash
git clone https://github.com/your-username/mkalias.git
cd mkalias
sudo bash install.sh
```

Or one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/mkalias/main/install.sh | sudo bash
```

> **Requires:** `bash` 4+, `fish` (optional but recommended), `curl` for one-liner install.

---

## Usage

```
mkalias                      show aliases (global + current user)
mkalias name=value           add alias for current user
mkalias -g name=value        add global alias for all users (requires sudo)
mkalias -r name              remove alias
mkalias -l                   list aliases (same as bare mkalias)
mkalias -a                   list aliases for ALL users on the system
```

---

## Commands

### Add a user alias

```bash
mkalias dc=docker-compose
mkalias r=ranger
mkalias da="cd /projects/boars"
```

Alias is immediately available in Fish (as a function file in `~/.config/fish/functions/`).

### Add a global alias (all users)

```bash
sudo mkalias -g m=micro
sudo mkalias -g ll="ls -la"
```

Writes to `/etc/mkalias/aliases.conf` and `/etc/fish/functions/`.

### Remove an alias

```bash
mkalias -r dc
```

Works for both user and global aliases (global removal requires `sudo`).

### List aliases

```bash
mkalias        # or mkalias -l
```

```
  [all users]
  dc                = docker-compose
  m                 = micro

  [vladick]
  da                = cd /projects/boars
```

### List aliases for all users

```bash
mkalias -a
```

Useful for admins to see what every user has configured.

---

## Shell Support

| Shell | Status | Notes |
|-------|--------|-------|
| **Fish** | ✅ Primary | Each alias = a `.fish` function file. No reload needed. |
| **Bash** | ✅ Supported | `eval "$(mkalias --source-bash)"` added to `.bashrc` on install |
| **Zsh** | ✅ Supported | Same eval line added to `.zshrc` on install |
| Others | ➕ DIY | Run `mkalias --source-bash` to get `alias x=y` lines |

### How Fish integration works

Each alias is written as a native Fish function:

```fish
# ~/.config/fish/functions/dc.fish
function dc
    docker-compose $argv
end
```

Fish auto-loads functions from `~/.config/fish/functions/` — no config change or shell restart needed.

---

## File Structure

```
/etc/mkalias/
  aliases.conf           ← global aliases (name=value per line)

/etc/fish/functions/
  dc.fish                ← global fish function per alias
  m.fish

~/.config/mkalias/
  aliases.conf           ← user aliases

~/.config/fish/functions/
  da.fish                ← user fish function per alias
```

---

## Uninstall

```bash
sudo rm /usr/local/bin/mkalias
sudo rm -rf /etc/mkalias
sudo rm -rf /etc/fish/functions/*.fish   # careful — only if you want to wipe all
rm -rf ~/.config/mkalias
rm -f ~/.config/fish/functions/*.fish    # user functions
```

---

## License

MIT
