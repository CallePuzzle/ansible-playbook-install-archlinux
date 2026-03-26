# Plan de Corrección de Playbooks de Arch Linux

## Resumen del Análisis de Logs

Se han analizado los logs del sistema (`dmesg`, `journalctl -b0`) y se han identificado varios problemas que pueden corregirse en los playbooks de Ansible.

---

## Errores Identificados y Soluciones

### 1. Permisos de Archivos de Autostart (010-configure.yaml)

**Problema:** El archivo `tuxedo-control-center-tray.desktop` tiene permisos de ejecución, lo que genera advertencias de systemd.

```
systemd-xdg-autostart-generator: Configuration file ... is marked executable.
Please remove executable permission bits.
```

**Solución:** Agregar una tarea para corregir permisos de archivos .desktop en autostart.

### 2. SDDM - Cursor por Defecto (000-base.yaml)

**Problema:** SDDM muestra el error "Could not setup default cursor" durante el inicio.

**Solución:** Instalar un tema de cursores completo que incluya cursores para X11.

### 3. Servicios de systemd (000-base.yaml)

**Problemas de D-Bus:**
- `systemd-resolved` está deshabilitado (error sobre `org.freedesktop.resolve1`)
- `systemd-homed` está deshabilitado (error sobre `org.freedesktop.home1`)
- `ModemManager` está instalado pero deshabilitado

**Solución:** Habilitar los servicios necesarios para el funcionamiento correcto de D-Bus.

### 4. PackageKit para Discover (010-configure.yaml)

**Problema:** DiscoverNotifier no puede cargar `libpackagekitqt6.so.2` porque PackageKit no está instalado.

**Solución:** Agregar `packagekit` y `packagekit-qt6` como paquetes opcionales si se desea usar Discover.

### 5. Bluetooth Configuración (010-configure.yaml)

**Problema:** Error de configuración por defecto de bluetoothd para hci0.

**Solución:** Agregar configuración de `/etc/bluetooth/main.conf` con opciones apropiadas.

### 6. Firmware Regulatorio (000-base.yaml)

**Problema:** El kernel no puede cargar `regulatory.db`.

**Solución:** Instalar `wireless-regdb` para la base de datos de regulaciones inalámbricas.

### 7. Solaar Service Failed (010-configure.yaml)

**Problema:** El servicio de Solaar en autostart falla al iniciar.

**Solución:** Verificar si falta dependencia `hid-logitech-dj` o agregar retraso en el autostart.

---

## Archivos a Modificar

1. **archlinux/000-base.yaml**
   - Agregar paquetes: `wireless-regdb`, tema de cursores (ej: `breeze-icons`)
   - Habilitar servicios: `systemd-resolved`, `ModemManager`
   - Configurar resolved

2. **archlinux/010-configure.yaml**
   - Corregir permisos de archivos .desktop en autostart
   - Agregar configuración de bluetooth
   - Agregar opcionalmente PackageKit
   - Mejorar configuración de Solaar

---

## Notas

- Los errores **ACPI BIOS** son bugs de firmware de la BIOS del Tuxedo y no pueden solucionarse desde los playbooks.
- Los errores de **dbus-broker** sobre nombres de servicios son problemas de empaquetado de KDE y no afectan el funcionamiento.
- Los errores de **xdg-desktop-portal** son advertencias cosméticas del sandboxing.
