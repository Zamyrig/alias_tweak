#!/usr/bin/env bash
# =============================================================================
# alias.sh — installs alias management commands for fish, bash and zsh
#
#   addalias        — add alias for current user
#   addaliasall     — add alias for all users        (root required)
#   removealias     — remove alias for current user
#   removealiasall  — remove alias from all users    (root required)
#   listalias       — list aliases of current user
#   listaliasall    — list global + all-user aliases
#
# Usage:
#   chmod +x alias.sh && sudo ./alias.sh
# =============================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*" >&2; }
title() { echo -e "\n${CYAN}=== $* ===${NC}"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root: sudo ./alias.sh"
        exit 1
    fi
}

# =============================================================================
# Helper: detect rc-file for a given home dir + shell binary
# =============================================================================
get_rc_file() {
    local homedir="$1" shell="$2"
    case "$shell" in
        */zsh)  echo "$homedir/.zshrc"  ;;
        */bash) echo "$homedir/.bashrc" ;;
        */fish) echo ""                 ;;   # handled separately
        *)      echo "$homedir/.profile" ;;
    esac
}

# =============================================================================
# FISH function files
# =============================================================================

FISH_ADDALIAS='function addalias --description "Add alias for current user (fish)"
    if test (count $argv) -lt 2
        echo "Usage: addalias <alias_name> <command>"
        return 1
    end
    set alias_name $argv[1]
    set alias_cmd  $argv[2..-1]
    if not string match -qr "^[a-zA-Z_][a-zA-Z0-9_-]*\$" -- $alias_name
        echo "Error: invalid alias name '"'"'$alias_name'"'"'"
        return 1
    end
    set func_dir ~/.config/fish/functions
    mkdir -p $func_dir
    set func_file "$func_dir/$alias_name.fish"
    echo "function $alias_name"          > $func_file
    echo "    $alias_cmd \$argv"        >> $func_file
    echo "end"                          >> $func_file
    set cfg ~/.config/fish/config.fish
    touch $cfg
    set tmp (mktemp)
    grep -v "^alias $alias_name " $cfg > $tmp 2>/dev/null; or true
    mv $tmp $cfg
    echo "alias $alias_name '"'"'$alias_cmd'"'"'" >> $cfg
    echo "✓ [fish] alias '"'"'$alias_name'"'"' added"
    echo "  Run: source ~/.config/fish/config.fish"
end'

FISH_ADDALIASALL='function addaliasall --description "Add alias for all users (fish, root)"
    if test $EUID -ne 0
        echo "Error: must be run as root (sudo addaliasall ...)"
        return 1
    end
    if test (count $argv) -lt 2
        echo "Usage: sudo addaliasall <alias_name> <command>"
        return 1
    end
    set alias_name $argv[1]
    set alias_cmd  $argv[2..-1]
    if not string match -qr "^[a-zA-Z_][a-zA-Z0-9_-]*\$" -- $alias_name
        echo "Error: invalid alias name '"'"'$alias_name'"'"'"
        return 1
    end
    set gdir /etc/fish/functions
    mkdir -p $gdir
    set gfile "$gdir/$alias_name.fish"
    echo "function $alias_name"    > $gfile
    echo "    $alias_cmd \$argv" >> $gfile
    echo "end"                   >> $gfile
    chmod 644 $gfile
    echo "✓ [fish] global: $gfile"
    while read -L line
        set p (string split ":" $line)
        set uid $p[4]; set home $p[6]; set sh $p[7]
        if test $uid -lt 1000 -a $uid -ne 0; continue; end
        if not test -d $home; continue; end
        if not string match -q "*/fish" $sh; continue; end
        set cfg "$home/.config/fish/config.fish"
        mkdir -p (dirname $cfg); touch $cfg
        set tmp (mktemp)
        grep -v "^alias $alias_name " $cfg > $tmp 2>/dev/null; or true
        mv $tmp $cfg
        echo "alias $alias_name '"'"'$alias_cmd'"'"'" >> $cfg
        echo "  -> $cfg"
    end < /etc/passwd
    echo "✓ [fish] alias '"'"'$alias_name'"'"' added for all fish users"
end'

