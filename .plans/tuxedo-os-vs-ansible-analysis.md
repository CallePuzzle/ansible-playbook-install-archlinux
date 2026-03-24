# Plan: Análisis Comparativo - Playbooks Ansible vs Tuxedo OS Actual

## 📊 Resumen Ejecutivo

| Aspecto | Playbooks Ansible (Arch) | Tuxedo OS Actual | Estado |
|---------|-------------------------|------------------|--------|
| **Distribución base** | Arch Linux | Ubuntu 24.04 LTS | 🔴 Diferente |
| **Kernel** | `linux` (vanilla) | `linux-tuxedo` 6.17 (custom) | 🟡 Diferente |
| **Bootloader** | systemd-boot + efibootmgr | GRUB | 🔴 Diferente |
| **Gestor de paquetes** | pacman | apt/dpkg | 🔴 Diferente |
| **Shell por defecto** | fish | bash | 🔴 Diferente |

---

## 🔍 Diferencias Detalladas

### 1. Sistema Base y Kernel

| Característica | Playbook Ansible | Tuxedo OS |
|----------------|------------------|-----------|
| Distribución | Arch Linux (rolling) | Tuxedo OS 24.04 (Ubuntu LTS) |
| Kernel | `linux` genérico | `linux-tuxedo-6.17` (customizado) |
| Versión exacta | - | 6.17.0-108014-tuxedo / 6.17.0-109014-tuxedo |
| Microcode | `amd-ucode` | Incluido en kernel tuxedo |
| LVM VG name | `Vol` | `system` |
| Bootloader | EFI stub con systemd-boot | GRUB 2.12 |
| cmdline | `rd.luks.name=... rd.luks.options=discard` | `quiet splash vt.handoff=7` |

**Impacto:** Tuxedo OS incluye optimizaciones específicas para el hardware que los playbooks no tenían.

---

### 2. Drivers Específicos Tuxedo ✅

| Paquete | Playbook Ansible | Tuxedo OS | Estado |
|---------|------------------|-----------|--------|
| `tuxedo-drivers` / `tuxedo-drivers-dkms` | ❌ No instalado | ✅ `tuxedo-drivers` 4.21.0 | 🔴 Faltaba en Ansible |
| `tuxedo-control-center` | ❌ No instalado | ✅ `tuxedo-control-center` 2.1.23 | 🔴 Faltaba en Ansible |
| `tuxedo-control-center-bin` | ❌ No instalado | ✅ Instalado | 🔴 Faltaba en Ansible |
| `tuxedo-yt6801` | ❌ No instalado | ✅ `tuxedo-yt6801` 1.0.31 | 🔴 Faltaba en Ansible |
| `tuxedo-tomte` | ❌ No instalado | ✅ `tuxedo-tomte` 2.61.3 | 🔴 Faltaba en Ansible |
| `tuxedo-io` (módulo) | ❌ No cargado | ✅ Cargado | 🔴 Faltaba en Ansible |
| `tuxedo-keyboard` | ❌ No instalado | ✅ Cargado | 🔴 Faltaba en Ansible |
| `tuxedo-touchpad-switch` | ❌ No instalado | ✅ Instalado | 🔴 Faltaba en Ansible |
| `tuxedo-plymouth` | ❌ No instalado | ✅ Instalado (boot animation) | 🔴 Faltaba en Ansible |
| `tuxedo-wallpapers-*` | ❌ No instalado | ✅ Instalados | 🔴 Faltaba en Ansible |
| `tuxedo-theme-plasma` | ❌ No instalado | ✅ Instalado | 🔴 Faltaba en Ansible |
| `sddm-theme-tuxedo` | ❌ No instalado | ✅ Instalado (v3.1) | 🔴 Faltaba en Ansible |
| `tuxedo-neofetch` | ❌ No instalado | ✅ Instalado | 🔴 Faltaba en Ansible |

