# Plan: Crear 050-asdf.yaml para instalar asdf-vm

## Resumen
Crear un playbook Ansible en `archlinux/050-asdf.yaml` que instale asdf-vm desde AUR y configure los plugins de nodejs, golang y terraform.

## Contexto del proyecto
- Los playbooks en `archlinux/` usan formato YAML con `hosts: all`
- Se usa `become: yes` para tareas privilegiadas y `become_user` para ejecutar como usuario
- Ya existe configuración de ASDF en `010-configure.yaml` (líneas 377-389 en config.fish)
- No existe actualmente un playbook dedicado a instalar asdf
- Los paquetes AUR se instalan con el módulo `kewlfft.aur.aur` (ver `030-aur.yaml`)

## Implementación propuesta

### Estructura del playbook
1. **Instalar asdf-vm desde AUR**: Usar `kewlfft.aur.aur` con yay para instalar `asdf-vm`
2. **Instalar dependencias de plugins**: base-devel, openssl, curl (necesario para algunos plugins)
3. **Instalar plugins**:
   - nodejs (https://github.com/asdf-vm/asdf-nodejs.git)
   - golang (https://github.com/asdf-community/asdf-golang.git)
   - terraform (https://github.com/asdf-community/asdf-hashicorp.git)

### Contenido del archivo

```yaml
---
- name: Install asdf-vm from AUR and language plugins
  hosts: all
  vars:
    asdf_plugins:
      - { name: nodejs, url: https://github.com/asdf-vm/asdf-nodejs.git }
      - { name: golang, url: https://github.com/asdf-community/asdf-golang.git }
      - { name: terraform, url: https://github.com/asdf-community/asdf-hashicorp.git }
  tasks:
    - name: Install plugin dependencies
      pacman:
        name:
          - base-devel
          - openssl
          - curl
          - git
      become: yes
      become_method: sudo

    - name: Install asdf-vm from AUR
      kewlfft.aur.aur:
        name: asdf-vm
        state: present
        use: yay
        update_cache: yes
      become: yes
      become_user: "{{ ansible_ssh_user }}"

    - name: Install asdf plugins
      shell: |
        asdf plugin add {{ item.name }} {{ item.url }}
      args:
        executable: /usr/bin/fish
      become: yes
      become_user: "{{ ansible_ssh_user }}"
      loop: "{{ asdf_plugins }}"
      register: plugin_install
      changed_when: "'already added' not in plugin_install.stderr | default('')"
      failed_when:
        - plugin_install.rc != 0
        - "'already added' not in plugin_install.stderr | default('')"
```

## Notas
- Se usa `kewlfft.aur.aur` con `use: yay` igual que en `030-aur.yaml`
- El paquete AUR es `asdf-vm` (no `asdf`)
- Se usa `changed_when` y `failed_when` para manejar idempotencia cuando el plugin ya existe
- Los plugins se instalan sin versiones específicas (el usuario las instalará después con `asdf install`)
