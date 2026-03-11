<div align="center">

```
 _ __ ___  _  __  __ _  | (_) __ _ ___
| '_ ` _ \| |/ / / _` | | | |/ _` / __|
| | | | | |   < | (_| | | | | (_| \__ \
|_| |_| |_|_|\_\ \__,_| |_|_|\__,_|___/
```

**fish-first alias manager**

![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos-blue?style=flat-square)
![Shell](https://img.shields.io/badge/shell-fish%20%7C%20bash%20%7C%20zsh-89b4fa?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

</div>

---

`mkalias` — простой менеджер алиасов с нативной поддержкой **Fish**.
Каждый алиас становится Fish-функцией и подхватывается мгновенно, без перезапуска шелла.

```
$ mkalias

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

## Установка

```bash
git clone https://github.com/Zamyrig/alias_tweak.git
cd mkalias
sudo bash install.sh
```

Или одной строкой:

```bash
curl -fsSL https://raw.githubusercontent.com/Zamyrig/alias_tweak/main/install.sh | sudo bash
```

---

## Команды

| Команда | Что делает |
|---|---|
| `mkalias` | показать все алиасы |
| `mkalias name=value` | добавить алиас для текущего пользователя |
| `sudo mkalias -g name=value` | добавить глобальный алиас (для всех) |
| `mkalias -r name` | удалить алиас |
| `mkalias -l` | то же что и просто `mkalias` |
| `mkalias -a` | показать алиасы всех пользователей |

---

## Примеры

```bash
# пользовательские алиасы
mkalias dc=docker-compose
mkalias r=ranger
mkalias da="cd /projects/boars"

# глобальные — видны всем пользователям
sudo mkalias -g m=micro
sudo mkalias -g ll="ls -la"

# удалить
mkalias -r dc

# посмотреть что у всех
mkalias -a
```

---

## Как работает Fish-интеграция

Каждый алиас создаётся как отдельный `.fish` файл:

```fish
# ~/.config/fish/functions/dc.fish
function dc
    docker-compose $argv
end
```

Fish автоматически загружает функции из `~/.config/fish/functions/` — никакого `source` и перезапуска не нужно.

Глобальные алиасы пишутся в `/etc/fish/functions/` и доступны всем пользователям.

---

## Bash / Zsh

Установщик добавляет в `.bashrc` и `.zshrc`:

```bash
eval "$(mkalias --source-bash)"
```

Алиасы будут доступны при каждом старте шелла.

---

## Удаление

```bash
sudo rm /usr/local/bin/mkalias
sudo rm -rf /etc/mkalias
rm -rf ~/.config/mkalias
rm -f ~/.config/fish/functions/*.fish
```

---

## License

MIT