**Estado actual en Tuxedo OS:**
- ✅ Retroiluminación de teclado funciona (detectado: white only keyboard backlight)
- ✅ Control de ventiladores con perfiles configurados (Overboost por defecto)
- ✅ Teclas de función especiales configuradas
- ✅ Perfil de carga de batería configurado (`high_capacity`)
- ✅ `tccd.service` activo y funcionando
- ✅ `tuxedo-tomte.timer` ejecutándose periódicamente (verifica/configura el sistema)

**Configuración TCC actual (`/etc/tcc/settings`):**
```json
{
  "fahrenheit": false,
  "stateMap": {
    "power_ac": "__default_custom_profile__",
    "power_bat": "__default_custom_profile__"
  },
  "chargingProfile": "high_capacity",
  "cpuSettingsEnabled": true,
  "fanControlEnabled": true,
  "keyboardBacklightControlEnabled": true
}
```

---

### 3. Entorno de Escritorio KDE Plasma

| Característica | Playbook Ansible | Tuxedo OS Actual |
|----------------|------------------|------------------|
| Versión Plasma | 6.6.2 (esperada) | 6.5.2 |
| Versión KWin | - | 6.5.2 |
| QT Version | - | 6.x (integrado) |
| Theme | Breeze (por defecto) | Tuxedo theme personalizado (`tuxedo-theme-plasma` 4.0.3) |
| SDDM | Habilitado | Habilitado con tema Tuxedo (`sddm-theme-tuxedo`) |

**Configuración KDE detallada:**

| Archivo | Playbook Ansible | Tuxedo OS Actual |
|---------|------------------|------------------|
| `kxkbrc` | `LayoutList=es,us`, `Options=caps:ctrl_modifier` | ❌ No existe (config por defecto) |
| `kwinrc` - Desktops | 3 escritorios: main, code, chat | 1 escritorio (por defecto) |
| `kwinrc` - Id_1 | `7f91f6e3-2733-4938-8721-957df2d769ae` | `30e4db42-c0ca-4c10-911b-107ea14aa470` |
| `kwinrc` - Id_2 | `be9529d6-f166-4890-9284-073fc1e17213` | ❌ No existe |
| `kwinrc` - Id_3 | `fdeb20f3-b204-498d-8552-7e3fa4ae4cc8` | ❌ No existe |
| `kwinrc` - Name_1 | `main` | ❌ No existe |
| `kwinrc` - Name_2 | `code` | ❌ No existe |
| `kwinrc` - Name_3 | `chat` | ❌ No existe |
| `kwinrc` - Number | `3` | `1` |
| `kwinrc` - Rows | `1` | `1` |
| `kwinrc` - RollOverDesktops | `true` | No configurado |
| `kwinrc` - Xwayland Scale | `1` | `1.6` |
| `kwinrc` - ButtonsOnRight | No configurado | `IAX` |
| `kwinrc` - Tiling padding | No configurado | `4` |
| `kglobalshortcutsrc` | Atajos personalizados (Meta+PgUp/Down, etc.) | Configuración por defecto de Tuxedo |

**⚠️ Lo que falta en Tuxedo OS:**
- Configuración de teclado con layouts es/us y caps como ctrl
- Tres escritorios virtuales configurados con nombres (main, code, chat)
- RollOverDesktops activado
- Atajos de teclado personalizados:
  - `Meta+PgUp` / `Meta+Up` → Maximizar ventana
  - `Meta+PgDown` / `Meta+Down` → Minimizar ventana
  - `Meta+Backspace` → Ocultar borde de ventana
  - `Meta+Left/Right` → Tile ventana izquierda/derecha
  - `Ctrl+Alt+Left/Right` → Cambiar escritorio

---

### 4. Shell y Terminal

