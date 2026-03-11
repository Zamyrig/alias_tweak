# alias.sh

Bash-скрипт, который устанавливает в систему шесть команд для удобного управления алиасами. Работает с **fish**, **bash** и **zsh**.

---

## Установка

```bash
git clone https://github.com/Zamyrig/my_tweaks
cd my_tweaks
chmod +x alias.sh
sudo ./alias.sh
```

После установки скрипт можно удалить — команды останутся в системе.

Чтобы активировать команды без перезапуска терминала:

```bash
# fish
source ~/.config/fish/config.fish

# bash
source ~/.bashrc

# zsh
source ~/.zshrc
```

---

## Команды

| Команда | Описание | Права |
|---------|----------|-------|
| `addalias <имя> <команда>` | Добавить алиас себе | — |
| `addaliasall <имя> <команда>` | Добавить алиас всем пользователям | root |
| `removealias <имя>` | Удалить алиас у себя | — |
| `removealiasall <имя>` | Удалить алиас у всех | root |
| `listalias` | Показать свои алиасы | — |
| `listaliasall` | Показать глобальные алиасы и алиасы всех пользователей | — |

### Примеры

```bash
addalias ll 'ls -la'
addalias dc 'docker compose'

sudo addaliasall cls 'clear'

removealias ll
sudo removealiasall cls

listalias
listaliasall
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
sudo rm -f /etc/fish/functions/addalias.fish
sudo rm -f /etc/fish/functions/addaliasall.fish
sudo rm -f /etc/fish/functions/removealias.fish
sudo rm -f /etc/fish/functions/removealiasall.fish
sudo rm -f /etc/fish/functions/listalias.fish
sudo rm -f /etc/fish/functions/listaliasall.fish
sudo rm -f /etc/fish/conf.d/alias_tools.fish

# bash/zsh
sudo rm -f /etc/profile.d/alias_tools.sh
sudo rm -f /etc/profile.d/custom_aliases.sh
```

Алиасы, добавленные через `addalias`, останутся в личных конфигах пользователей. Удалить их можно командой `removealias` или вручную.

---

## Лицензия

MIT