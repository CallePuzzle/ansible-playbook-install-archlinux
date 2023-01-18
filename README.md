# Ansible Playbook install Arch Linux

Ansible playbook to install Arch Linux on a laptop and configure Steam Deck in desktop mode.

## Laptop

Download the latest Arch Linux ISO and write it to a USB stick.

``` bash
dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/sdx conv=fsync oflag=direct status=progress
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

The first one needs access by root.
* Allow ssh root login `# vim /etc/ssh/sshd_config`
* Start sshd

```bash
$ ansible-playbook -i laptop/inventory.ini --vault-password-file .vault-password-file archlinux/000-base.yaml -k
```

Now, we can remove the access given in the previous step. And run the rest of the playbooks.

```bash
$ ansible-playbook -i laptop/inventory.ini --vault-password-file .vault-password-file archlinux/100-configure-arch-linux.yaml -kK
```

## Steam Deck

SteamOS comes pre-installed and pre-configured by default. To use the Steam Deck as a desktop, we need activate it.

```bash
$ ansible-playbook -i steam-deck/inventory.ini --vault-password-file .vault-password-file steam-deck/playbook.yaml -kK
```

And configure our personal settings.

```bash
$ ansible-playbook -i laptop/inventory.ini --vault-password-file .vault-password-file archlinux/100-configure-arch-linux.yaml -kK
```

## TODO

```
    2  mkdir aur
    3  cd aur/
    4  git
    5  git clone https://aur.archlinux.org/pikaur.git
    6  cd pikaur/
    7  makepkg -fsri
    8  sudo pacman -S pyalpm
    9  sudo pacman -S pyalpm
   10  makepkg -fsri
   11  pikaur -S google-chrome --noconfirm
   12  pikaur -S spotify --noconfirma
   13  pikaur -S spotify --noconfirm
   14  gpg --recv-keys 4773BD5E130D1D45
   15  pikaur -S spotify --noconfirm
```


https://github.com/kewlfft/ansible-aur