| Característica | Playbook Ansible | Tuxedo OS Actual |
|----------------|------------------|------------------|
| Shell por defecto | fish | bash |
| fish version | Última | No instalado |
| fisher (plugin manager) | ✅ Instalado (jorgebucaran/fisher) | ❌ No instalado |
| Plugins fish | `hydro`, `bass` | ❌ Ninguno |
| `config.fish` | Configurado con SSH agent, ASDF, aliases | ❌ No existe |
| `fish_plugins` | ✅ Creado | ❌ No existe |
| `fish_mode_prompt.fish` | ✅ Función personalizada (VI mode) | ❌ No existe |
| Ghostty | ✅ Instalado y configurado | ❌ No instalado |
| Ghostty config | `copy-on-select`, keybinds personalizados | ❌ No existe |

**Configuración fish del playbook:**
```fish
# SSH agent con ksshaskpass
if test -n "$DESKTOP_SESSION"
    set -x SSH_ASKPASS /usr/bin/ksshaskpass
    eval (ssh-agent -c)
    ssh-add < /dev/null
end

# Paths
set -Ua fish_user_paths $HOME/.local/bin
set -gx --prepend PATH $HOME/.asdf/shims
set -x PATH $PATH $HOME/go/bin

# Alias
alias zed="zeditor"
```

---

### 5. Paquetes de Aplicaciones

#### ✅ Instalados en ambos:

| Paquete | Playbook | Tuxedo OS | Notas |
|---------|----------|-----------|-------|
| `firefox` | ✅ | ✅ v148.0 | Tuxedo: con locales es/de/en |
| `vlc` | ✅ | ✅ | OK |
| `kcalc` | ✅ | ✅ v25.08.2 | OK |
| `dolphin` | ✅ | ✅ v25.08.2 + nextcloud integration | OK |
| `ark` | ✅ | ✅ v25.08.2 | OK |
| `spectacle` | ✅ | ✅ (kde-spectacle v6.5.2) | OK |
| `okular` | ✅ | ✅ | OK |
| `gwenview` | ✅ | ✅ v25.08.2 | OK |
| `htop` | ✅ | ✅ v3.3.0 | OK |
| `git` | ✅ | ✅ v2.43.0 | OK |
| `nextcloud-client` | ✅ | ✅ v4.0.6 (nextcloud-desktop) | OK |
| `cups` | ✅ | ✅ v2.4.7 | OK |
| `bluez` / bluetooth | ✅ | ✅ v5.82 (con bluez-cups, bluez-obexd) | OK |
| `nfs-utils` | ✅ | ✅ (nfs-common v2.6.4) | Service masked |
| `unzip` | ✅ | ✅ v6.0 | OK |
| `wget` | ✅ | ✅ | OK |
| `rsync` | ✅ | ✅ | OK |
| `bind-tools` | ✅ | ✅ (bind9-dnsutils v9.18.39) | OK |
| `vim` | ✅ (implícito) | ✅ v9.1 | OK |
| `python3` | ✅ | ✅ v3.12.3 | OK |
| `bluez-utils` | ✅ | ✅ (integrado) | OK |
| `cups` | ✅ | ✅ | OK |
| `libcups` | ✅ | ✅ (libcups2t64) | OK |
| `print-manager` | ✅ | ✅ (integrado en KDE) | OK |
| `usbutils` | ✅ | ✅ | OK |

#### 🔴 Solo en Playbook (faltan en Tuxedo OS):

| Paquete | Versión esperada | Alternativa Ubuntu | Prioridad |
|---------|------------------|-------------------|-----------|
| `featherpad` | Última | `leafpad` o queda | Baja |
| `audacity` | Última | `audacity` | Media |
| `obsidian` | Última | Descargar de web | Alta |
| `telegram-desktop` | Última | `telegram-desktop` | Media |
| `btop` | Última | `btop` | Baja |
| `solaar` | Última | `solaar` | Media |
| `the_silver_searcher` (ag) | Última | `silversearcher-ag` | Baja |
| `emacs` | Última | `emacs` | Media |
| `ghostty` | Última | Compilar o esperar | Media |
| `sshpass` | Última | `sshpass` | Baja |
| `noto-fonts-emoji` | Última | `fonts-noto-color-emoji` | Baja |
| `python-virtualenv` | Última | `python3-venv` | Media |
| `fish` | Última | `fish` | Alta |
| `pacman-contrib` | - | N/A | N/A |

