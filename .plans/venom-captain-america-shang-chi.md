# Plan: Solución Flasazos Verdes - Kernel LTS y Configuración Adicional

## Diagnóstico Confirmado

✅ **Configuración actual (todas aplicadas correctamente):**
- Parámetros kernel: `amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0 acpi.ec_no_wakeup=1 i8042.*`
- Configuración modprobe: `/etc/modprobe.d/amdgpu.conf` ✅
- Variable KWin: `KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1` ✅
- Drivers Tuxedo: `tuxedo_keyboard`, `tuxedo_io` cargados ✅

❌ **Problema:** Los flasazos verdes persisten a pesar de tener todos los workarounds aplicados.

**Causa probable:** El kernel `linux` (6.19.x) tiene regresiones con AMD Radeon 860M (Krackan) que no se solucionan solo con parámetros.

---

## Soluciones

### Opción A: Instalar Kernel LTS (Recomendada)

El kernel LTS (6.12.x) es más estable y tiene mejor soporte para GPUs AMD sin las regresiones del kernel 6.19.

**Pasos:**
```bash
# 1. Instalar kernel LTS y headers
sudo pacman -S linux-lts linux-lts-headers

# 2. Regenerar GRUB para incluir nueva entrada
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 3. Reiniciar y seleccionar "Arch Linux LTS" en el menú de GRUB
sudo reboot

# 4. (Opcional) Configurar LTS como default si funciona bien
# Editar /etc/default/grub y cambiar GRUB_DEFAULT
```

**Ventajas:**
- Kernel más estable y probado
- Mejor soporte para AMD 860M
- Actualizaciones menos frecuentes (más seguras)

**Desventajas:**
- Software ligeramente más antiguo
- Posiblemente algunas características muy nuevas no disponibles

---

### Opción B: Configuración Adicional de KWin/Plasma

Si el problema ocurre principalmente en el escritorio KDE/Plasma, puede haber configuraciones adicionales de KWin que ayuden.

**Pasos:**
```bash
# 1. Verificar si se usa Wayland o X11
echo $XDG_SESSION_TYPE

# 2. Si es Wayland, probar en X11 (seleccionar en SDDM)

# 3. Añadir más variables de entorno para KWin/AMD
sudo tee /etc/profile.d/amdgpu-workaround-extended.sh << 'EOF'
# Workarounds extendidos para AMD Radeon 860M
export KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1
export KWIN_DRM_NO_AMS=1
export AMD_VULKAN_ICD=RADV
EOF
```

**Ventajas:**
- No requiere cambiar kernel
- Rápido de probar

**Desventajas:**
- Puede no ser suficiente con kernel 6.19
- Algunas características gráficas pueden verse afectadas

---

### Opción C: Actualizar Mesa y Drivers Gráficos

Asegurar que los drivers Mesa estén actualizados puede ayudar con problemas de AMD.

**Pasos:**
```bash
# Actualizar sistema y Mesa
sudo pacman -Syu mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon

# Verificar versión de Mesa
glxinfo | grep "OpenGL version"
```

---

## Recomendación

**Opción A (Kernel LTS)** es la más probable de resolver el problema definitivamente porque:
1. Los workarounds ya están todos aplicados y el problema persiste
2. El kernel 6.19 es conocido por tener regresiones con GPUs AMD recientes
3. El kernel LTS 6.12 tiene mejor soporte estable para AMD 860M
4. Es la solución recomendada en la wiki de Arch y foros de Tuxedo

---

## Verificación Post-Implementación

Después de aplicar la solución:

```bash
# Verificar kernel en uso
uname -r

# Verificar que los parámetros siguen aplicados
cat /proc/cmdline | grep -oE 'amdgpu[^ ]+'

# Verificar versión de Mesa
glxinfo | grep "OpenGL version" 2>/dev/null || echo "glxinfo no disponible"

# Probar reproducción de video y scroll
```

---

## Notas

- El playbook `archlinux/040-tuxedo.yaml` ya instala `linux-headers` y `dkms` que son necesarios para compilar módulos DKMS con kernel LTS
- Los drivers Tuxedo (`tuxedo-drivers-dkms`) se recompilarán automáticamente para el kernel LTS
- Se puede tener ambos kernels instalados y seleccionar en el menú de GRUB
