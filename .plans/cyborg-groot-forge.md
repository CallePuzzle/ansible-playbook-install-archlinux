# Plan: Sincronizar playbooks de Steam Deck con los cambios de `archlinux/`

## Objetivo
Actualizar `steam-deck/playbook.yaml` y `steam-deck/after-SO-upgrade.yaml` para que reflejen los cambios recientes de los playbooks de Arch Linux (paquetes, ghostty, fish, configuración de usuario, KDE, SSH, etc.), y corregir la documentación que aún referencia archivos que ya no existen.

## Decisiones tomadas
- Replicar la configuración de usuario de `archlinux/010-configure.yaml` en Steam Deck.
- La configuración de usuario vive solo en `steam-deck/playbook.yaml` (setup inicial); `after-SO-upgrade.yaml` solo reinstala paquetes.
- Actualizar `README.md` y `AGENTS.md` para reflejar el flujo actual.

## Cambios detallados

### 1. `steam-deck/after-SO-upgrade.yaml`
Mantener la estructura existente (disable readonly, pacman keys, enlace de firefox) y actualizar la lista de paquetes a reinstalar para que coincida con `archlinux/010-configure.yaml`:

- **Sustituir:**
  - `leafpad` → `featherpad`
  - `terminator` → `ghostty`
- **Eliminar:**
  - `emacs`
  - `transmission-qt` (no está en `archlinux/010-configure.yaml`)
- **Añadir:**
  - `less`, `dolphin`, `spectacle`, `okular`, `gwenview`, `unzip`, `ark`
  - `bluedevil`, `bluez`, `bluez-libs`, `bluez-utils`
  - `cups`, `libcups`, `print-manager`
  - `nfs-utils`, `python-virtualenv`, `fish`
  - `ghostty` (ya se indica arriba)
- Mantener: `vlc`, `the_silver_searcher`, `nextcloud-client`, `wget`, `git`, `rsync`, `btop`, `audacity`, `obsidian`, `noto-fonts-emoji`, `telegram-desktop`, `kcalc`, `sshpass`, `solaar`.
- Opcionalmente convertir `with_items` a una lista en `pacman.name` para mantener el estilo de los playbooks de `archlinux/`.

### 2. `steam-deck/playbook.yaml`
Añadir, tras las tareas iniciales de preparación del sistema, un bloque de configuración de usuario adaptado desde `archlinux/010-configure.yaml`:

1. **Instalar los paquetes necesarios** para la configuración (misma lista que `after-SO-upgrade.yaml`), usando `pacman`.
2. **Grupo plugdev y udev:**
   - Crear grupo `plugdev`.
   - Añadir `{{ ansible_ssh_user }}` al grupo.
   - Handler `reload udev rules`.
3. **Bluetooth:**
   - Habilitar e iniciar servicio `bluetooth`.
   - Configurar `/etc/bluetooth/main.conf` (con `AutoEnable=true`).
   - Handler `restart bluetooth`.
4. **Autostart:**
   - Crear `~/.config/autostart`.
   - Escribir `solaar.desktop` y `nextcloud.desktop`.
   - Ajustar permisos `0644` en archivos `.desktop` (incluyendo `tuxedo-control-center-tray.desktop` con `ignore_errors`).
5. **Git:** copiar `../files/git.config` a `~/.gitconfig`.
6. **Configuración de KDE:**
   - `~/.config/kxkbrc`: `LayoutList=es,us`, `Options=caps:ctrl_modifier`, `ResetOldOptions=true`.
   - `~/.config/kwinrc`: escritorios, `RollOverDesktops`, `Xwayland Scale=1`.
   - `~/.config/kglobalshortcutsrc`: atajos de ventanas/escritorios.
7. **SSH:**
   - Crear `~/.ssh`.
   - Copiar `id_ed25519` e `id_ed25519.pub` con permisos `0600`.
   - Configurar `SetEnv TERM=xterm-256color` en `~/.ssh/config`.
8. **Ghostty:**
   - Crear `~/.config/ghostty`.
   - Escribir `~/.config/ghostty/config` con los atajos definidos en `archlinux/010-configure.yaml`.
9. **Fish:**
   - Establecer `/usr/bin/fish` como shell por defecto.
   - Crear `~/.config/fish`.
   - Escribir `fish_plugins` (`jorgebucaran/fisher`, `edc/bass`, `jorgebucaran/hydro`).
   - Instalar fisher y plugins.
   - Escribir `config.fish` y `functions/fish_mode_prompt.fish`.

Adaptaciones específicas para Steam Deck:
- Usar `{{ ansible_ssh_user }}` (normalmente `deck`).
- No incluir configuraciones de hardware Tuxedo ni parámetros de kernel.
- No ejecutar `archlinux/020-developer.yaml` ni `archlinux/050-asdf.yaml` automáticamente; solo documentar que pueden usarse opcionalmente.

### 3. Documentación
Actualizar `README.md` y `AGENTS.md`:
- Reemplazar todas las referencias a `archlinux/100-configure-arch-linux.yaml` (ya no existe) por `steam-deck/playbook.yaml` y, cuando corresponda, `archlinux/010-configure.yaml` / `archlinux/020-developer.yaml` como pasos opcionales.
- En la sección **Steam Deck** indicar:
  - Setup inicial: `ansible-playbook -i inventory.ini --vault-password-file .vault-password-file steam-deck/playbook.yaml -kK`
  - Tras actualizaciones de SteamOS: `ansible-playbook -i inventory.ini --vault-password-file .vault-password-file steam-deck/after-SO-upgrade.yaml -kK`
- Actualizar el resumen de estructura y el workflow summary en `AGENTS.md` si es necesario para incluir `steam-deck/after-SO-upgrade.yaml` y los nuevos playbooks de `archlinux/`.

## Verificación
Ejecutar syntax-check de los playbooks modificados:
```bash
source .venv/bin/activate
ansible-playbook --syntax-check steam-deck/playbook.yaml
ansible-playbook --syntax-check steam-deck/after-SO-upgrade.yaml
```

Si el entorno lo permite, revisar en modo check (`--check`) sin aplicar cambios reales.