#### 🟡 Solo en Tuxedo OS (no estaban en playbooks):

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `build-essential` | 12.10ubuntu1 | Herramientas de compilación |
| `gcc-13/14` | 13.3.0 / 14.2.0 | Compiladores C/C++ |
| Mesa drivers | 25.2.8-1~24.04-tux1 | Drivers gráficos optimizados |
| `vulkan-tools` | 1.3.275.0 | Utilidades Vulkan |
| `libvulkan1` | 1.4.315.0-0tux1 | Loader Vulkan |
| `mesa-vulkan-drivers` | 25.2.8 | Drivers Vulkan Mesa |
| `mesa-va-drivers` | 25.2.8 | VA-API video acceleration |
| Firefox locales | - | es, de, en |
| `dolphin-nextcloud` | 4.0.6 | Integración Nextcloud en Dolphin |
| `kdeconnect` | 25.08.2 | Integración con móviles |

---

### 6. Configuración de Desarrollo

#### Zed Editor

| Característica | Playbook Ansible | Tuxedo OS |
|----------------|------------------|-----------|
| Instalado | ✅ | ✅ (en `~/.local/bin/zed`) |
| `settings.json` | ✅ Configurado completo | ❌ No existe |
| `keymap.json` | ✅ Configurado (Emacs bindings) | ❌ No existe |
| Directorio config | - | Existe pero vacío (solo themes/) |

**Configuración Zed del playbook:**
```json
{
  "edit_predictions": {
    "provider": "zed",
    "mode": "subtle",
    "enabled_in_text_threads": false
  },
  "agent": {
    "tool_permissions": { "default": "allow" },
    "default_profile": "write",
    "default_model": { "provider": "copilot_chat", "model": "claude-haiku-4.5" }
  },
  "base_keymap": "Emacs",
  "ui_font_size": 16,
  "buffer_font_size": 16,
  "theme": { "mode": "dark", "light": "One Light", "dark": "One Dark" }
}
```

#### Git

| Característica | Playbook Ansible | Tuxedo OS |
|----------------|------------------|-----------|
| `~/.gitconfig` | ✅ Copiado de `files/git.config` | ❌ No existe |
| GitHub CLI credentials | ✅ Configurado (`gh auth git-credential`) | ❌ No existe |
| Usuario/email | César M. Cristóbal / cesar@callepuzzle.com | N/A |
| Alias | br, st, d, dc, cm, co | N/A |

**Contenido `files/git.config`:**
```ini
[user]
    name = César M. Cristóbal
    email = cesar@callepuzzle.com
[alias]
    br = branch
    st = status
    d = diff
    dc = diff --cached
    cm = commit --message
    co = checkout
[http]
    sslVerify = true
[push]
    autoSetupRemote = true
[credential "https://github.com"]
    helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
    helper = !/usr/bin/gh auth git-credential
```

#### SSH

| Característica | Playbook Ansible | Tuxedo OS |
|----------------|------------------|-----------|
| `id_ed25519` | ✅ Copiado de `files/` | ✅ Generado nuevo |
| `id_ed25519.pub` | ✅ Copiado de `files/` | ✅ Generado nuevo |
| `id_rsa` | ✅ Copiado de `files/` | ❌ No existe |
| `id_rsa.pub` | ✅ Copiado de `files/` | ❌ No existe |
| `medapsis` / `medapsis.pub` | ✅ Copiado de `files/` | ❌ No existe |
| `~/.ssh/config` | ✅ Creado con SetEnv TERM | ❌ No existe |
| `known_hosts` | - | ✅ Existe |

**Configuración SSH del playbook:**
```
Host *
  SetEnv TERM=xterm-256color
```

#### Podman

