# Plan: Solución Flasazos Verdes AMD Radeon 860M + KDE Plasma Wayland

## Problema

Flasazos verdes intermitentes al cambiar de pestaña en aplicaciones con:
- GPU: AMD Radeon 860M (Krackan)
- KDE Plasma 6.6.2
- Wayland
- Driver amdgpu

## Investigación

Este es un issue conocido reportado por múltiples usuarios con GPUs AMD en KDE Plasma Wayland, especialmente en kernels 6.12+. Las causas identificadas incluyen:

1. **Triple Buffering** - Problemas con el triple buffering en el backend DRM de KWin
2. **Color Accuracy** - Configuración de "Preferir precisión de color" incompatible
3. **Adaptive Sync/VRR** - Problemas con Variable Refresh Rate
4. **AMD Gamma LUT** - Cambios frecuentes en GAMMA_LUT causan flickering

## Soluciones Propuestas (en orden de prioridad)

### 1. Deshabilitar Triple Buffering (Solución más común)

```bash
mkdir -p ~/.config/plasma-workspace/env
echo 'export KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1' > ~/.config/plasma-workspace/env/kwin_fix.sh
chmod +x ~/.config/plasma-workspace/env/kwin_fix.sh
```

Luego: Cerrar sesión y volver a entrar.

Referencias:
- https://bugs.kde.org/show_bug.cgi?id=494547
- Varios usuarios reportan que esto soluciona el flickering en GPUs AMD

### 2. Configurar Precisión de Color

Configuración del Sistema → Pantalla y monitor → [Seleccionar pantalla] → Precisión de color → **"Preferir eficiencia"**

Nota: "Preferir precisión de color" puede causar distorsiones y flickering en GPUs AMD.

Referencias:
- https://discuss.kde.org/t/fix-rx-9070-9070xt-on-kde-plasma-wayland-distortion-and-flickering/32866

### 3. Variables de entorno adicionales para VRR/Adaptive Sync

Si tienes Adaptive Sync habilitado y persisten los problemas:

```bash
cat >> ~/.config/plasma-workspace/env/kwin_fix.sh << 'EOF'
export KWIN_DRM_DELAY_VRR_CURSOR_UPDATES=1
export KWIN_FORCE_SW_CURSOR=1
EOF
```

O alternativamente, deshabilitar Adaptive Sync completamente:
Configuración del Sistema → Pantalla y monitor → Adaptive Sync → **"Nunca"**

Referencias:
- https://discuss.kde.org/t/kde-nvidia-constant-frame-drops-in-desktop-use-with-nvidia-dkms-open-565-driver-wayland/26637

### 4. Workaround AMD Gamma (si las anteriores fallan)

Plasma 6.4.5+ incluye un workaround automático para AMD. Si causa problemas, deshabilitar:

```bash
echo 'export KWIN_DRM_DISABLE_AMD_GAMMA_WORKAROUND=1' >> ~/.config/plasma-workspace/env/kwin_fix.sh
```

Referencias:
- https://9to5linux.com/kde-plasma-6-4-5-fixes-brightness-flickering-issues-with-amd-gpu-drivers

### 5. Perfil de energía del kernel

Algunos usuarios reportan mejoras cambiando el perfil de energía a "performance":

```bash
sudo pacman -S power-profiles-daemon
powerprofilesctl set performance
```

Referencias:
- https://discussion.fedoraproject.org/t/screen-flicker-after-updating-from-kernel-6-12-4/141441

## Verificación

Después de aplicar cada solución, verificar:

```bash
# Verificar que la variable esté cargada
printenv | grep KWIN

# Verificar estado de KWin
qdbus org.kde.KWin /KWin supportInformation 2>/dev/null | head -50

# Ver logs de KWin
journalctl --user -u plasma-kwin_wayland.service -n 100 --no-pager
```

## Estado Actual

- [ ] Aplicar solución 1: Deshabilitar triple buffering
- [ ] Verificar si persiste el problema
- [ ] Si persiste: Probar solución 2 (precisión de color)
- [ ] Si persiste: Probar solución 3 (Adaptive Sync/VRR)
- [ ] Si persiste: Probar solución 4 (AMD gamma workaround)
- [ ] Documentar cuál solución funcionó

## Notas

- El issue está reportado en KDE bugs y hay fixes en desarrollo para Plasma 6.4+
- Algunos usuarios reportan que el problema desaparece completamente en Plasma 6.4.3+
- Mantener el sistema actualizado puede resolver el problema eventualmente
