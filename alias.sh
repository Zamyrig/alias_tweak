#!/usr/bin/env bash
# =============================================================================
# alias.sh — installs mkalias command for fish, bash and zsh
#
# mkalias <n> <command>       add alias for current user
# mkalias -a <n> <command>    add alias for all users      (root required)
# mkalias -r <n>              remove alias for current user
# mkalias -r -a <n>           remove alias for all users   (root required)
# mkalias -l                  list aliases of current user
# mkalias -l -a               list global + all-user aliases
# mkalias                     same as mkalias -l
#
# Flags:
#   -a, --all     affect all users (requires root)
#   -g, --global  same as --all
#   -r, --remove  remove alias instead of adding
#   -l, --list    list aliases
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

get_rc_file() {
    local homedir="$1" shell="$2"
    case "$shell" in
        */zsh)  echo "$homedir/.zshrc"   ;;
        */bash) echo "$homedir/.bashrc"  ;;
        */fish) echo ""                  ;;
        *)      echo "$homedir/.profile" ;;
    esac
}

# =============================================================================
# FISH — mkalias.fish
# =============================================================================

FISH_MKALIAS='function mkalias --description "Alias manager: add/remove/list aliases"

    # ── parse flags ──────────────────────────────────────────────────────────
    set do_all    0
    set do_remove 0
    set do_list   0
    set rest

    for arg in $argv
        switch $arg
            case -a --all -g --global
                set do_all 1
            case -r --remove
                set do_remove 1
            case -l --list
                set do_list 1
            case "*"
                set rest $rest $arg
        end
    end

    # no args → list
    if test (count $argv) -eq 0
        set do_list 1
    end

    # require root for --all
    if test $do_all -eq 1 -a $EUID -ne 0
        echo "Error: -a / --all requires root (sudo mkalias ...)"
        return 1
    end

    # ── LIST ─────────────────────────────────────────────────────────────────
    if test $do_list -eq 1
        if test $do_all -eq 1
            echo "=== Fish global (/etc/fish/functions/) ==="
            if test -d /etc/fish/functions
                set gfiles (ls /etc/fish/functions/*.fish 2>/dev/null)
                if test (count $gfiles) -gt 0
                    for f in $gfiles; echo "  "(basename $f .fish)" → $f"; end
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
        else
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
        end
        return 0
    end

    # ── REMOVE ────────────────────────────────────────────────────────────────
    if test $do_remove -eq 1
        if test (count $rest) -lt 1
            echo "Usage: mkalias -r [-a] <alias_name>"
            return 1
        end
        set alias_name $rest[1]

        if test $do_all -eq 1
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
            echo "✓ alias '"'"'$alias_name'"'"' removed from all users"
        else
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
            echo "✓ alias '"'"'$alias_name'"'"' removed"
        end
        return 0
    end

    # ── ADD ───────────────────────────────────────────────────────────────────
    if test (count $rest) -lt 2
        echo "Usage: mkalias [-a] [-r] [-l] <alias_name> <command>"
        echo ""
        echo "  mkalias ll '"'"'ls -la'"'"'            add alias for yourself"
        echo "  mkalias -a dc '"'"'docker compose'"'"'  add alias for all users (sudo)"
        echo "  mkalias -r ll                    remove alias for yourself"
        echo "  mkalias -r -a dc                 remove alias for all users (sudo)"
        echo "  mkalias -l                       list your aliases"
        echo "  mkalias -l -a                    list global + all-user aliases"
        return 1
    end

    set alias_name $rest[1]
    set alias_cmd  $rest[2..-1]

    if not string match -qr "^[a-zA-Z_][a-zA-Z0-9_-]*\$" -- $alias_name
        echo "Error: invalid alias name '"'"'$alias_name'"'"'"
        return 1
    end

    if test $do_all -eq 1
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
        echo "✓ alias '"'"'$alias_name'"'"' added for all users"
    else
        set func_dir ~/.config/fish/functions
        mkdir -p $func_dir
        set func_file "$func_dir/$alias_name.fish"
        echo "function $alias_name"    > $func_file
        echo "    $alias_cmd \$argv" >> $func_file
        echo "end"                   >> $func_file
        set cfg ~/.config/fish/config.fish
        touch $cfg
        set tmp (mktemp)
        grep -v "^alias $alias_name " $cfg > $tmp 2>/dev/null; or true
        mv $tmp $cfg
        echo "alias $alias_name '"'"'$alias_cmd'"'"'" >> $cfg
        echo "✓ alias '"'"'$alias_name'"'"' added"
        echo "  Run: source ~/.config/fish/config.fish"
    end
end'

# =============================================================================
# BASH/ZSH — mkalias function
# =============================================================================

BASH_FUNCTIONS='
# ---------------------------------------------------------------------------
# mkalias — unified alias manager (bash/zsh)
#
#   mkalias <n> <cmd>         add alias for current user
#   mkalias -a <n> <cmd>      add alias for all users       (root)
#   mkalias -r <n>            remove alias for current user
#   mkalias -r -a <n>         remove alias for all users    (root)
#   mkalias -l                list aliases of current user
#   mkalias -l -a             list global + all-user aliases
#   mkalias                   same as mkalias -l
# ---------------------------------------------------------------------------
mkalias() {
    local do_all=0 do_remove=0 do_list=0
    local rest=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all|-g|--global) do_all=1    ; shift ;;
            -r|--remove)          do_remove=1 ; shift ;;
            -l|--list)            do_list=1   ; shift ;;
            --) shift; rest+=("$@"); break ;;
            *)  rest+=("$1")      ; shift ;;
        esac
    done

    # no args → list
    [[ ${#rest[@]} -eq 0 && $do_remove -eq 0 ]] && do_list=1

    # require root for --all
    if [[ $do_all -eq 1 && "$(id -u)" -ne 0 ]]; then
        echo "Error: -a / --all requires root (sudo mkalias ...)"
        return 1
    fi

    local rc_file
    case "$SHELL" in
        */zsh)  rc_file="$HOME/.zshrc"   ;;
        */bash) rc_file="$HOME/.bashrc"  ;;
        *)      rc_file="$HOME/.profile" ;;
    esac

    # ── LIST ─────────────────────────────────────────────────────────────────
    if [[ $do_list -eq 1 ]]; then
        if [[ $do_all -eq 1 ]]; then
            local global_file="/etc/profile.d/custom_aliases.sh"
            echo "=== Global aliases (${global_file}) ==="
            if [[ -f "$global_file" ]]; then
                local lines; lines=$(grep "^alias " "$global_file" 2>/dev/null)
                [[ -n "$lines" ]] && echo "$lines" | sed "s/^/  /" || echo "  (none)"
            else
                echo "  (not found)"
            fi
            echo ""
            echo "=== Per-user aliases ==="
            while IFS=: read -r uname _ uid _ _ homedir shell; do
                [[ "$uid" -ge 1000 || "$uid" -eq 0 ]] || continue
                [[ -d "$homedir" ]] || continue
                case "$shell" in */fish) continue ;; esac
                local urc
                case "$shell" in
                    */zsh)  urc="$homedir/.zshrc"   ;;
                    */bash) urc="$homedir/.bashrc"  ;;
                    *)      urc="$homedir/.profile" ;;
                esac
                if [[ -f "$urc" ]]; then
                    local ulines; ulines=$(grep "^alias " "$urc" 2>/dev/null)
                    if [[ -n "$ulines" ]]; then
                        echo "  [${uname}] ${urc}"
                        echo "$ulines" | sed "s/^/    /"
                    fi
                fi
            done < /etc/passwd
        else
            echo "=== Aliases in ${rc_file} ==="
            if [[ -f "$rc_file" ]]; then
                local lines; lines=$(grep "^alias " "$rc_file" 2>/dev/null)
                [[ -n "$lines" ]] && echo "$lines" | sed "s/^/  /" || echo "  (none)"
            else
                echo "  (file not found)"
            fi
            echo ""
            echo "=== Active aliases in current session ==="
            alias | sed "s/^/  /"
        fi
        return 0
    fi

    # ── REMOVE ────────────────────────────────────────────────────────────────
    if [[ $do_remove -eq 1 ]]; then
        if [[ ${#rest[@]} -lt 1 ]]; then
            echo "Usage: mkalias -r [-a] <alias_name>"
            return 1
        fi
        local alias_name="${rest[0]}"

        if [[ $do_all -eq 1 ]]; then
            local global_file="/etc/profile.d/custom_aliases.sh"
            if [[ -f "$global_file" ]]; then
                sed -i "/^alias ${alias_name}=/d" "$global_file" 2>/dev/null || true
                echo "✓ Removed from global: $global_file"
            fi
            while IFS=: read -r uname _ uid _ _ homedir shell; do
                [[ "$uid" -ge 1000 || "$uid" -eq 0 ]] || continue
                [[ -d "$homedir" ]] || continue
                case "$shell" in */fish) continue ;; esac
                local urc
                case "$shell" in
                    */zsh)  urc="$homedir/.zshrc"   ;;
                    */bash) urc="$homedir/.bashrc"  ;;
                    *)      urc="$homedir/.profile" ;;
                esac
                if [[ -f "$urc" ]]; then
                    sed -i "/^alias ${alias_name}=/d" "$urc" 2>/dev/null || true
                    echo "  -> cleaned: $urc"
                fi
            done < /etc/passwd
            echo "✓ alias '"'"'${alias_name}'"'"' removed from all users"
        else
            if [[ -f "$rc_file" ]]; then
                sed -i "/^alias ${alias_name}=/d" "$rc_file" 2>/dev/null || true
            fi
            unalias "$alias_name" 2>/dev/null || true
            echo "✓ alias '"'"'${alias_name}'"'"' removed from ${rc_file}"
        fi
        return 0
    fi

    # ── ADD ───────────────────────────────────────────────────────────────────
    if [[ ${#rest[@]} -lt 2 ]]; then
        echo "Usage: mkalias [-a] [-r] [-l] <alias_name> <command>"
        echo ""
        echo "  mkalias ll '\''ls -la'\''             add alias for yourself"
        echo "  mkalias -a dc '\''docker compose'\''   add alias for all users (sudo)"
        echo "  mkalias -r ll                      remove alias for yourself"
        echo "  mkalias -r -a dc                   remove alias for all users (sudo)"
        echo "  mkalias -l                         list your aliases"
        echo "  mkalias -l -a                      list global + all-user aliases"
        return 1
    fi

    local alias_name="${rest[0]}"
    local alias_cmd="${rest[*]:1}"

    if ! echo "$alias_name" | grep -qE "^[a-zA-Z_][a-zA-Z0-9_-]*$"; then
        echo "Error: invalid alias name '\''${alias_name}'\''"
        return 1
    fi

    if [[ $do_all -eq 1 ]]; then
        local global_file="/etc/profile.d/custom_aliases.sh"
        sed -i "/^alias ${alias_name}=/d" "$global_file" 2>/dev/null || true
        echo "alias ${alias_name}='\''${alias_cmd}'\''" >> "$global_file"
        chmod 644 "$global_file"
        echo "✓ [bash/zsh] global: $global_file"
        while IFS=: read -r uname _ uid _ _ homedir shell; do
            [[ "$uid" -ge 1000 || "$uid" -eq 0 ]] || continue
            [[ -d "$homedir" ]] || continue
            case "$shell" in */fish) continue ;; esac
            local urc
            case "$shell" in
                */zsh)  urc="$homedir/.zshrc"   ;;
                */bash) urc="$homedir/.bashrc"  ;;
                *)      urc="$homedir/.profile" ;;
            esac
            touch "$urc"
            sed -i "/^alias ${alias_name}=/d" "$urc" 2>/dev/null || true
            echo "alias ${alias_name}='\''${alias_cmd}'\''" >> "$urc"
            echo "  -> $urc"
        done < /etc/passwd
        echo "✓ alias '\''${alias_name}'\'' added for all users"
    else
        sed -i "/^alias ${alias_name}=/d" "$rc_file" 2>/dev/null || true
        echo "alias ${alias_name}='\''${alias_cmd}'\''" >> "$rc_file"
        alias "${alias_name}"="${alias_cmd}"
        echo "✓ alias '\''${alias_name}'\'' added to ${rc_file}"
        echo "  Run: source ${rc_file}"
    fi
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