FISH_REMOVEALIAS='function removealias --description "Remove alias for current user (fish)"
    if test (count $argv) -lt 1
        echo "Usage: removealias <alias_name>"
        return 1
    end
    set alias_name $argv[1]
    set func_file ~/.config/fish/functions/$alias_name.fish
    set cfg ~/.config/fish/config.fish
    set removed 0
    if test -f $func_file
        rm -f $func_file
        echo "✓ Removed: $func_file"
        set removed 1
    end
    if test -f $cfg
        set tmp (mktemp)
        grep -v "^alias $alias_name " $cfg > $tmp 2>/dev/null; or true
        mv $tmp $cfg
        set removed 1
    end
    if functions -q $alias_name; functions -e $alias_name; end
    if test $removed -eq 0
        echo "Alias '"'"'$alias_name'"'"' not found."
        return 1
    end
    echo "✓ [fish] alias '"'"'$alias_name'"'"' removed"
end'

FISH_REMOVEALIASALL='function removealiasall --description "Remove alias from all users (fish, root)"
    if test $EUID -ne 0
        echo "Error: must be run as root (sudo removealiasall ...)"
        return 1
    end
    if test (count $argv) -lt 1
        echo "Usage: sudo removealiasall <alias_name>"
        return 1
    end
    set alias_name $argv[1]
    set gfile /etc/fish/functions/$alias_name.fish
    if test -f $gfile; rm -f $gfile; echo "✓ Removed global: $gfile"; end
    while read -L line
        set p (string split ":" $line)
        set uid $p[4]; set home $p[6]; set sh $p[7]
        if test $uid -lt 1000 -a $uid -ne 0; continue; end
        if not test -d $home; continue; end
        if not string match -q "*/fish" $sh; continue; end
        set cfg "$home/.config/fish/config.fish"
        if test -f $cfg
            set tmp (mktemp)
            grep -v "^alias $alias_name " $cfg > $tmp 2>/dev/null; or true
            mv $tmp $cfg
            echo "  -> cleaned: $cfg"
        end
        set uf "$home/.config/fish/functions/$alias_name.fish"
        if test -f $uf; rm -f $uf; echo "  -> removed: $uf"; end
    end < /etc/passwd
    echo "✓ [fish] alias '"'"'$alias_name'"'"' removed from all users"
end'

FISH_LISTALIAS='function listalias --description "List current user aliases"
    echo "=== Fish: ~/.config/fish/config.fish ==="
    if test -f ~/.config/fish/config.fish
        set lines (grep "^alias " ~/.config/fish/config.fish 2>/dev/null)
        if test (count $lines) -gt 0
            for l in $lines; echo "  $l"; end
        else; echo "  (none)"; end
    else; echo "  (not found)"; end

    echo ""
    echo "=== Fish: ~/.config/fish/functions/ ==="
    if test -d ~/.config/fish/functions
        set files (ls ~/.config/fish/functions/*.fish 2>/dev/null)
        if test (count $files) -gt 0
            for f in $files; echo "  "(basename $f .fish)" → $f"; end
        else; echo "  (none)"; end
    else; echo "  (not found)"; end
end'

FISH_LISTALIASALL='function listaliasall --description "List global and all-user aliases"
    echo "=== Fish global (/etc/fish/functions/) ==="
    if test -d /etc/fish/functions
        set files (ls /etc/fish/functions/*.fish 2>/dev/null)
        if test (count $files) -gt 0
            for f in $files; echo "  "(basename $f .fish)" → $f"; end
        else; echo "  (none)"; end
    else; echo "  (not found)"; end

    echo ""
    echo "=== Fish: per-user config.fish ==="
    while read -L line
        set p (string split ":" $line)
        set user $p[1]; set uid $p[4]; set home $p[6]; set sh $p[7]
        if test $uid -lt 1000 -a $uid -ne 0; continue; end
        if not test -d $home; continue; end
        if not string match -q "*/fish" $sh; continue; end
        set cfg "$home/.config/fish/config.fish"
        if test -f $cfg
            set lines (grep "^alias " $cfg 2>/dev/null)
            if test (count $lines) -gt 0
                echo "  [$user]"
                for l in $lines; echo "    $l"; end
            end
        end
    end < /etc/passwd

    echo ""
    echo "=== Bash/Zsh global (/etc/profile.d/custom_aliases.sh) ==="
    if test -f /etc/profile.d/custom_aliases.sh
        set lines (grep "^alias " /etc/profile.d/custom_aliases.sh 2>/dev/null)
        if test (count $lines) -gt 0
            for l in $lines; echo "  $l"; end
        else; echo "  (none)"; end
    else; echo "  (not found)"; end
end'

# =============================================================================
# BASH/ZSH shell functions (written to /etc/profile.d/alias_tools.sh)
# =============================================================================

BASH_FUNCTIONS='
# ---------------------------------------------------------------------------
# addalias — add alias for current user (bash/zsh)
# ---------------------------------------------------------------------------
addalias() {
    if [ $# -lt 2 ]; then
        echo "Usage: addalias <alias_name> <command>"
        return 1
    fi
    local alias_name="$1"; shift
    local alias_cmd="$*"
    if ! echo "$alias_name" | grep -qE "^[a-zA-Z_][a-zA-Z0-9_-]*$"; then
        echo "Error: invalid alias name '\''$alias_name'\''"
        return 1
    fi
    local rc_file
    case "$SHELL" in
        */zsh)  rc_file="$HOME/.zshrc"  ;;
        */bash) rc_file="$HOME/.bashrc" ;;
        *)      rc_file="$HOME/.profile" ;;
    esac
    sed -i "/^alias ${alias_name}=/d" "$rc_file" 2>/dev/null || true
    echo "alias ${alias_name}='\''${alias_cmd}'\''" >> "$rc_file"
    # activate in current session
    alias "${alias_name}"="${alias_cmd}"
    echo "✓ Alias '\''${alias_name}'\'' added to ${rc_file}"
    echo "  Run: source ${rc_file}"
}

