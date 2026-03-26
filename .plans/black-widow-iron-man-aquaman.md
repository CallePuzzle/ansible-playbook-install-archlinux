# Plan: Revisión de Playbook 010-configure.yaml vs Configuración Actual

## Hallazgos

### 1. Git Config (⚠️ PROBLEMA MAYOR)

**Playbook:** Copia `files/git.config` (configuración básica de 2023)
**Equipo actual:** `~/.gitconfig` tiene configuración más completa:
- Incluye credenciales de GitHub (`gh auth git-credential`)
- Mismo usuario/email y alias, pero con extras importantes

**Riesgo:** El playbook sobrescribiría la configuración actual perdiendo la integración con GitHub CLI

### 2. Paquetes (⚠️ FALTAN ALGUNOS)

| Paquete | En Playbook | En Equipo | Estado |
|---------|-------------|-----------|--------|
| ark | ✅ | ✅ | OK |
| audacity | ✅ | ✅ | OK |
| bluedevil | ✅ | ✅ | OK |
| bluez-utils | ✅ | ✅ | OK |
| btop | ✅ | ✅ | OK |
| cups | ✅ | ✅ | OK |
| dolphin | ✅ | ✅ | OK |
| emacs | ✅ | ✅ | OK |
| firefox | ✅ | ✅ | OK |
| git | ✅ | ✅ | OK |
| gwenview | ✅ | ✅ | OK |
| htop | ✅ | ✅ | OK |
| kcalc | ✅ | ✅ | OK |
| leafpad | ✅ | ✅ | OK |
| nextcloud-client | ✅ | ✅ | OK |
| nfs-utils | ✅ | ✅ | OK |
| noto-fonts-emoji | ✅ | ✅ | OK |
| obsidian | ✅ | ✅ | OK |
| okular | ✅ | ✅ | OK |
| print-manager | ✅ | ✅ | OK |
| python-virtualenv | ✅ | ✅ | OK |
| rsync | ✅ | ✅ | OK |
| spectacle | ✅ | ✅ | OK |
| sshpass | ✅ | ✅ | OK |
| telegram-desktop | ✅ | ✅ | OK |
| the_silver_searcher | ✅ | ✅ | OK |
| unzip | ✅ | ✅ | OK |
| usbutils | ✅ | ✅ | OK |
| vlc | ✅ | ✅ | OK |
| wget | ✅ | ✅ | OK |
| **bluez** | ✅ | ❌ | **FALTA** |
| **bluez-libs** | ✅ | ❌ | **FALTA** |
| **pulseaudio-bluetooth** | ✅ | ❌ | **FALTA** |
| **libcups** | ✅ | ❌ | **FALTA** |
| **bind-tools** | ✅ | ❌ | **FALTA** |

### 3. KDE Configuration (✅ OK)

**kxkbrc:** Coincide exactamente (LayoutList=es,us, Options=caps:ctrl_modifier)

**kwinrc:** Coincide exactamente:
- Mismos IDs de escritorios (main, code, chat)
- RollOverDesktops=True
- Xwayland Scale=1

**kglobalshortcutsrc:** Coincide en los atajos importantes:
- Window Maximize: Meta+PgUp\tMeta+Up ✅
- Window Minimize: Meta+PgDown\tMeta+Down ✅
- Window No Border: Meta+Backspace ✅
- Quick Tile atajos configurados ✅

### 4. SSH Keys (⚠️ PROBLEMA)

**Playbook:** Copia `files/id_rsa` y `files/id_rsa.pub` (de 2023)
**Equipo actual:** 
- Tiene `id_rsa` y `id_rsa.pub` (de 2023)
- Tiene también `id_ed25519` y `id_ed25519.pub` (más recientes, 2025)
- Tiene claves adicionales (`medapsis`, `medapsis.pub`)

**Riesgo:** El playbook podría sobrescribir las claves si son diferentes

## Propuesta de Cambios

### Opción A: Modificar Playbook (Recomendada)

1. **Git config:**
   - Opción A1: Actualizar `files/git.config` para incluir credenciales de GitHub
   - Opción A2: Hacer la tarea condicional (no sobrescribir si existe)

2. **Paquetes:** Agregar los 5 paquetes faltantes

3. **SSH:** 
   - Verificar si las claves en `files/` coinciden con las del equipo
   - Considerar hacer las tareas SSH opcionales (tag `ssh` ya existe)

### Opción B: Actualizar Archivos del Playbook

1. Copiar la configuración actual del equipo a `files/`:
   - `~/.gitconfig` → `files/git.config`
   - `~/.ssh/id_rsa*` → `files/id_rsa*` (si son las mismas)

## Recomendación

Recomiendo **Opción A** con las siguientes acciones:

1. Actualizar `files/git.config` con el contenido actual del equipo (incluyendo credenciales GitHub)
2. Agregar los paquetes faltantes al playbook
3. Verificar/actualizar las claves SSH en `files/`
4. Opcional: Agregar `id_ed25519` a la lista de claves SSH en el playbook