title "Installing mkalias (fish + bash + zsh)"

# ── Fish ──────────────────────────────────────────────────────────────────────
if command -v fish &>/dev/null; then
    mkdir -p "$GLOBAL_FISH_FUNC" "$GLOBAL_FISH_CONF"

    dest="$GLOBAL_FISH_FUNC/mkalias.fish"
    printf '%s\n' "$FISH_MKALIAS" > "$dest"
    chmod 644 "$dest"
    info "[fish] Installed: $dest"

    cat > "$GLOBAL_FISH_CONF/alias_tools.fish" << 'FISHCONF'
# alias.sh — make global functions available in all fish sessions
if not contains /etc/fish/functions $fish_function_path
    set -p fish_function_path /etc/fish/functions
end
FISHCONF
    chmod 644 "$GLOBAL_FISH_CONF/alias_tools.fish"
    info "[fish] Written: $GLOBAL_FISH_CONF/alias_tools.fish"

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

# ── Bash / Zsh ────────────────────────────────────────────────────────────────
title "Installing bash/zsh function"

printf '%s\n' "$BASH_FUNCTIONS" > "$GLOBAL_BASH_PROFILE"
chmod 644 "$GLOBAL_BASH_PROFILE"
info "[bash/zsh] Written: $GLOBAL_BASH_PROFILE"

