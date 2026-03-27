# Plan de Corrección de Errores Detectados

## Resumen

Tras analizar los logs del sistema y revisar la wiki de Arch Linux, se han identificado errores específicos en la configuración.

---

## Errores a Corregir

### 1. Solaar - Argumento Inválido (CRÍTICO)

**Problema:** El archivo `solaar.desktop` usa el argumento `-w hide-only` que no existe.

**Log de error:**
```
solaar: error: argument -w/--window: invalid choice: 'hide-only' (choose from show, hide, only)
```

**Solución:** Cambiar `hide-only` por `hide` (según wiki de Arch Linux).

**Referencia wiki:** `solaar -w hide`

### 2. Solaar - Permisos y Grupo plugdev

**Problema:** El usuario no está en el grupo `plugdev`, necesario para acceder a `/dev/hidraw*` sin root.

**Log de error:**
```
solaar: error: [Errno 13] Permission denied: '/dev/hidraw2'
cannot create uinput device: "/dev/uinput" cannot be opened for writing
```

**Solución:** 
1. Crear grupo `plugdev` si no existe
2. Añadir usuario al grupo `plugdev`
3. Recargar reglas udev: `udevadm control --reload-rules`

**Referencia wiki:** *"The following packages use the `plugdev` user group, create it if it does not exist, and add users to this group to avoid the need of running these as root"*

### 3. Bluetooth - BAP/ISO Socket y Configuración

**Problema:** Bluetooth Audio BAP requiere ISO Socket que no está habilitado.

**Log de error:**
```
bluetoothd[923]: profiles/audio/bap.c:bap_adapter_probe() BAP requires ISO Socket which is not enabled
bluetoothd[923]: Failed to set default system config for hci0
```

**Solución:** Mejorar configuración de `/etc/bluetooth/main.conf` con opciones adicionales para LE Audio.

---

## Archivos a Modificar

1. **archlinux/010-configure.yaml**
   - Corregir argumento de Solaar: `hide-only` → `hide`
   - Agregar tarea para crear grupo `plugdev`
   - Agregar tarea para añadir usuario al grupo `plugdev`
   - Agregar handler para recargar udev
   - Mejorar configuración de Bluetooth

---

## Cambios Específicos

### Cambio 1: Solaar desktop entry

```yaml
# Cambiar esto:
Exec=/bin/sh -c 'sleep 5 && solaar -w hide-only'

# Por esto:
Exec=/bin/sh -c 'sleep 5 && solaar -w hide'
```

### Cambio 2: Grupo plugdev y usuario

```yaml
- name: Create plugdev group
  group:
    name: plugdev
    state: present

- name: Add user to plugdev group
  user:
    name: "{{ user_name }}"
    groups: plugdev
    append: yes
```

### Cambio 3: Recargar reglas udev

```yaml
- name: Reload udev rules
  command: udevadm control --reload-rules
```

### Cambio 4: Configuración Bluetooth mejorada

```ini
[General]
Name = tuxedo
Class = 0x000100
DiscoverableTimeout = 0
AlwaysPairable = false
PairableTimeout = 0
AutoEnable=true
Privacy = device
JustWorksRepairing = always
Experimental = true
```

---

## Notas

- Los errores **ACPI BIOS** son bugs de firmware y no se pueden solucionar desde software.
- El error de `xdg-desktop-portal-kde` es cosmético y no afecta el funcionamiento.
- Después de aplicar los cambios, el usuario debe **cerrar sesión y volver a entrar** para que el grupo `plugdev` tenga efecto.
