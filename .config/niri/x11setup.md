# Настройка X11-приложений на niri

Используется `xwayland-satellite` — автоматически скейлит X11-приложения под scale монитора.

## Глобальные настройки в niri

В `config.kdl` добавлен блок `environment {}`:

```
environment {
    QT_AUTO_SCREEN_SCALE_FACTOR "1"
}
```

`QT_AUTO_SCREEN_SCALE_FACTOR=1` включает автоопределение DPI для всех Qt-приложений (X11).

## Obsidian (Electron, X11)

###   Файл `~/.config/obsidian/user-flags.conf`

```
--ozone-platform=x11
--force-device-scale-factor=1.75
```

- `--ozone-platform=x11` — форсирует X11, даже если доступен Wayland.
- `--force-device-scale-factor=1.75` — указывает Electron правильный DPI.

Файл автоматически подхватывается скриптом запуска Obsidian-flatpak (`obsidian.sh`).

### Команда для проверки

```
flatpak run md.obsidian.Obsidian
```

### Другие Electron-приложения

Если у другого Electron-приложения (VSCode, Discord и т.п.) такие же проблемы:

1. Найди скрипт запуска — обычно читает `user-flags.conf` или `~/.config/<app>/flags.conf`.
2. Добавь туда `--force-device-scale-factor=<scale>` с твоим scale.

## Qt-приложения (Amnezia VPN и т.п.)

Qt использует `QT_AUTO_SCREEN_SCALE_FACTOR=1` из глобального `environment {}` niri.

Если конкретное приложение всё ещё мелкое — можно переопределить при запуске:

```
env QT_SCALE_FACTOR=1.75 AmneziaVPN
```

Или изменить `Exec` в `/usr/share/applications/AmneziaVPN.desktop`:

```
Exec=env QT_SCALE_FACTOR=1.75 AmneziaVPN
```
