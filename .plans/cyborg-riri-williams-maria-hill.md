# Plan: Solución Flasazos - Variable KWin en Wayland

## Diagnóstico Confirmado

✅ **Configuraciones aplicadas:**
- Kernel LTS en uso: `6.18.20-1-lts`
- Parámetros kernel GRUB: `amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0`
- Configuración modprobe: `/etc/modprobe.d/amdgpu.conf`
- Archivo profile.d: `/etc/profile.d/kwin-amdgpu-workaround.sh` con `KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1`

❌ **Problema identificado:** 
La variable está en `/etc/profile.d/` que solo se carga para shells de login. Como usas **Wayland**, KWin se inicia por systemd **antes** de que se cargue el profile, por eso el proceso `kwin_wayland` no recibe la variable.

---

## Solución

### Opción A: Usar /etc/environment (Recomendada)

Mover la variable a `/etc/environment` que es cargado por PAM al inicio de sesión, antes de que systemd inicie KWin:

```bash
# Añadir variable a /etc/environment
sudo tee -a /etc/environment << 'EOF'
KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1
EOF

# Opcionalmente, eliminar el archivo de profile.d (ya no es necesario)
# sudo rm /etc/profile.d/kwin-amdgpu-workaround.sh
```

### Opción B: Usar /etc/environment.d/ (Alternativa systemd)

Crear archivo en el directorio de environment.d que systemd carga automáticamente:

```bash
# Crear directorio si no existe
sudo mkdir -p /etc/environment.d

# Crear archivo con la variable
sudo tee /etc/environment.d/90-amdgpu-kwin.conf << 'EOF'
KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1
EOF
```

---

## Verificación

Después de reiniciar la sesión (o el sistema):

```bash
# Verificar que KWin tiene la variable
cat /proc/$(pgrep kwin_wayland)/environ 2>/dev/null | tr '\0' '\n' | grep KWIN
```

Debería mostrar: `KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1`

---

## Notas

- `/etc/profile.d/` solo funciona para sesiones X11 o shells de login
- `/etc/environment` es la forma tradicional y funciona con PAM
- `/etc/environment.d/` es la forma moderna con systemd
- Ambas opciones (A y B) funcionan para Wayland
- Es necesario reiniciar la sesión para que KWin reciba la variable