# ---------------------------------------------------------------------------
# addaliasall — add alias for all users (bash/zsh, root required)
# ---------------------------------------------------------------------------
addaliasall() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: must be run as root (sudo addaliasall ...)"
        return 1
    fi
    if [ $# -lt 2 ]; then
        echo "Usage: sudo addaliasall <alias_name> <command>"
        return 1
    fi
    local alias_name="$1"; shift
    local alias_cmd="$*"
    if ! echo "$alias_name" | grep -qE "^[a-zA-Z_][a-zA-Z0-9_-]*$"; then
        echo "Error: invalid alias name '\''$alias_name'\''"
        return 1
    fi
    local global_file="/etc/profile.d/custom_aliases.sh"
    sed -i "/^alias ${alias_name}=/d" "$global_file" 2>/dev/null || true
    echo "alias ${alias_name}='\''${alias_cmd}'\''" >> "$global_file"
    chmod 644 "$global_file"
    echo "✓ [bash/zsh] global: $global_file"
    while IFS=: read -r uname _ uid _ _ homedir shell; do
        [ "$uid" -ge 1000 ] || [ "$uid" -eq 0 ] || continue
        [ -d "$homedir" ] || continue
        case "$shell" in */fish) continue ;; esac
        local rc_file
        case "$shell" in
            */zsh)  rc_file="$homedir/.zshrc"  ;;
            */bash) rc_file="$homedir/.bashrc" ;;
            *)      rc_file="$homedir/.profile" ;;
        esac
        touch "$rc_file"
        sed -i "/^alias ${alias_name}=/d" "$rc_file" 2>/dev/null || true
        echo "alias ${alias_name}='\''${alias_cmd}'\''" >> "$rc_file"
        echo "  -> $rc_file"
    done < /etc/passwd
    echo "✓ [bash/zsh] alias '\''${alias_name}'\'' added for all users"
}

# ---------------------------------------------------------------------------
# removealias — remove alias for current user (bash/zsh)
# ---------------------------------------------------------------------------
removealias() {
    if [ $# -lt 1 ]; then
        echo "Usage: removealias <alias_name>"
        return 1
    fi
    local alias_name="$1"
    local rc_file
    case "$SHELL" in
        */zsh)  rc_file="$HOME/.zshrc"  ;;
        */bash) rc_file="$HOME/.bashrc" ;;
        *)      rc_file="$HOME/.profile" ;;
    esac
    if [ -f "$rc_file" ]; then
        sed -i "/^alias ${alias_name}=/d" "$rc_file" 2>/dev/null || true
    fi
    unalias "$alias_name" 2>/dev/null || true
    echo "✓ Alias '\''${alias_name}'\'' removed from ${rc_file}"
}

# ---------------------------------------------------------------------------
# removealiasall — remove alias from all users (bash/zsh, root required)
# ---------------------------------------------------------------------------
removealiasall() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: must be run as root (sudo removealiasall ...)"
        return 1
    fi
    if [ $# -lt 1 ]; then
        echo "Usage: sudo removealiasall <alias_name>"
        return 1
    fi
    local alias_name="$1"
    local global_file="/etc/profile.d/custom_aliases.sh"
    if [ -f "$global_file" ]; then
        sed -i "/^alias ${alias_name}=/d" "$global_file" 2>/dev/null || true
        echo "✓ Removed from global: $global_file"
    fi
    while IFS=: read -r uname _ uid _ _ homedir shell; do
        [ "$uid" -ge 1000 ] || [ "$uid" -eq 0 ] || continue
        [ -d "$homedir" ] || continue
        case "$shell" in */fish) continue ;; esac
        local rc_file
        case "$shell" in
            */zsh)  rc_file="$homedir/.zshrc"  ;;
            */bash) rc_file="$homedir/.bashrc" ;;
            *)      rc_file="$homedir/.profile" ;;
        esac
        if [ -f "$rc_file" ]; then
            sed -i "/^alias ${alias_name}=/d" "$rc_file" 2>/dev/null || true
            echo "  -> cleaned: $rc_file"
        fi
    done < /etc/passwd
    echo "✓ [bash/zsh] alias '\''${alias_name}'\'' removed from all users"
}

