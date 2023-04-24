# Ansible Playbook install Arch Linux

Ansible playbook to install Arch Linux on a laptop and configure Steam Deck in desktop mode.

## Python Virtual Environment

Create a Python virtual environment and install the dependencies.

```bash
$ python3 -m venv .venv
$ source .venv/bin/activate
$ pip install ansible
```

## Laptop

Download the latest Arch Linux ISO and write it to a USB stick.

``` bash
dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/sdx conv=fsync oflag=direct status=progress
```

Connect to the Internet: https://wiki.archlinux.org/title/Iwd#iwctl

``` bash
root@archiso# iwctl
[iwd]# station wlan0 connect CMCMT
```

When the Arch Linux Live is ready, start the ssh server and set the root password.

``` bash
root@archiso# systemctl start sshd
root@archiso# passwd
```

### Base installation

Run the playbooks to install the minimal Arch Linux system needed to start the laptop.

```bash
$ ansible-playbook -i laptop/inventory.ini --vault-password-file .vault-password-file laptop/000-platform-base.yaml -k
$ ansible-playbook -i laptop/inventory.ini --vault-password-file .vault-password-file laptop/010-configure-chroot-env.yaml -k
```

Exit the chroot environment and reboot the laptop.

```bash
root@archiso# arch-chroot /mnt
root@archiso# passwd
root@archiso# exit
root@archiso# reboot
```

## Arch Linux

After installing Arch Linux, run the playbooks to configure the laptop.

Connect to the Internet: https://wiki.archlinux.org/title/Iwd#iwctl

``` bash
root@host# systemctl start iwd
root@host# iwctl
[iwd]# station wlan0 connect CMCMT
[iwd]# exit
root@host# dhcpclient wlan0
```

The first one needs access by root.
* Allow ssh root login `# vim /etc/ssh/sshd_config`
* Start sshd

```bash
$ ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/000-base.yaml -k
```

Now, we can remove the access given in the previous step. And run the rest of the playbooks.

```bash
$ ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/100-configure-arch-linux.yaml -kK
```

## Steam Deck

SteamOS comes pre-installed and pre-configured by default. To use the Steam Deck as a desktop, we need activate it.

```bash
$ ansible-playbook -i inventory.ini --vault-password-file .vault-password-file steam-deck/playbook.yaml -kK
```

And configure our personal settings.

```bash
$ ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/100-configure-arch-linux.yaml -kK
```
