# Dockerfile para testing de Ansible con Arch Linux
# Basado en: https://github.com/CarloDePieri/docker-archlinux-systemd
# Y: https://github.com/geerlingguy/docker-archlinux-ansible

FROM archlinux:latest

# Establecer variable de entorno para indicar que estamos en un contenedor
ENV container=podman

# Instalar dependencias necesarias
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        systemd \
        systemd-sysv \
        sudo \
        python \
        python-pip \
        git \
        base-devel \
        openssh && \
    pacman -Scc --noconfirm

# Configurar systemd para contenedores
# Eliminar servicios innecesarios que no funcionan en contenedores
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
    for i in *; do \
        [ "$i" = "systemd-tmpfiles-setup.service" ] || rm -f "$i"; \
    done && \
    rm -f /lib/systemd/system/multi-user.target.wants/* && \
    rm -f /etc/systemd/system/*.wants/* && \
    rm -f /lib/systemd/system/local-fs.target.wants/* && \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
    rm -f /lib/systemd/system/basic.target.wants/* && \
    rm -f /lib/systemd/system/anaconda.target.wants/* && \
    rm -f /lib/systemd/system/plymouth* && \
    rm -f /lib/systemd/system/systemd-update-utmp*

# Crear usuario ansible para molecule (con sudo sin contraseña)
RUN useradd -m -G wheel ansible && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel && \
    mkdir -p /home/ansible/.ssh && \
    chown -R ansible:ansible /home/ansible

# Configurar SSH para aceptar conexiones locales
RUN mkdir -p /var/run/sshd && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Configurar hostname
RUN echo "archlinux-test" > /etc/hostname

# Volumes necesarios para systemd
VOLUME ["/sys/fs/cgroup", "/tmp", "/run", "/var/lib/containerd"]

# Usar systemd como entrypoint
ENTRYPOINT ["/usr/lib/systemd/systemd"]
CMD ["--log-level=info", "--unit=sysinit.target"]