| Característica | Playbook Ansible | Tuxedo OS |
|----------------|------------------|-----------|
| Instalado | ✅ Sí | ❌ No instalado |
| `podman.socket` | ✅ Habilitado (user) | ❌ No existe |
| `podman-restart.service` | ✅ Habilitado | ❌ No existe |
| Registries config | ✅ Configurado (docker.io) | ❌ No existe |
| subuid/subgid | ✅ Configurado (100000-165535) | ❌ No configurado |
| `unprivileged_userns_clone` | ✅ Habilitado | ❌ No configurado |

**Paquetes Podman en playbook:**
- `podman`, `netavark`, `aardvark-dns`, `podman-docker`, `passt`, `slirp4netns`, `fuse-overlayfs`

---

### 7. Servicios del Sistema

| Servicio | Playbook Ansible | Tuxedo OS | Estado |
|----------|------------------|-----------|--------|
| `sddm` | ✅ habilitado | ✅ habilitado y activo | OK |
| `NetworkManager` | ✅ habilitado | ✅ activo | OK |
| `bluetooth` | ✅ habilitado y arrancado | ✅ habilitado y activo | OK |
| `chronyd` | ✅ instalado y configurado | ❌ No instalado | 🔴 |
| `systemd-timesyncd` | ❌ (no aplica en Arch) | ✅ habilitado y activo | 🟡 |
| `cups` / `cups-browsed` | ✅ habilitado | ✅ ambos activos | OK |
| `cups.socket` / `cups.path` | - | ✅ habilitados | OK |
| `nfs-client` / `nfs-common` | - | ❌ Masked | - |
| `podman.socket` | ✅ habilitado (user) | ❌ No existe | 🔴 |
| `tccd.service` | ❌ | ✅ activo | 🟡 Específico Tuxedo |
| `tuxedo-tomte.timer` | ❌ | ✅ habilitado | 🟡 Específico Tuxedo |
| `tuxedo-tomte.service` | ❌ | ✅ static | 🟡 Específico Tuxedo |
| `tuxedo-wifi-set-reg-domain.timer` | ❌ | ✅ habilitado | 🟡 Específico Tuxedo |
| `networkd-dispatcher` | - | ✅ habilitado | Ubuntu default |

---

### 8. Configuraciones de Autostart

| Aplicación | Playbook Ansible | Tuxedo OS |
|------------|------------------|-----------|
| `solaar.desktop` | ✅ Creado (`solaar -w hide-only`) | ❌ No existe |
| `nextcloud.desktop` | ✅ Creado (`nextcloud --background`) | ❌ No existe |
| `tuxedo-control-center-tray.desktop` | ❌ | ✅ Creado por Tuxedo |

---

### 9. Red y Sincronización de Tiempo

| Característica | Playbook Ansible | Tuxedo OS |
|----------------|------------------|-----------|
| Zona horaria | `Europe/Madrid` | ✅ `Europe/Madrid` (CET, +0100) |
| Locale | `es_ES.UTF-8` | ✅ `es_ES.UTF-8` |
| Keymap (vconsole) | `es` | ❌ No configurado (`VC Keymap: unset`) |
| NTP service | `chronyd` | `systemd-timesyncd` |
| NTP servers | `pool.ntp.org`, `time.cloudflare.com` (NTS) | `ntp.ubuntu.com` |
| chrony config | `makestep 1.0 3`, `rtcsync` | N/A |

---

### 10. Problemas Gráficos - AMD Radeon 860M

#### Estado en Playbooks Ansible (ACTUALIZADO ✅)

| Configuración | Estado | Notas |
|---------------|--------|-------|
| `amdgpu.dcdebugmask=0x410` | ✅ Aplicado en GRUB y modprobe | Deshabilita PSR (Panel Self Refresh) |
| `amdgpu.sg_display=0` | ✅ Aplicado en GRUB y modprobe | Deshabilita scatter/gather |
| `acpi.ec_no_wakeup=1` | ✅ Aplicado en GRUB | Mejora batería durante sleep (2-3% vs 50-70% pérdida) |
| `KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1` | ✅ Configurado en /etc/profile.d | Workaround para flickering en KDE |
| Módulo `amdgpu` | ✅ Añadido a modules-load.d | Carga explícita del driver |
| Initramfs regenerado | ✅ mkinitcpio -P | Aplica cambios de modprobe |
| Kernel 6.19 | ❌ Se usaba último | Problemático con AMD 860M |
| `xf86-video-amdgpu` | ❌ No instalado | No necesario en Wayland |
| Configuración X11 | ❌ No aplicada | Sistema usa Wayland |

