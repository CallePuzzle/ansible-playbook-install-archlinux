# Plan: Solucionar Flickering AMD Radeon 860M en KWin Wayland

## Estado Actual
- `KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1` ya aplicado pero persiste el flickering
- Parámetros del kernel `amdgpu.dcdebugmask=0x410` y `amdgpu.sg_display=0` ya aplicados
- GPU: AMD Radeon 860M (Krackan) en Tuxedo InfinityBook Pro AMD Gen10

## Opciones Adicionales para Probar

### Opción 1: Deshabilitar Atomic Mode Setting (AMS) - RECOMENDADA

La variable `KWIN_DRM_NO_AMS=1` fuerza a KWin a usar el modo "legacy" en lugar de Atomic Mode Setting. Esto ha resuelto problemas de flickering y "crtc timeouts" para muchos usuarios con GPUs AMD.

**Implementación:**
```bash
# Añadir a /etc/environment.d/90-amdgpu-kwin.conf
KWIN_DRM_NO_AMS=1
```

**Ventajas:**
- Fácil de implementar y revertir
- Documentado en múltiples reportes de bugs de KDE
- No afecta el rendimiento general

**Desventajas:**
- Algunas características avanzadas (como HDR + VRR simultáneos) pueden no funcionar
- Es considerado un "legacy" mode

---

### Opción 2: Deshabilitar Direct Scanout

`KWIN_DRM_NO_DIRECT_SCANOUT=1` evita que KWin use direct scanout, que puede causar flickering en algunas configuraciones de AMD.

**Implementación:**
```bash
# Añadir a /etc/environment.d/90-amdgpu-kwin.conf
KWIN_DRM_NO_DIRECT_SCANOUT=1
```

**Ventajas:**
- Simple de probar
- Puede resolver problemas de sincronización

**Desventajas:**
- Puede aumentar ligeramente el uso de CPU/GPU por el compositing siempre activo

---

### Opción 3: Forzar Multi-GPU GL Finish

`KWIN_DRM_FORCE_MGPU_GL_FINISH=1` fuerza sincronización más estricta del buffer swap, útil para evitar tearing/flickering.

**Implementación:**
```bash
# Añadir a /etc/environment.d/90-amdgpu-kwin.conf
KWIN_DRM_FORCE_MGPU_GL_FINISH=1
```

**Ventajas:**
- Mejora sincronización de frames

**Desventajas:**
- Puede causar micro-stuttering
- Diseñado principalmente para multi-GPU

---

### Opción 4: Control de Power Management de VRAM (MCLK)

El flickering puede estar causado por el cambio dinámico de clocks de memoria VRAM. Hay dos enfoques:

#### 4a. Script de systemd para fijar clocks al boot:
```bash
# Crear /etc/systemd/system/amdgpu-mclk-fix.service
[Unit]
Description=Fix AMD GPU MCLK flickering
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo manual > /sys/class/drm/card0/device/power_dpm_force_performance_level && echo 3 > /sys/class/drm/card0/device/pp_dpm_mclk'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

#### 4b. Parámetro del kernel:
```
amdgpu.dpm=0  # Deshabilita Dynamic Power Management completamente
```

**Ventajas:**
- Resuelve flickering causado por transiciones de MCLK

**Desventajas:**
- Mayor consumo de batería (MCLK siempre en high)
- O menor rendimiento (MCLK siempre en low)

---

### Opción 5: Ajustar Safety Margin de Renderizado

`KWIN_DRM_OVERRIDE_SAFETY_MARGIN` aumenta el tiempo antes de que KWin empiece a renderizar el frame, útil para resoluciones altas/refresh rates.

**Implementación:**
```bash
# Valor por defecto es 1500 (microsegundos)
# Para monitores de alta frecuencia, probar con 3000 o 5000
KWIN_DRM_OVERRIDE_SAFETY_MARGIN=3000
```

---

### Opción 6: Parchear el Kernel (Avanzado)

El parche de Mario Limonciello que mencionas está enfocado a problemas de VPE (Video Processing Engine) en Strix Halo durante suspend/resume. Este es un fix específico que podría no resolver directamente el flickering de pantalla, que parece estar más relacionado con Display Core (DC) y power management de MCLK.

### Complejidad de aplicar parches al kernel en Arch:

**Nivel de dificultad: ALTO** (~2-4 horas, requiere conocimientos técnicos)

**Pasos necesarios:**
1. Descargar el PKGBUILD de `linux` o `linux-lts` de ABS/Arch Build System
2. Aplicar el parche al código fuente del kernel
3. Compilar el kernel (30-60 minutos dependiendo del hardware)
4. Instalar el paquete generado
5. Mantener el kernel parcheado manualmente en cada actualización

**Alternativa menos invasiva:**
- Usar `linux-git` desde AUR que ya incluye los últimos parches de amdgpu
- O esperar a que el parche llegue al kernel estable (generalmente 1-2 meses)

**Recomendación:** Dado que el parche que mencionas está específicamente para VPE/suspend y no para el flickering de pantalla que estás experimentando, **no recomiendo aplicar este parche**. En su lugar, probar primero las opciones 1-5 que son menos invasivas y más específicas para el problema de flickering.

---

## Implementación Recomendada

Actualizar `/etc/environment.d/90-amdgpu-kwin.conf` con las siguientes variables en orden de prioridad:

```
# Workarounds para flickering en KDE con AMD Radeon 860M (Krackan)
KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1
KWIN_DRM_NO_AMS=1
KWIN_DRM_NO_DIRECT_SCANOUT=1
```

Probar combinaciones progresivamente:
1. Primero solo `KWIN_DRM_NO_AMS=1`
2. Si persiste, añadir `KWIN_DRM_NO_DIRECT_SCANOUT=1`
3. Si persiste, considerar el control de MCLK

## Archivos a Modificar

1. `/etc/environment.d/90-amdgpu-kwin.conf` - Variables de entorno KWin
2. Opcionalmente crear servicio systemd para control de MCLK

## Testing

Después de cada cambio:
```bash
# Recargar variables de entorno
systemctl --user daemon-reload

# Cerrar sesión y volver a entrar (reinicio recomendado para kernel params)
```

Verificar que las variables están cargadas:
```bash
cat /proc/$(pgrep kwin_wayland)/environ 2>/dev/null | tr '\0' '\n' | grep KWIN
```

Verificar estado de MCLK:
```bash
cat /sys/class/drm/card*/device/pp_dpm_mclk
```
