#!/bin/bash
# Script para solucionar flasazos verdes en TUXEDO InfinityBook Pro AMD Gen10
# GPU: AMD Radeon 860M (Krackan)
# Problema: PSR/Panel Replay causa artifacts en pantalla interna (eDP)
# Solución: Añadir parámetros de kernel según wiki de Arch Linux

set -e

echo "=========================================="
echo "Fix para flasazos verdes - TUXEDO InfinityBook Pro AMD Gen10"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Este script debe ejecutarse como root${NC}"
    echo "Uso: sudo bash fix-tuxedo-flicker.sh"
    exit 1
fi

# Crear backup
echo -e "${YELLOW}[1/6] Creando backup de configuración EFI actual...${NC}"
BACKUP_FILE="/tmp/efiboot-backup-$(date +%Y%m%d-%H%M%S).txt"
efibootmgr -v > "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup guardado en: $BACKUP_FILE${NC}"
echo ""

# Mostrar configuración actual
echo -e "${YELLOW}[2/6] Configuración EFI actual:${NC}"
efibootmgr -v | grep -E "Boot[0-9]{4}"
echo ""

# Parámetros actuales del kernel (sin los parámetros de amdgpu)
CURRENT_CMDLINE=$(cat /proc/cmdline)
echo -e "${YELLOW}Parámetros actuales del kernel:${NC}"
echo "$CURRENT_CMDLINE"
echo ""

# Nuevos parámetros a añadir
NEW_PARAMS="i8042.reset i8042.nomux i8042.nopnp i8042.noloop amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0"
echo -e "${YELLOW}[3/6] Parámetros que se añadirán:${NC}"
echo "  - i8042.reset i8042.nomux i8042.nopnp i8042.noloop  (fix teclado Tuxedo)"
echo "  - amdgpu.dcdebugmask=0x410                          (deshabilita PSR + Panel Replay)"
echo "  - amdgpu.sg_display=0                               (deshabilita scatter/gather)"
echo ""

# Confirmación
echo -e "${RED}⚠ ADVERTENCIA:${NC}"
echo "Este script modificará la entrada de arranque EFI."
echo "Se eliminará la entrada Boot0000 y se creará una nueva."
echo ""
read -p "¿Continuar? (s/N): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operación cancelada."
    exit 0
fi
echo ""

# Obtener el disco y la ruta del loader desde la entrada actual
# La entrada actual tiene esta forma:
# Boot0000* Arch Linux HD(1,MBR,...)/EFI\Linux\vmlinuz-linux...
echo -e "${YELLOW}[4/6] Eliminando entrada EFI actual (Boot0000)...${NC}"
efibootmgr -b 0000 -B 2>/dev/null || echo "Nota: No se pudo eliminar Boot0000 (puede que no exista)"
echo -e "${GREEN}✓ Entrada anterior eliminada${NC}"
echo ""

# Crear nueva entrada EFI con los parámetros
# Nota: Los parámetros deben ir DESPUÉS del initrd en la línea de comandos EFI
echo -e "${YELLOW}[5/6] Creando nueva entrada EFI con parámetros...${NC}"

# La ruta del kernel y initrd
KERNEL_PATH="\\EFI\\Linux\\vmlinuz-linux"
INITRD_PATH="\\EFI\\Linux\\initramfs-linux.img"

# Comando completo para crear la entrada
# Parámetros del kernel existentes + nuevos parámetros
EXISTING_PARAMS="root=/dev/mapper/Vol-root rw rd.luks.uuid=efdb1633-18f4-492a-81cd-578dd3bc7c9c rd.luks.options=discard"
ALL_PARAMS="$EXISTING_PARAMS $NEW_PARAMS"

echo "Creando entrada: Arch Linux (con fixes)"
efibootmgr \
    --create \
    --label "Arch Linux (con fixes)" \
    --disk /dev/nvme0n1 \
    --part 1 \
    --loader "$KERNEL_PATH" \
    --unicode "$ALL_PARAMS initrd=$INITRD_PATH" \
    --verbose

echo -e "${GREEN}✓ Nueva entrada EFI creada${NC}"
echo ""

# Establecer la nueva entrada como primera opción de arranque
echo -e "${YELLOW}[6/6] Configurando orden de arranque...${NC}"
NEW_BOOTNUM=$(efibootmgr -v | grep -E "Arch Linux \(con fixes\)" | grep -oE "Boot[0-9a-fA-F]{4}" | head -1 | sed 's/Boot//')
if [ -n "$NEW_BOOTNUM" ]; then
    efibootmgr --bootorder "$NEW_BOOTNUM"
    echo -e "${GREEN}✓ Nueva entrada establecida como boot por defecto (Boot$NEW_BOOTNUM)${NC}"
else
    echo -e "${RED}⚠ No se pudo determinar el número de la nueva entrada${NC}"
    echo "Por favor, verifica manualmente con: sudo efibootmgr -v"
fi
echo ""

# Mostrar configuración final
echo -e "${GREEN}=========================================="
echo "Configuración EFI actualizada:"
echo "==========================================${NC}"
efibootmgr -v | grep -E "Boot[0-9]{4}|BootOrder"
echo ""

echo -e "${GREEN}=========================================="
echo "✓ Script completado exitosamente"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Reinicia el sistema: sudo reboot"
echo "2. Después del reinicio, verifica los parámetros:"
echo "   cat /proc/cmdline | grep -E 'amdgpu|i8042'"
echo ""
echo -e "${YELLOW}Si quieres revertir los cambios:${NC}"
echo "1. Arranca desde el backup (si existe en el menú de boot)"
echo "2. O restaura desde el backup: sudo bash /tmp/efiboot-backup-*.txt"
echo "3. O usa: sudo efibootmgr para gestionar entradas manualmente"
echo ""
echo -e "${YELLOW}Nota:${NC}"
echo "Los flasazos verdes deberían desaparecer después del reinicio."
echo "Si persisten, considera instalar el kernel LTS:"
echo "   sudo pacman -S linux-lts linux-lts-headers"
