# alias.sh

Bash-скрипт, который устанавливает в систему шесть команд для удобного управления алиасами. Работает с **fish**, **bash** и **zsh** — каждый пользователь получает команды в своём родном shell.

---

## Быстрый старт

```bash
git clone https://github.com/Zamyrig/my_tweaks
cd my_tweaks
chmod +x alias.sh
sudo ./alias.sh
```

После установки скрипт можно удалить — команды останутся в системе.

---

## Команды

### `addalias` — добавить алиас себе

```
addalias <имя> <команда>
```

Добавляет алиас в конфиг текущего пользователя и активирует его в текущей сессии.

```fish
# fish
addalias ll  'ls -la'
addalias gs  'git status'
addalias k   'kubectl'
addalias ..  'cd ..'
```
```bash
# bash / zsh
addalias ll  'ls -la'
addalias py  'python3'
```

Применить без перезапуска терминала:
```fish
source ~/.config/fish/config.fish   # fish
source ~/.bashrc                     # bash
source ~/.zshrc                      # zsh
```

---

### `addaliasall` — добавить алиас всем пользователям

```
sudo addaliasall <имя> <команда>
```

Записывает алиас глобально и в конфиг каждого пользователя системы (fish, bash, zsh), включая root.

```bash
sudo addaliasall dc   'docker compose'
sudo addaliasall ll   'ls -la --color=auto'
sudo addaliasall cls  'clear'
```

---

### `removealias` — удалить алиас у себя

```
removealias <имя>
```

Удаляет алиас из конфига и деактивирует его в текущей сессии.

```bash
removealias ll
removealias gs
```

---

### `removealiasall` — удалить алиас у всех

```
sudo removealiasall <имя>
```

Удаляет алиас из глобального конфига и из конфига каждого пользователя.

```bash
sudo removealiasall dc
```

---

### `listalias` — посмотреть свои алиасы

```
listalias
```

Показывает алиасы текущего пользователя из его конфиг-файла и активные алиасы сессии.

**Fish:**
```
=== Fish: ~/.config/fish/config.fish ===
  alias ll 'ls -la'
  alias gs 'git status'

=== Fish: ~/.config/fish/functions/ ===
  ll → /home/user/.config/fish/functions/ll.fish
  gs → /home/user/.config/fish/functions/gs.fish
```

**Bash/Zsh:**
```
=== Aliases in /home/user/.bashrc ===
  alias ll='ls -la'

=== Active aliases in current session ===
  alias ll='ls -la'
  alias ls='ls --color=auto'
```

---

### `listaliasall` — посмотреть глобальные алиасы

```
listaliasall
```

Показывает глобальные алиасы и алиасы каждого пользователя системы.

```
=== Fish global (/etc/fish/functions/) ===
  dc  → /etc/fish/functions/dc.fish
  cls → /etc/fish/functions/cls.fish

=== Fish: per-user config.fish ===
  [alice]
    alias ll 'ls -la'
  [root]
    alias k 'kubectl'

=== Global aliases (/etc/profile.d/custom_aliases.sh) ===
  alias dc='docker compose'

=== Per-user aliases ===
  [bob] /home/bob/.bashrc
    alias ll='ls -la'
```

---

## Как это работает

```
sudo ./alias.sh
      │
      ├── [fish]
      │     ├── 6 .fish файлов → /etc/fish/functions/
      │     ├── /etc/fish/conf.d/alias_tools.fish
      │     │         (прописывает /etc/fish/functions в fish_function_path)
      │     └── добавляет fish_function_path в config.fish каждого fish-пользователя
      │
      └── [bash/zsh]
            ├── /etc/profile.d/alias_tools.sh
            │         (содержит все 6 функций для bash/zsh)
            ├── /etc/profile.d/custom_aliases.sh
            │         (сюда записываются глобальные алиасы через addaliasall)
            └── добавляет sourcing в ~/.bashrc / ~/.zshrc каждого пользователя
```

При повторном добавлении того же алиаса — старый перезаписывается, дублей нет.

---

## Требования

- Bash 4.0+ (для запуска установщика)
- Fish, bash или zsh — в зависимости от пользователей в системе
- Права root для установки и для команд `*all`
- Стандартные утилиты: `grep`, `sed`, `mktemp`

---

## Совместимость

| Shell | Поддержка |
|-------|-----------|
| fish  | ✅ |
| bash  | ✅ |
| zsh   | ✅ |

| ОС | Поддержка |
|----|-----------|
| Ubuntu / Debian | ✅ |
| CentOS / RHEL / Fedora | ✅ |
| Arch Linux | ✅ |
| macOS | ⚠️ частично (нет `/etc/bash.bashrc`) |

---

## Файлы, которые затрагивает скрипт

| Файл | Что делает |
|------|------------|
| `/etc/fish/functions/*.fish` | Функции команд и глобальные fish-алиасы |
| `/etc/fish/conf.d/alias_tools.fish` | Добавляет `/etc/fish/functions` в `fish_function_path` |
| `/etc/profile.d/alias_tools.sh` | Bash/zsh функции всех 6 команд |
| `/etc/profile.d/custom_aliases.sh` | Глобальные bash/zsh алиасы (через `addaliasall`) |
| `/etc/bash.bashrc` | Добавляет sourcing `/etc/profile.d/` если его нет |
| `~/.config/fish/config.fish` | Алиасы и fish_function_path для fish-пользователя |
| `~/.config/fish/functions/*.fish` | Файлы функций конкретного fish-пользователя |
| `~/.bashrc` / `~/.zshrc` | Sourcing + алиасы bash/zsh пользователя |

---

## Удаление

```bash
# Удалить команды (fish)
sudo rm -f /etc/fish/functions/addalias.fish
sudo rm -f /etc/fish/functions/addaliasall.fish
sudo rm -f /etc/fish/functions/removealias.fish
sudo rm -f /etc/fish/functions/removealiasall.fish
sudo rm -f /etc/fish/functions/listalias.fish
sudo rm -f /etc/fish/functions/listaliasall.fish
sudo rm -f /etc/fish/conf.d/alias_tools.fish

# Удалить команды (bash/zsh) и глобальные алиасы
sudo rm -f /etc/profile.d/alias_tools.sh
sudo rm -f /etc/profile.d/custom_aliases.sh
```

Алиасы, добавленные через `addalias`, останутся в личных конфигах пользователей. Их можно удалить командой `removealias` до удаления скрипта или вручную.

---

## Лицензия

MIT