**Archivos configurados por el playbook `040-tuxedo.yaml`:**
- `/etc/default/grub` - Parámetros kernel AMD + acpi
- `/etc/modprobe.d/amdgpu.conf` - Opciones del módulo amdgpu
- `/etc/profile.d/kwin-amdgpu-workaround.sh` - Variable KWIN_DRM_DISABLE_TRIPLE_BUFFERING
- `/etc/modules-load.d/tuxedo.conf` - Añade módulo amdgpu

#### Estado en Tuxedo OS

| Configuración | Estado | Notas |
|---------------|--------|-------|
| Kernel | ✅ 6.17.0-108014-tuxedo | Kernel Tuxedo con parches |
| Mesa | ✅ 25.2.8-1~24.04-tux1 | Optimizado por Tuxedo |
| OpenGL | ✅ 4.6 (Compatibility) | Funcionando correctamente |
| Vulkan | ✅ 1.4.315 | `mesa-vulkan-drivers` |
| Driver AMDGPU | ✅ Cargado correctamente | `amdgpu` en kernel |
| Parámetros kernel PSR | ❌ No aplicados | Podría necesitarse |
| Variables KWin | ❌ No configuradas | Posible solución a flickering |

**Módulos AMD cargados en Tuxedo OS:**
```
amdgpu (principal)
snd_sof_amd_acp70, snd_sof_amd_acp63, snd_sof_amd_vangogh
snd_sof_amd_rembrandt, snd_sof_amd_renoir, snd_sof_amd_acp
snd_sof_pci, snd_sof_xtensa_dsp, amd_atl
```

**Nota:** A pesar de no tener los parámetros PSR deshabilitados, Tuxedo OS parece funcionar correctamente con el kernel personalizado.

---

### 11. Hardware Específico Detectado

#### GPU / Gráficos
```
00:00.0 Host bridge: AMD Krackan Root Complex
65:00.0 Display controller: AMD/ATI Krackan [Radeon 840M / 860M Graphics] (rev c2)
Kernel driver in use: amdgpu
Kernel modules: amdgpu
CPU: AMD Ryzen AI 7 350 w/ Radeon 860M
```

#### Almacenamiento
```
nvme0n1
├── nvme0n1p1: ext3 BOOT /boot (d16e31aa-48e2-4497-99dc-b99eaa71fd6b)
├── nvme0n1p2: vfat EFI /boot/efi (E493-EBB4)
└── nvme0n1p3: crypto_LUKS (2f32a1c7-2173-4787-a85d-fedf4e82bf87)
    └── crypt_dev_nvme0n1p3: LVM2_member
        └── system-root: ext4 / (020d50bc-4795-40a1-8309-e990e289e790)
```

**Nota:** Tuxedo OS mantiene la partición LUKS pero usa GRUB en lugar de EFI stub.

---

## 📋 Resumen de Estado

### ✅ Funcionando correctamente en Tuxedo OS:

1. **Hardware completo** con drivers Tuxedo
2. **Gráficos AMD** (kernel Tuxedo incluye parches)
3. **KDE Plasma 6.5.2** estable
4. **Servicios esenciales** (SDDM, NetworkManager, Bluetooth, CUPS)
5. **Aplicaciones principales** (Firefox, VLC, Dolphin, etc.)
6. **Sincronización horaria** (systemd-timesyncd)
7. **Seguridad** (LUKS, firewall UFW con perfiles Tuxedo)

### 🔴 Falta en Tuxedo OS (configurado en playbooks):

