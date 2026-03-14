# Plan: Revisión configuración gráfica AMD Tuxedo InfinityBook 14 Gen10

## Resumen Ejecutivo

La gráfica AMD Radeon 860M está **funcionando correctamente** con el driver `amdgpu`, Mesa 26.0.1, y soporte Vulkan vía RADV en **Wayland**. El sistema usa **EFI boot (systemd-boot)**.

Según la wiki de Arch Linux para este modelo, existe una carencia importante: los **drivers específicos de TUXEDO** no están instalados.

---

## Estado Actual (Verificado)

### ✅ Lo que funciona correctamente:

| Componente | Estado | Detalle |
|------------|--------|---------|
| Kernel driver | ✅ | `amdgpu` cargado automáticamente |
| OpenGL | ✅ | 4.6 (Compatibility Profile) Mesa 26.0.1-arch1.1 |
| Renderer | ✅ | AMD Radeon 860M Graphics (radeonsi, krackan1, ACO, DRM 3.64) |
| Vulkan | ✅ | API 1.4.335, driver 26.0.1, device "AMD Radeon 860M Graphics (RADV KRACKAN1)" |
| Firmware | ✅ | `amd-ucode`, `linux-firmware-amdgpu`, `linux-firmware-radeon` instalados |
| ACO compiler | ✅ | Default desde Mesa 20.2 (activo) |
| KFD/ROCm | ✅ | Inicializado correctamente (kfd: amdgpu: added device 1002:1114) |
| Boot | ✅ | EFI boot con systemd-boot (initrd=EFI\Linux\initramfs-linux.img) |
| Display Server | ✅ | Wayland (KDE Plasma/KWin) |

### 📊 Hardware detectado:
```
65:00.0 Display controller: AMD/ATI Krackan [Radeon 840M / 860M Graphics] (rev c2)
Kernel driver in use: amdgpu
Kernel modules: amdgpu
CPU: AMD Ryzen AI 7 350 w/ Radeon 860M (family: 0x1a, model: 0x60)
```

---

## ⚠️ Mejoras Recomendadas

### 1. Drivers específicos TUXEDO (Alta prioridad) 🔴

Según https://wiki.archlinux.org/title/TUXEDO_InfinityBook_14_Gen10:

| Paquete | Propósito | Estado |
|---------|-----------|--------|
| `tuxedo-drivers-dkms` | Control de retroiluminación teclado, teclas función, fan control | ❌ No instalado |
| `tuxedo-control-center-bin` | GUI para perfiles de energía y control de ventiladores | ❌ No instalado |
| `tuxedo-yt6801-dkms-git` | Driver para Ethernet Motorcomm YT6801 | ❌ No instalado |

**Impacto**: Sin estos paquetes no funcionará:
- Retroiluminación del teclado
- Teclas de función especiales (F1-F12) 
- Control de ventiladores/perfiles de energía
- Ethernet por cable (si se usa)

**Instalación**:
```bash
yay -S tuxedo-drivers-dkms tuxedo-control-center-bin tuxedo-yt6801-dkms-git
sudo systemctl enable --now tccd.service
```

### 2. Parámetros kernel para teclado (Alta prioridad) 🟡

Según la FAQ de Tuxedo, el teclado puede no funcionar al resumir de suspend.

**Parámetros requeridos**:
```
i8042.reset i8042.nomux i8042.nopnp i8042.noloop
```

**Ubicación** (systemd-boot EFI):
Añadir a `/boot/loader/entries/arch.conf` en la línea `options`:
```
options root=/dev/mapper/Vol-root rw rd.luks.uuid=efdb1633-18f4-492a-81cd-578dd3bc7c9c rd.luks.options=discard i8042.reset i8042.nomux i8042.nopnp i8042.noloop
```

Luego regenerar initramfs (si es necesario) y reiniciar:
```bash
sudo mkinitcpio -P
```

### 3. Soporte 32-bit para aplicaciones/juegos (Media prioridad)

Para aplicaciones/juegos de 32-bit (Steam, juegos antiguos):

**Habilitar repositorio multilib** en `/etc/pacman.conf`:
```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

**Instalar**:
```bash
sudo pacman -Syu
sudo pacman -S lib32-mesa lib32-vulkan-radeon
```

### 4. Configuración Wayland - No requiere acciones ⚪

**Nota importante**: Al usar **Wayland** (no Xorg):

- ✅ **No se necesita** `xf86-video-amdgpu` - Wayland usa el backend DRM/KMS directamente
- ✅ **No se necesita** configuración en `/etc/X11/xorg.conf.d/` - Wayland no usa X11 config
- ✅ **No se necesita** TearFree - Wayland gestiona el tearing de forma nativa (generalmente mejor que X11)
- ✅ KDE Plasma con KWin en Wayland funciona correctamente con el driver `amdgpu`

La configuración actual en el playbook (línea 101-105 de `archlinux/010-configure.yaml`):
```yaml
- name: kwinrc Windows
  community.general.ini_file:
    path: "/home/{{ ansible_ssh_user }}/.config/kwinrc"
    section: Xwayland
    option: Scale
    value: 1
```

Esto está correcto para Wayland.

---

## 🔍 Verificaciones Adicionales

### Logs limpios
- ✅ No hay errores críticos en `dmesg` relacionados con amdgpu
- ✅ No hay errores en `journalctl -b0 -p3` para gráficos
- ✅ AMDGPU se inicializa correctamente con todos los IP blocks (gfx_v11_0, vcn_v4_0_5, etc.)

### Rendimiento
- GPU: 8 CUs activos, 512MB VRAM asignados
- Display Core v3.2.359 en DCN 3.5
- SMU inicializado correctamente

---

## Acciones Propuestas (Resumen)

| Prioridad | Acción | Comando/Archivo |
|-----------|--------|-----------------|
| 🔴 Alta | Instalar drivers TUXEDO | `yay -S tuxedo-drivers-dkms tuxedo-control-center-bin` |
| 🔴 Alta | Habilitar servicio tccd | `sudo systemctl enable --now tccd.service` |
| 🟡 Media | Añadir parámetros kernel teclado | Editar `/boot/loader/entries/arch.conf` |
| 🟢 Baja | Soporte 32-bit (opcional) | `sudo pacman -S lib32-mesa lib32-vulkan-radeon` |
| ⚪ N/A | Configuración X11 | No aplica - se usa Wayland |

---

## Conclusión

La configuración gráfica AMD está **funcional y correcta** para Wayland. El driver `amdgpu` se carga correctamente, Vulkan/OpenGL funcionan, y no hay errores en logs.

**La única carencia importante** son los **drivers específicos de TUXEDO** que proporcionan:
- Retroiluminación del teclado
- Control de ventiladores y perfiles de energía
- Teclas de función especiales

El playbook de Ansible no instala estos paquetes AUR. Se recomienda instalarlos manualmente o añadir una tarea al playbook para instalarlos vía `kewlfft.aur` (ya está en las colecciones instaladas según AGENTS.md).
