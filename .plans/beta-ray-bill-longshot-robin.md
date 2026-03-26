# Plan: Migración de TuxedoOS a Arch Linux - Verificación de Configuraciones

## Estado Actual del Análisis

He revisado exhaustivamente los playbooks, host_vars, planes anteriores y la documentación del proyecto. Aquí está el resumen:

---

## ✅ Configuraciones Tuxedo YA IMPLEMENTADAS

### 1. Playbook `archlinux/040-tuxedo.yaml` (Completo)

Ya existe un playbook específico para Tuxedo que cubre todo lo esencial:

| Configuración | Estado | Descripción |
|--------------|--------|-------------|
| `tuxedo-drivers-dkms` | ✅ | Drivers del teclado, ventiladores, retroiluminación |
| `tuxedo-control-center-bin` | ✅ | GUI para control de ventiladores y perfiles |
| `tuxedo-yt6801-dkms-git` | ✅ | Driver ethernet YT6801 |
| `tccd.service` | ✅ | Servicio Tuxedo Control Center habilitado |
| Tray autostart | ✅ | Tuxedo Control Center inicia en tray |
| Kernel params (GRUB) | ✅ | `i8042.*`, `amdgpu.dcdebugmask=0x410`, `amdgpu.sg_display=0`, `acpi.ec_no_wakeup=1` |
| `/etc/modprobe.d/amdgpu.conf` | ✅ | Workarounds para Radeon 860M |
| `/etc/profile.d/kwin-amdgpu-workaround.sh` | ✅ | `KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1` |
| Charging profile | ✅ | `high_capacity` |
| `/etc/modules-load.d/tuxedo.conf` | ✅ | Módulos `tuxedo_keyboard`, `tuxedo_io`, `amdgpu` |
| Initramfs regeneration | ✅ | `mkinitcpio -P` después de cambios |

### 2. Playbooks de Instalación (`laptop/`)

| Aspecto | Estado | Notas |
|---------|--------|-------|
| Esquema de particiones | ✅ | Tres particiones: `/boot` (ext4), `/boot/efi` (vfat), LUKS |
| GRUB bootloader | ✅ | Configurado para LUKS + LVM |
| Host vars (`tuxedo.yaml`) | ✅ | UUID LUKS, passwords cifradas, config LVM |

### 3. Configuración Post-Instalación (`archlinux/`)

| Aspecto | Estado | Notas |
|---------|--------|-------|
| KDE Plasma | ✅ | Configurado con 3 escritorios, atajos personalizados |
| Fish shell | ✅ | Con fisher, hydro, bass |
| Ghostty terminal | ✅ | Configurado |
| Zed editor | ✅ | Settings y keymap personalizados |
| Aplicaciones | ✅ | Obsidian, Telegram, Solaar, Nextcloud, etc. |

---

## ⚠️ Consideraciones para la Migración

### 1. Hardware: InfinityBook Pro AMD Gen10

Según el análisis previo (`tuxedo-os-vs-ansible-analysis.md`):
- **GPU**: AMD Radeon 860M (Krackan) - REQUIERE los parámetros kernel ya configurados
- **Teclado**: Necesita parámetros `i8042.*` para funcionar después de suspend
- **Ethernet**: YT6801 - requiere driver `tuxedo-yt6801-dkms-git` del AUR

### 2. Script `fix-tuxedo-flicker.sh`

Existe un script manual que hace lo mismo que el playbook `040-tuxedo.yaml`. **No es necesario usarlo** si se ejecuta el playbook, pero puede servir como fallback.

### 3. Paquetes NO disponibles en Arch (específicos de Ubuntu/TuxedoOS)

| Paquete | Disponibilidad | Alternativa |
|---------|---------------|-------------|
| `tuxedo-tomte` | ❌ Solo Ubuntu | No esencial - es un gestor de configuración automática |
| `tuxedo-plymouth` | ❌ Solo Ubuntu | Opcional - animación de boot |
| `tuxedo-theme-plasma` | ❌ Solo Ubuntu | Opcional - tema visual |
| `sddm-theme-tuxedo` | ❌ Solo Ubuntu | Opcional - tema login |
| `tuxedo-neofetch` | ❌ Solo Ubuntu | Opcional - branding en neofetch |

**Conclusión**: Ninguno de estos es crítico para el funcionamiento del sistema.

---

## 📋 Checklist Pre-Migración

Antes de formatear TuxedoOS, verifica/respaldar:

### Datos Personales
- [ ] Directorio `~/` completo (Nextcloud ya sincroniza la mayoría)
- [ ] Configuraciones específicas de Tuxedo Control Center si se personalizaron

### Claves y Credenciales
- [ ] Las claves SSH ya están en `files/` del repo
- [ ] El vault de Ansible contiene las contraseñas necesarias

### Configuraciones Específicas de TuxedoOS
- [ ] Perfiles de Tuxedo Control Center (si se personalizaron)
  - Ubicación: `/etc/tcc/settings`
  - El playbook ya configura `high_capacity` por defecto

---

## 🚀 Proceso de Migración Recomendado

### Fase 1: Preparación desde TuxedoOS
1. Sincronizar Nextcloud completamente
2. Verificar que las claves SSH en `files/` están actualizadas
3. Hacer backup de `/etc/tcc/settings` si se personalizó TCC

### Fase 2: Instalación desde Arch ISO
```bash
# Boot desde USB con Arch ISO
# Conectar red y arrancar SSH
systemctl start sshd
passwd root

# Desde tu estación de trabajo con el repo clonado:
cd ansible-playbook-install-archlinux
source .venv/bin/activate

# Fase 1: Particionado, LUKS, LVM, base packages
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file laptop/000-platform-base.yaml -k

# Fase 2: Chroot, GRUB, configuración base
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file laptop/010-configure-chroot-env.yaml -k

# Salir de chroot y reiniciar
reboot
```

### Fase 3: Post-Instalación
```bash
# Desde el sistema recién instalado (como root):
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/000-base.yaml -k

# Como usuario (con sudo):
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/010-configure.yaml -kK
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/040-tuxedo.yaml -kK
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/020-developer.yaml -kK
```

### Fase 4: Verificación Post-Instalación
- [ ] Verificar que `tuxedo-control-center` se ejecuta
- [ ] Comprobar teclado después de suspend/resume
- [ ] Verificar no hay flickering en pantalla
- [ ] Revisar `cat /proc/cmdline` tiene los parámetros amdgpu

---

## 🔧 Posibles Ajustes Manuales Post-Instalación

Si algo no funciona perfectamente:

### 1. Kernel LTS (si hay problemas con kernel latest)
```bash
sudo pacman -S linux-lts linux-lts-headers
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 2. Recuperar TCC settings personalizados
```bash
# Si se hizo backup de /etc/tcc/settings desde TuxedoOS:
sudo cp /path/to/backup/settings /etc/tcc/settings
sudo systemctl restart tccd
```

---

## Conclusión

**¡Todo lo esencial ya está en los playbooks!** No hay configuraciones críticas faltantes. El playbook `040-tuxedo.yaml` cubre todos los aspectos de hardware específicos del InfinityBook Pro AMD Gen10.

La migración puede procederse con confianza siguiendo el proceso documentado en `AGENTS.md` y este plan.
