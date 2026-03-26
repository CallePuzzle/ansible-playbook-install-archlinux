# Plan: Migrar Playbooks a Configuración Tuxedo con GRUB

## Objetivo

Actualizar los playbooks de Ansible para mantener Arch Linux como sistema operativo pero adoptando la configuración de TuxedoOS, específicamente:
1. Cambiar el bootloader de EFI stub a **GRUB** (como usa TuxedoOS)
2. Añadir drivers y herramientas específicas de Tuxedo
3. Configurar el hardware específico del InfinityBook 14 Gen10

---

## Cambios Necesarios

### 1. Laptop - Playbook 000-platform-base.yaml

**Cambio de esquema de particiones:**

TuxedoOS usa este layout:
- `nvme0n1p1`: ext3 BOOT /boot 
- `nvme0n1p2`: vfat EFI /boot/efi
- `nvme0n1p3`: LUKS con LVM (system-root)

**Modificaciones requeridas:**

```yaml
# AÑADIR en host_vars/tuxedo.yaml:
# Separar /boot (ext4) y /boot/efi (vfat)
boot_partition: "/dev/nvme0n1p1"      # /boot - ext4 (1GiB recomendado)
efi_partition: "/dev/nvme0n1p2"       # /boot/efi - vfat 512MiB
luks_partition: "/dev/nvme0n1p3"      # Encrypted LVM

# Cambiar nombre del VG de "Vol" a "system" (como TuxedoOS)
lvm_vg_name: "system"
```

**Tasks a modificar:**
1. Crear 3 particiones en lugar de 2 (boot ext4, efi vfat, luks)
2. Formatear boot como ext4 (no vfat) para GRUB
3. Mantener EFI como vfat separada
4. Cambiar nombre del VG a "system"

### 2. Laptop - Playbook 010-configure-chroot-env.yaml

**Reemplazar toda la configuración de EFI stub por GRUB:**

```yaml
# ELIMINAR:
# - Instalación de efibootmgr
# - Creación de /boot/EFI/Linux
# - Copias de vmlinuz/initramfs a EFI
# - Creación de efistub-update.path/service
# - Creación de entrada EFI con efibootmgr

# AÑADIR - Instalación y configuración de GRUB:

# 1. Instalar GRUB y dependencias
- name: Install GRUB and dependencies
  command: arch-chroot /mnt bash -c 'pacman -S --noconfirm --needed grub efibootmgr os-prober'

# 2. Configurar /etc/default/grub para LUKS
- name: Configure GRUB for LUKS
  copy:
    dest: /mnt/etc/default/grub
    content: |
      GRUB_DEFAULT=0
      GRUB_TIMEOUT=5
      GRUB_DISTRIBUTOR="Arch"
      GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
      GRUB_CMDLINE_LINUX="cryptdevice=UUID={{ luks_device.uuid }}:cryptlvm root=/dev/mapper/system-root resume=/dev/mapper/system-swap rd.luks.options=discard"
      GRUB_PRELOAD_MODULES="part_gpt part_msdos"
      GRUB_ENABLE_CRYPTODISK=y
      GRUB_GFXMODE=auto
      GRUB_GFXPAYLOAD_LINUX=keep

# 3. Configurar mkinitcpio con hooks correctos para GRUB + LUKS
# (Cambiar de sd-encrypt a encrypt si se usa hook busybox)
- name: Configure mkinitcpio for GRUB
  lineinfile:
    path: /mnt/etc/mkinitcpio.conf
    line: "HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)"
    regexp: '^HOOKS=\('

# 4. Instalar GRUB en modo EFI
- name: Install GRUB EFI
  command: arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck

# 5. Generar configuración GRUB
- name: Generate GRUB config
  command: arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# 6. Añadir kernel parameters para hardware Tuxedo (suspend/resume)
# Ver: https://wiki.archlinux.org/title/TUXEDO_InfinityBook_14_Gen10
- name: Configure Tuxedo kernel parameters
  lineinfile:
    path: /mnt/etc/default/grub
    regexp: '^GRUB_CMDLINE_LINUX="'
    line: 'GRUB_CMDLINE_LINUX="cryptdevice=UUID={{ luks_device.uuid }}:cryptlvm root=/dev/mapper/system-root resume=/dev/mapper/system-swap rd.luks.options=discard i8042.reset i8042.nomux i8042.nopnp i8042.noloop"'
```

### 3. Archlinux - Playbook 000-base.yaml

**Añadir kernel LTS y headers para DKMS:**

