# alias.sh

Bash-скрипт, который устанавливает команду `mkalias` для удобного управления алиасами. Работает с **fish**, **bash** и **zsh**.

---

## Установка

```bash
git clone https://github.com/Zamyrig/my_tweaks
cd my_tweaks
chmod +x alias.sh
sudo ./alias.sh
```

После установки скрипт можно удалить — команда останется в системе.

Чтобы активировать без перезапуска терминала:

```bash
source ~/.config/fish/config.fish   # fish
source ~/.bashrc                     # bash
source ~/.zshrc                      # zsh
```

---

## Использование

```
mkalias [флаги] [имя] [команда]
```

| Флаг | Полная форма | Описание |
|------|-------------|----------|
| `-a` | `--all` | Применить ко всем пользователям (требует root) |
| `-g` | `--global` | Синоним `-a` |
| `-r` | `--remove` | Удалить алиас |
| `-l` | `--list` | Показать список алиасов |

### Примеры

```bash
# Добавить алиас себе
mkalias ll 'ls -la'
mkalias dc 'docker compose'

# Добавить алиас всем пользователям
sudo mkalias -a cls 'clear'

# Удалить алиас у себя
mkalias -r ll

# Удалить алиас у всех
sudo mkalias -r -a cls

# Показать свои алиасы (также работает просто: mkalias)
mkalias -l

# Показать глобальные алиасы и алиасы всех пользователей
mkalias -l -a
```

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

## Удаление

```bash
# fish
sudo rm -f /etc/fish/functions/mkalias.fish
sudo rm -f /etc/fish/conf.d/alias_tools.fish

# bash/zsh
sudo rm -f /etc/profile.d/alias_tools.sh
sudo rm -f /etc/profile.d/custom_aliases.sh
```

Личные алиасы пользователей остаются в их конфигах. Удалить их можно командой `mkalias -r <имя>` или вручную.

---

## Лицензия

MIT