# ---------------------------------------------------------------------------
# listalias — list aliases of current user (bash/zsh)
# ---------------------------------------------------------------------------
listalias() {
    local rc_file
    case "$SHELL" in
        */zsh)  rc_file="$HOME/.zshrc"  ;;
        */bash) rc_file="$HOME/.bashrc" ;;
        *)      rc_file="$HOME/.profile" ;;
    esac
    echo "=== Aliases in ${rc_file} ==="
    if [ -f "$rc_file" ]; then
        local lines
        lines=$(grep "^alias " "$rc_file" 2>/dev/null)
        if [ -n "$lines" ]; then
            echo "$lines" | sed "s/^/  /"
        else
            echo "  (none)"
        fi
    else
        echo "  (file not found)"
    fi
    echo ""
    echo "=== Active aliases in current session ==="
    alias | sed "s/^/  /"
}

# ---------------------------------------------------------------------------
# listaliasall — list global and all-user aliases (bash/zsh)
# ---------------------------------------------------------------------------
listaliasall() {
    local global_file="/etc/profile.d/custom_aliases.sh"
    echo "=== Global aliases (${global_file}) ==="
    if [ -f "$global_file" ]; then
        local lines
        lines=$(grep "^alias " "$global_file" 2>/dev/null)
        if [ -n "$lines" ]; then
            echo "$lines" | sed "s/^/  /"
        else
            echo "  (none)"
        fi
    else
        echo "  (not found)"
    fi
    echo ""
    echo "=== Per-user aliases ==="
    while IFS=: read -r uname _ uid _ _ homedir shell; do
        [ "$uid" -ge 1000 ] || [ "$uid" -eq 0 ] || continue
        [ -d "$homedir" ] || continue
        case "$shell" in */fish) continue ;; esac
        local rc_file
        case "$shell" in
            */zsh)  rc_file="$homedir/.zshrc"  ;;
            */bash) rc_file="$homedir/.bashrc" ;;
            *)      rc_file="$homedir/.profile" ;;
        esac
        if [ -f "$rc_file" ]; then
            local lines
            lines=$(grep "^alias " "$rc_file" 2>/dev/null)
            if [ -n "$lines" ]; then
                echo "  [${uname}] ${rc_file}"
                echo "$lines" | sed "s/^/    /"
            fi
        fi
    done < /etc/passwd
}
'

# =============================================================================
# Installation
# =============================================================================

require_root

GLOBAL_FISH_FUNC="/etc/fish/functions"
GLOBAL_FISH_CONF="/etc/fish/conf.d"
GLOBAL_BASH_PROFILE="/etc/profile.d/alias_tools.sh"
GLOBAL_BASH_ALIASES="/etc/profile.d/custom_aliases.sh"

title "Installing alias management tools (fish + bash + zsh)"

# ---- 1. Fish -----------------------------------------------------------------
if command -v fish &>/dev/null; then
    mkdir -p "$GLOBAL_FISH_FUNC" "$GLOBAL_FISH_CONF"

    declare -A FISH_FUNCS
    FISH_FUNCS["addalias"]="$FISH_ADDALIAS"
    FISH_FUNCS["addaliasall"]="$FISH_ADDALIASALL"
    FISH_FUNCS["removealias"]="$FISH_REMOVEALIAS"
    FISH_FUNCS["removealiasall"]="$FISH_REMOVEALIASALL"
    FISH_FUNCS["listalias"]="$FISH_LISTALIAS"
    FISH_FUNCS["listaliasall"]="$FISH_LISTALIASALL"

    for name in "${!FISH_FUNCS[@]}"; do
        dest="$GLOBAL_FISH_FUNC/$name.fish"
        printf '%s\n' "${FISH_FUNCS[$name]}" > "$dest"
        chmod 644 "$dest"
        info "[fish] Installed: $dest"
    done

    # Ensure /etc/fish/functions is in fish_function_path
    cat > "$GLOBAL_FISH_CONF/alias_tools.fish" << 'FISHCONF'
