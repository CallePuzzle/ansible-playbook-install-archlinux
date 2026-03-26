# Plan: Solución para Flasazos Verdes AMD Radeon 860M (Krackan)

## Problema Identificado
- **Hardware**: Tuxedo laptop con AMD Radeon 860M (Krackan) - APU Ryzen AI 300
- **Kernel**: Linux 6.19.8-arch1-1 (muy reciente, posible regresión)
- **Síntoma**: Flasazos verdes/artifacts solo en pantalla interna (eDP), no en externa
- **Causa**: Panel Self Refresh (PSR) o Panel Replay habilitados en el panel eDP

## Estado Actual del Sistema
1. **Boot**: EFI directo mediante `efibootmgr` (sin GRUB ni systemd-boot tradicional)
2. **KWin**: Ya tiene configuraciones aplicadas (`KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1`, etc.)
3. **Parámetros kernel**: NO aplicados - `amdgpu.dcdebugmask=0x410` no está en `/proc/cmdline`
4. **Modprobe**: No hay configuración para deshabilitar PSR a nivel de módulo

## Soluciones Propuestas

### Opción A: Parámetros de Kernel vía EFI (Recomendada)
Modificar la entrada EFI directamente para añadir los parámetros necesarios:
- Deshabilitar PSR: `amdgpu.dcdebugmask=0x10`
- Deshabilitar Panel Replay: `amdgpu.dcdebugmask=0x400`
- Combinado: `amdgpu.dcdebugmask=0x410`
- Deshabilitar scatter/gather: `amdgpu.sg_display=0`

**Trade-offs**:
- ✅ Solución más efectiva, se aplica antes de cargar el driver
- ✅ Persiste después de reinicios
- ⚠️ Aumento de consumo de batería (~10-20%)
- ⚠️ Requiere modificar entrada EFI con `efibootmgr`

### Opción B: Configuración vía Modprobe
Crear configuración en `/etc/modprobe.d/amdgpu-psr.conf` para pasar parámetros al módulo.

**Trade-offs**:
- ✅ Más fácil de aplicar y revertir
- ✅ No requiere modificar entrada EFI
- ⚠️ El módulo ya está cargado en boot, puede requerir regenerar initramfs
- ⚠️ Menos efectivo que parámetros de kernel tempranos

### Opción C: Kernel LTS (Alternativa de respaldo)
Instalar y usar `linux-lts` (6.12.x) que tiene mejor soporte para GPUs AMD sin las regresiones de 6.19.

**Trade-offs**:
- ✅ Kernel más estable, probado con hardware AMD
- ✅ Puede resolver el problema sin workarounds
- ⚠️ Pierdes características más nuevas del kernel
- ⚠️ Requiere seleccionar kernel en bootloader

## Pasos de Implementación

### Para Opción A (EFI Boot Parameters):
1. Crear backup de entrada EFI actual
2. Eliminar entrada EFI actual (0000)
3. Crear nueva entrada EFI con parámetros amdgpu:
   - `amdgpu.dcdebugmask=0x410` (deshabilita PSR + Panel Replay)
   - `amdgpu.sg_display=0` (deshabilita scatter/gather)
4. Establecer nueva entrada como boot por defecto
5. Reiniciar y verificar con `cat /proc/cmdline`

### Para Opción B (Modprobe):
1. Crear `/etc/modprobe.d/amdgpu-psr.conf` con `options amdgpu dcdebugmask=0x410 sg_display=0`
2. Regenerar initramfs con `sudo mkinitcpio -P`
3. Reiniciar y verificar con `systool -v -m amdgpu 2>/dev/null | grep parm`

### Para Opción C (Kernel LTS):
1. Instalar `sudo pacman -S linux-lts linux-lts-headers`
2. Regenerar initramfs
3. Seleccionar kernel LTS en el menú de boot o modificar entrada EFI
4. Verificar funcionamiento

## Verificación Post-Implementación
- `cat /proc/cmdline` debe mostrar los parámetros aplicados
- `sudo cat /sys/kernel/debug/dri/*/eDP-*/psr_state` debe mostrar 0 (si existe)
- Probar reproducción de video y scroll en aplicaciones
- Verificar que no hay flasazos verdes

## Nota Importante
El kernel 6.19 es un kernel de desarrollo (mainline) con posibles regresiones. Si las opciones A o B no funcionan, la Opción C (kernel LTS) es la más probable de resolver el problema definitivamente.