```yaml
# Modificar task "Install X" para añadir:
- name: Install base packages including kernel headers
  pacman:
    name:
      - mesa
      - plasma
      - linux-headers        # Necesario para DKMS
      - linux-lts            # Kernel LTS opcional (más estable)
      - linux-lts-headers    # Headers para kernel LTS
      - dkms                 # Framework para módulos del kernel
```

### 4. Archlinux - Playbook 010-configure.yaml

**Añadir paquetes específicos de Tuxedo:**

```yaml
# AÑADIR a la lista de paquetes:
- name: Install necessary packages
  pacman:
    name:
      # ... paquetes existentes ...
      # Drivers y utilidades Tuxedo (desde repos oficiales primero)
      - vulkan-tools         # Herramientas Vulkan
      - mesa-utils           # Utilidades Mesa
      - vulkan-radeon        # Driver Vulkan AMD
      - libvdpau-va-gl       # VA-API video acceleration
```

### 5. Nuevo Playbook: archlinux/040-tuxedo.yaml

**Crear nuevo playbook para drivers y configuración Tuxedo:**

```yaml
---
- name: Configure Tuxedo specific hardware and drivers
  hosts: all
  tasks:
    # 1. Instalar yay si no está instalado (desde 030-aur.yaml)
    # 2. Instalar drivers Tuxedo desde AUR
    - name: Install Tuxedo drivers from AUR
      kewlfft.aur.aur:
        name: "{{ item }}"
        state: present
        use: yay
      become: yes
      become_user: "{{ ansible_ssh_user }}"
      loop:
        - tuxedo-drivers-dkms       # Drivers kernel: teclado, retroiluminación, I/O
        - tuxedo-control-center-bin # Centro de control Tuxedo
        - tuxedo-yt6801-dkms-git    # Driver ethernet YT6801 (si aplica)
      when: inventory_hostname == "tuxedo"

    # 3. Habilitar servicios Tuxedo
    - name: Enable Tuxedo Control Center service
      ansible.builtin.systemd:
        name: tccd.service
        enabled: yes
        state: started
      become: yes
      when: inventory_hostname == "tuxedo"

    # 4. Crear autostart para Tuxedo Control Center tray
    - name: Configure Tuxedo Control Center tray autostart
      copy:
        dest: "/home/{{ ansible_ssh_user }}/.config/autostart/tuxedo-control-center-tray.desktop"
        owner: "{{ ansible_ssh_user }}"
        content: |
          [Desktop Entry]
          Type=Application
          Name=Tuxedo Control Center
          Exec=tuxedo-control-center --tray
          Icon=tuxedo-control-center
          Comment=Tuxedo Control Center Tray
          X-GNOME-Autostart-enabled=true
      when: inventory_hostname == "tuxedo"

    # 5. Configurar parámetros de charging profile (opcional)
    # Basado en configuración actual de TuxedoOS
    - name: Configure Tuxedo charging profile
      ansible.builtin.command: |
        echo "high_capacity" > /sys/bus/platform/drivers/tuxedo_keyboard/tuxedo_keyboard/charging_profile/charging_profile
      become: yes
      ignore_errors: yes
      when: inventory_hostname == "tuxedo"
```

### 6. Modificaciones a host_vars/tuxedo.yaml

```yaml
---
disk_name: "/dev/nvme0n1"

# Nuevo esquema de particiones (estilo TuxedoOS)
boot_partition: "/dev/nvme0n1p1"      # /boot - ext4 - 1GiB
efi_partition: "/dev/nvme0n1p2"       # /boot/efi - vfat - 512MiB
luks_partition: "/dev/nvme0n1p3"      # Encrypted container

# Tamaños de particiones
boot_partition_size: "1GiB"           # Aumentado para GRUB
efi_partition_size: "512MiB"

luks_device:
  device: "/dev/nvme0n1p3"
  name: "cryptlvm"
  type: "luks2"
  uuid: "efdb1633-18f4-492a-81cd-578dd3bc7c9c"

# VG name cambiado a "system" (como TuxedoOS)
lvm_vg_name: "system"

lvm_partitions:
  - name: swap
    size: 16g                       # Aumentado para Tuxedo
    type: swap
  - name: root
    size: "100%FREE"
    type: ext4
    path: /

cpu_vendor: amd
user_name: cesar

# ... contraseñas cifradas ...
```

### 7. Actualizar archlinux/030-aur.yaml

**Añadir los paquetes de Tuxedo como variables por host:**

