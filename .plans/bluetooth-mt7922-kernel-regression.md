# Bluetooth MT7922 Kernel Regression - Tuxedo

## Fecha

2026-05-21

## Problema

El Bluetooth del Tuxedo (chipset MediaTek MT7922) dejó de funcionar tras
actualizaciones del kernel `linux-lts`. El adaptador aparece como `hci0` pero
falla al inicializarse.

## Diagnóstico

### Error clave en dmesg

```
Bluetooth: hci0: Failed to send wmt func ctrl (-22)
Bluetooth: hci0: HCI Enhanced Setup Synchronous Connection command is advertised, but not supported.
```

### Estado del sistema

- `bluetooth.service`: activo y corriendo
- `rfkill`: sin bloqueos (soft/hard: no)
- Firmware `linux-firmware-mediatek`: instalado y presente (`BT_RAM_CODE_MT7922_1_1_hdr.bin.zst`)
- Dispositivo USB detectado: `0e8d:c616 MediaTek Inc. Wireless_Device`
- `bluetoothctl list`: `No default controller available`

### Kernel afectado

- **Roto:** `linux-lts 6.18.32-1` (actual en el momento del plan)
- **Afectados también:** `linux 7.0.7.arch2-1`, `linux-lts 6.18.30+`
- **Funcionaba antes:** versiones anteriores a la regresión
- **Verificado (NO arreglado en LTS):** `linux-lts 6.18.33-1` — el PKGBUILD de Arch no incluye el patch
- **Estado kernel estable (linux):** el fix llegó en `7.0.8-arch1` según [foro Arch](https://bbs.archlinux.org/viewtopic.php?id=313552), aunque hay reportes mixtos para ciertos dispositivos (`0e8d:e020`)

## Causa raíz

Regresión del driver `btmtk` en el kernel. No es culpa del firmware ni de los
playbooks de Ansible.

El fix upstream ya existe:

- **Commit upstream:** `67dba2c28fe0af7e25ea1aeade677162ed05310a`
- **Autor:** Chris Lu <chris.lu@mediatek.com>
- **Título:** `Bluetooth: btmtk: Fix failed to send func ctrl for MediaTek devices.`
- **Fixes:** `5c5e8c52e3ca` ("Bluetooth: btmtk: move btusb_mtk_[setup, shutdown] to btmtk.c")
- **Descripción:** Añade `usb_autopm_get_interface()` / `usb_autopm_put_interface()`
  en `btmtk_usb_shutdown()` para manejar correctamente el USB autosuspend.

Este commit fue integrado en el kernel `6.12.10`, pero **no está presente en**
`linux-lts 6.18.32-1` (al menos no funciona correctamente, lo que sugiere que
puede haber una regresión adicional o backport incorrecto en la rama 6.18).

## Referencias

- Debian bug: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1136945
- Arch Linux thread (general): https://bbs.archlinux.org/viewtopic.php?id=313561
- Arch Linux thread (bluetooth not working after kernel update): https://bbs.archlinux.org/viewtopic.php?id=313552
- Ubuntu bug: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2097139
- Gentoo thread: https://forums.gentoo.org/viewtopic.php?p=8885583
- Framework Community: https://community.frame.work/t/bluetooth-stopped-working-after-kernel-7-0-7-update/82594
- Debian changelog con el fix: https://launchpad.net/debian/+source/linux/+changelog?batch=75&memo=75&start=75
- Kernel changelog 6.12.10: https://www.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.12.10
- Kernel bugzilla: https://bugzilla.kernel.org/show_bug.cgi?id=221552

## Workaround actual

### Downgrade del kernel LTS

Los paquetes antiguos están en caché en `/var/cache/pacman/pkg/`.

**Comando para bajar a `6.18.29-1`:**

```bash
sudo pacman -U \
  /var/cache/pacman/pkg/linux-lts-6.18.29-1-x86_64.pkg.tar.zst \
  /var/cache/pacman/pkg/linux-lts-headers-6.18.29-1-x86_64.pkg.tar.zst
```

**Evitar actualización automática hasta que salga el fix:**

```bash
sudo sed -i '/^#IgnorePkg/a IgnorePkg = linux-lts linux-lts-headers' /etc/pacman.conf
```

**Reiniciar:**

```bash
sudo reboot
```

### Si 6.18.29 también falla

Probar con versiones anteriores disponibles en caché:
- `linux-lts-6.18.28-1`
- `linux-lts-6.18.26-2`
- `linux-lts-6.18.25-1`

## Cambio en playbooks

Se eliminó `AutoEnable=true` de `/etc/bluetooth/main.conf` en
`archlinux/010-configure.yaml` porque `bluetoothd` 5.86 ya no reconoce esa
clave (genera warning `Unknown key AutoEnable for group General`).

## Plan de seguimiento

### Cuándo revertir los cambios

1. **Quitar `IgnorePkg`** de `/etc/pacman.conf` cuando el kernel LTS incluya
   el fix upstream (`67dba2c28fe0af7e25ea1aeade677162ed05310a` o equivalente).
2. **Actualizar** a la nueva versión de `linux-lts`.
3. **Verificar** que el Bluetooth funciona tras el reinicio:
   ```bash
   bluetoothctl list
   dmesg | grep -i "hci0\|btmtk\|wmt func ctrl"
   ```

### Cómo verificar que el fix ha llegado a Arch

1. Revisar el changelog del paquete `linux-lts`:
   ```bash
   pacman -Q linux-lts
   ```
   Y buscar en los changelogs de kernel.org para la rama 6.18 que incluya el
   commit `67dba2c28fe0af7e25ea1aeade677162ed05310a` o el fix de `btmtk`.

2. O simplemente: quitar `IgnorePkg`, actualizar, reiniciar, y comprobar si
   `bluetoothctl list` devuelve el controlador.

### Notas

- El firmware `linux-firmware-mediatek` NO es el problema. No hace falta
  tocarlo.
- El fix upstream fue integrado en `6.12.10` pero la rama `6.18` parece
  reintroducir el bug o no tener el backport correcto. Hay que esperar a que
  Greg K-H o el equipo de Arch lo backporteen/resuelvan en una versión
  posterior de `6.18.x`.
