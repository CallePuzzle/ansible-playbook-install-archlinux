# Plan: Bootloader y Kernel para Flasazos Verdes Tuxedo

## Diagnóstico del Bootloader

**Confusión aclarada**: `systemd-boot` y `efibootmgr` **no son conflictivos**:
- `systemd-boot` = bootloader instalado en la partición EFI
- `efibootmgr` = herramienta para gestionar entradas UEFI en la NVRAM

**Tuxedo OS usa GRUB por defecto**, pero tu instalación Arch usa systemd-boot. Esto no es un problema en sí.

## El Problema Real

Los parámetros `amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0` **no están llegando al kernel**:
- No están en `/proc/cmdline`
- El archivo modprobe existe pero puede que el módulo sea built-in

## Solución: Configurar Correctamente el Bootloader

### Paso 1: Verificar qué bootloader está activo

```bash
# Verificar si systemd-boot está instalado
bootctl status

# Listar entradas disponibles
ls -la /boot/loader/entries/

# Ver configuración actual de entradas
cat /boot/loader/entries/*.conf
```

### Paso 2: Editar Entrada systemd-boot con los Parámetros

```bash
# Editar la entrada principal (probablemente arch.conf)
sudo vim /boot/loader/entries/arch.conf
```

Añadir los parámetros al final de la línea `options`:
```
title   Arch Linux
linux   /EFI/Linux/vmlinuz-linux
initrd  /EFI/Linux/initramfs-linux.img
options root=/dev/mapper/Vol-root rw rd.luks.uuid=efdb1633-18f4-492a-81cd-578dd3bc7c9c rd.luks.options=discard amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0
```

### Paso 3: Crear Entrada para Kernel LTS (Recomendado)

Dado que usas kernel 6.19 (problemático con AMD 860M), instalar LTS:

```bash
# Instalar kernel LTS
sudo pacman -S linux-lts linux-lts-headers

# Crear entrada para LTS con parámetros
sudo tee /boot/loader/entries/arch-lts.conf << 'EOF'
title   Arch Linux LTS
linux   /EFI/Linux/vmlinuz-linux-lts
initrd  /EFI/Linux/initramfs-linux-lts.img
options root=/dev/mapper/Vol-root rw rd.luks.uuid=efdb1633-18f4-492a-81cd-578dd3bc7c9c rd.luks.options=discard amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0
EOF

# Establecer LTS como default
sudo tee /boot/loader/loader.conf << 'EOF'
default arch-lts.conf
timeout 3
console-mode max
EOF
```

### Paso 4: Reiniciar y Verificar

```bash
sudo reboot
```

Después del reinicio:
```bash
# Verificar parámetros
cat /proc/cmdline | grep amdgpu

# Verificar kernel
uname -r
```

---

## Alternativa: Cambiar a GRUB (Si prefieres)

Si quieres usar el mismo bootloader que Tuxedo OS:

```bash
# Instalar GRUB
sudo pacman -S grub efibootmgr

# Instalar GRUB en EFI
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# Generar configuración
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Editar `/etc/default/grub` y añadir a `GRUB_CMDLINE_LINUX_DEFAULT`:
```
amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0
```

Luego regenerar configuración.

---

## Resumen

| Problema | Causa | Solución |
|----------|-------|----------|
| Parámetros no aplicados | Bootloader no configurado correctamente | Editar `/boot/loader/entries/arch.conf` |
| Kernel 6.19 inestable | Regresiones con AMD 860M | Instalar `linux-lts` |
| Flasazos persisten | Necesita parámetros + kernel estable | Aplicar ambas soluciones |

**No necesitas cambiar de bootloader**, solo configurar correctamente systemd-boot.