```yaml
---
- name: Install AUR packages
  hosts: all
  vars:
    base_aur_packages:
      - yay
    tuxedo_aur_packages:
      - tuxedo-drivers-dkms
      - tuxedo-control-center-bin
      - tuxedo-yt6801-dkms-git
  tasks:
    # ... tasks existentes para yay ...

    # Instalar paquetes específicos de Tuxedo solo en host tuxedo
    - name: Install Tuxedo AUR packages
      kewlfft.aur.aur:
        name: "{{ item }}"
        state: present
        use: yay
        update_cache: yes
      become: yes
      become_user: "{{ ansible_ssh_user }}"
      loop: "{{ tuxedo_aur_packages }}"
      when: 
        - item != 'yay'
        - inventory_hostname == "tuxedo"
```

---

## Consideraciones Técnicas

### GRUB con LUKS2

Según la wiki de Arch Linux, GRUB tiene soporte limitado para LUKS2. Recomendaciones:

1. **Usar LUKS1** o **LUKS2 con PBKDF2** (no Argon2):
   ```bash
   cryptsetup luksFormat --type luks1 /dev/nvme0n1p3
   # O para LUKS2:
   cryptsetup luksFormat --pbkdf pbkdf2 /dev/nvme0n1p3
   ```

2. **Configurar GRUB_ENABLE_CRYPTODISK=y** para desbloqueo en boot

3. **Hooks de mkinitcpio**: Usar `encrypt` en lugar de `sd-encrypt` si se usa el hook busybox tradicional

### Kernel Parameters Específicos Tuxedo

Según la [wiki de Arch](https://wiki.archlinux.org/title/TUXEDO_InfinityBook_14_Gen10):

1. **Teclado después de suspend**: 
   ```
   i8042.reset i8042.nomux i8042.nopnp i8042.noloop
   ```

2. **Opcional - Problemas gráficos AMD** (si hay flickering):
   ```
   amdgpu.dcdebugmask=0x410 amdgpu.sg_display=0
   ```

### Servicios Tuxedo

- `tccd.service` - Control Center Daemon (habilitar y arrancar)
- No existe `tuxedo-tomte` en Arch (es específico de Ubuntu/TuxedoOS)

---

## Flujo de Instalación Modificado

### Fase 1: Instalación Base (desde Arch ISO)

```bash
# 1. Ejecutar playbook de particionado y base
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file laptop/000-platform-base.yaml -k

# 2. Ejecutar playbook de configuración chroot con GRUB
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file laptop/010-configure-chroot-env.yaml -k

# 3. Reboot
exit
reboot
```

### Fase 2: Post-instalación

```bash
# 1. Configuración base
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/000-base.yaml -k

# 2. Configuración de usuario y paquetes
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/010-configure.yaml -kK

# 3. Instalar yay
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/030-aur.yaml -kK

# 4. Instalar drivers Tuxedo
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/040-tuxedo.yaml -kK

# 5. Configurar desarrollo
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/020-developer.yaml -kK
```

---

## Archivos a Modificar

| Archivo | Cambios |
|---------|---------|
| `host_vars/tuxedo.yaml` | Añadir `efi_partition`, cambiar `lvm_vg_name` a "system", añadir tamaños de partición |
| `laptop/000-platform-base.yaml` | Modificar particionado: 3 particiones (boot ext4, efi vfat, luks), cambiar nombre VG |
| `laptop/005-mount-the-installation.yaml` | Añadir montaje de efi_partition |
| `laptop/010-configure-chroot-env.yaml` | **Reescribir completamente**: reemplazar EFI stub por GRUB |
| `archlinux/000-base.yaml` | Añadir `linux-headers`, `dkms` |
| `archlinux/030-aur.yaml` | Añadir variables para paquetes Tuxedo |
| `archlinux/040-tuxedo.yaml` | **Crear nuevo**: drivers y servicios Tuxedo |

---

## Referencias

1. [Arch Wiki - GRUB](https://wiki.archlinux.org/title/GRUB)
2. [Arch Wiki - dm-crypt/Encrypting an entire system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)
3. [Arch Wiki - TUXEDO InfinityBook 14 Gen10](https://wiki.archlinux.org/title/TUXEDO_InfinityBook_14_Gen10)
4. [Tuxedo - Arch Linux y Manjaro](https://www.tuxedocomputers.com/en/Arch-Linux-and-Manjaro-on-TUXEDO-computers.tuxedo)
5. [AUR - tuxedo-drivers-dkms](https://aur.archlinux.org/packages/tuxedo-drivers-dkms)
6. [AUR - tuxedo-control-center-bin](https://aur.archlinux.org/packages/tuxedo-control-center-bin)