# alias.sh — make global functions available in all fish sessions
if not contains /etc/fish/functions $fish_function_path
    set -p fish_function_path /etc/fish/functions
end
FISHCONF
    chmod 644 "$GLOBAL_FISH_CONF/alias_tools.fish"
    info "[fish] Written: $GLOBAL_FISH_CONF/alias_tools.fish"

    # Patch each fish user's config.fish
    while IFS=: read -r username _ uid _ _ homedir shell; do
        [[ "$uid" -ge 1000 || "$uid" -eq 0 ]] || continue
        [[ -d "$homedir" ]] || continue
        [[ "$shell" == */fish ]] || continue
        uconfig="$homedir/.config/fish/config.fish"
        mkdir -p "$(dirname "$uconfig")"
        touch "$uconfig"
        if ! grep -q "alias_tools" "$uconfig" 2>/dev/null; then
            cat >> "$uconfig" << 'SNIPPET'

# Load global alias tools (added by alias.sh)
if not contains /etc/fish/functions $fish_function_path
    set -p fish_function_path /etc/fish/functions
end
SNIPPET
            info "[fish] Patched: $uconfig ($username)"
        else
            warn "[fish] Already patched: $uconfig ($username)"
        fi
    done < /etc/passwd
else
    warn "fish not found — skipping fish installation"
fi

# ---- 2. Bash / Zsh -----------------------------------------------------------
title "Installing bash/zsh functions"

# Global functions file
printf '%s\n' "$BASH_FUNCTIONS" > "$GLOBAL_BASH_PROFILE"
chmod 644 "$GLOBAL_BASH_PROFILE"
info "[bash/zsh] Written: $GLOBAL_BASH_PROFILE"

# Empty global aliases file (populated by addaliasall)
touch "$GLOBAL_BASH_ALIASES"
chmod 644 "$GLOBAL_BASH_ALIASES"
info "[bash/zsh] Created: $GLOBAL_BASH_ALIASES"

# Ensure /etc/bash.bashrc sources profile.d
GLOBAL_RC="/etc/bash.bashrc"
if ! grep -q "profile\.d" "$GLOBAL_RC" 2>/dev/null; then
    cat >> "$GLOBAL_RC" << 'SNIPPET'

# Source /etc/profile.d for interactive shells (added by alias.sh)
if [ -d /etc/profile.d ]; then
    for _f in /etc/profile.d/*.sh; do [ -r "$_f" ] && . "$_f"; done
    unset _f
fi
SNIPPET
    info "[bash/zsh] Updated: $GLOBAL_RC"
fi

# Patch each bash/zsh user's rc-file
while IFS=: read -r username _ uid _ _ homedir shell; do
    [[ "$uid" -ge 1000 || "$uid" -eq 0 ]] || continue
    [[ -d "$homedir" ]] || continue
    [[ "$shell" == */fish ]] && continue   # fish users handled above
    rc_file=$(get_rc_file "$homedir" "$shell")
    [[ -z "$rc_file" ]] && continue
    touch "$rc_file"
    if ! grep -q "alias_tools" "$rc_file" 2>/dev/null; then
        cat >> "$rc_file" << 'SNIPPET'

# Load alias tools (added by alias.sh)
[ -f /etc/profile.d/alias_tools.sh ] && . /etc/profile.d/alias_tools.sh
[ -f /etc/profile.d/custom_aliases.sh ] && . /etc/profile.d/custom_aliases.sh
SNIPPET
        info "[bash/zsh] Patched: $rc_file ($username)"
    else
        warn "[bash/zsh] Already patched: $rc_file ($username)"
    fi
done < /etc/passwd

# Done
title "Installation complete"
echo ""
echo -e "  ${GREEN}addalias${NC}        <n> <cmd>   add alias for yourself"
echo -e "  ${GREEN}addaliasall${NC}     <n> <cmd>   add alias for all users    (sudo)"
echo -e "  ${GREEN}removealias${NC}     <n>         remove alias for yourself"
echo -e "  ${GREEN}removealiasall${NC}  <n>         remove alias from all      (sudo)"
echo -e "  ${GREEN}listalias${NC}                      show your aliases"
echo -e "  ${GREEN}listaliasall${NC}                   show global + all-user aliases"
echo ""
echo "  Open a new terminal to activate, or reload your config:"
echo "    fish:    source ~/.config/fish/config.fish"
echo "    bash:    source ~/.bashrc"
echo "    zsh:     source ~/.zshrc"
echo ""
warn "You can now safely delete this script."