touch "$GLOBAL_BASH_ALIASES"
chmod 644 "$GLOBAL_BASH_ALIASES"
info "[bash/zsh] Created: $GLOBAL_BASH_ALIASES"

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

while IFS=: read -r username _ uid _ _ homedir shell; do
    [[ "$uid" -ge 1000 || "$uid" -eq 0 ]] || continue
    [[ -d "$homedir" ]] || continue
    [[ "$shell" == */fish ]] && continue
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

# ── Done ──────────────────────────────────────────────────────────────────────
title "Installation complete"
echo ""
echo -e "  ${GREEN}mkalias${NC} <n> <cmd>          add alias for yourself"
echo -e "  ${GREEN}mkalias${NC} -a <n> <cmd>        add alias for all users   (sudo)"
echo -e "  ${GREEN}mkalias${NC} -r <n>               remove alias for yourself"
echo -e "  ${GREEN}mkalias${NC} -r -a <n>            remove alias for all      (sudo)"
echo -e "  ${GREEN}mkalias${NC} -l                   list your aliases"
echo -e "  ${GREEN}mkalias${NC} -l -a                list global + all-user aliases"
echo ""
echo "  Reload your config to activate:"
echo "    fish:  source ~/.config/fish/config.fish"
echo "    bash:  source ~/.bashrc"
echo "    zsh:   source ~/.zshrc"
echo ""
warn "You can now safely delete this script."