#### Alta Prioridad:
1. **Fish shell** con configuración completa
2. **Configuración KDE personalizada:**
   - Layouts de teclado (es/us + caps como ctrl)
   - Tres escritorios (main, code, chat)
   - Atajos de teclado personalizados
3. **Zed** con settings y keymap personalizados
4. **Git config** con credenciales GitHub
5. **SSH config** con SetEnv TERM

#### Media Prioridad:
6. **Obsidian** - Gestor de notas
7. **Telegram Desktop** - Mensajería
8. **Audacity** - Edición de audio
9. **Solaar** - Gestión dispositivos Logitech
10. **Podman** - Contenedores
11. **Emacs** - Editor

#### Baja Prioridad:
12. **btop** - Monitor de recursos alternativo
13. **Ghostty** - Terminal
14. **the_silver_searcher** - Búsqueda de código
15. **sshpass** - SSH con password
16. **Featherpad/Leafpad** - Editor ligero
17. **Autostart** Nextcloud y Solaar

### 🟡 Consideraciones:

- **NFS:** El servicio está masked en Tuxedo OS (no se usa actualmente)
- **Chrony vs systemd-timesyncd:** Ambos funcionan, systemd-timesyncd es el default de Ubuntu
- **Kernel params PSR:** Tuxedo OS funciona sin ellos, pero podrían añadirse si hay flickering

---

## 🎯 Recomendaciones

### Opción A: Mantener Tuxedo OS + Configuraciones Manuales (Recomendada)

Ventajas:
- ✅ Soporte de hardware completo y estable
- ✅ Kernel optimizado por Tuxedo
- ✅ Actualizaciones y mantenimiento automático (tuxedo-tomte)
- ✅ Base Ubuntu LTS (estable)

Acciones:
1. Instalar paquetes faltantes vía apt
2. Copiar configuraciones KDE desde backup/playbook
3. Configurar fish como shell por defecto
4. Configurar Zed, Git, SSH
5. Configurar autostart applications

### Opción B: Volver a Arch Linux + Mejorar Playbooks

Ventajas:
- ✅ Rolling release, software más nuevo
- ✅ Total control de la instalación
- ✅ Sistema más ligero

Desventajas:
- ❌ Requiere instalar drivers Tuxedo manualmente (AUR)
- ❌ Kernel vanilla puede tener problemas con AMD 860M
- ❌ Más mantenimiento manual

Acciones:
1. Actualizar playbooks para incluir:
   - `tuxedo-drivers-dkms` (AUR)
   - `tuxedo-control-center-bin` (AUR)
   - `tuxedo-yt6801-dkms-git` (AUR)
   - Parámetros kernel para PSR
   - Kernel LTS como opción

---

## 📁 Archivos de Configuración Referencia

Los siguientes archivos deberían respaldarse/copiarse de los playbooks:

```
files/
├── git.config              → ~/.gitconfig
├── id_ed25519              → ~/.ssh/id_ed25519
├── id_ed25519.pub          → ~/.ssh/id_ed25519.pub
├── id_rsa                  → ~/.ssh/id_rsa (opcional)
└── id_rsa.pub              → ~/.ssh/id_rsa.pub (opcional)

Configuración generada por playbook:
├── ~/.config/kxkbrc
├── ~/.config/kwinrc
├── ~/.config/kglobalshortcutsrc
├── ~/.config/fish/config.fish
├── ~/.config/fish/fish_plugins
├── ~/.config/fish/functions/fish_mode_prompt.fish
├── ~/.config/ghostty/config
├── ~/.config/zed/settings.json
├── ~/.config/zed/keymap.json
├── ~/.ssh/config
├── ~/.config/autostart/solaar.desktop
└── ~/.config/autostart/nextcloud.desktop
```

---

*Plan generado el: 2026-03-23*
*Equipo: Tuxedo InfinityBook 14 Gen10*
*OS: Tuxedo OS 24.04.4 LTS*
*Kernel: 6.17.0-108014-tuxedo*
