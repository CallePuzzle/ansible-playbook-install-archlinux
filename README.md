# ansible-playbook-install-archlinux

## Install USB

``` bash
dd if=image.iso of=/dev/sdb bs=4M
```

## Base installation

``` bash
root@archiso# systemctl start sshd
root@archiso# passwd
```

```bash
$ ansible-playbook -i monom.ini --vault-password-file .vault-password-file 000-platform-base.yaml -k
$ ansible-playbook -i monom.ini --vault-password-file .vault-password-file -k 010-configure-chroot-env.yaml
```

```bash
root@archiso# arch-chroot /mnt
root@archiso# passwd
root@archiso# exit
root@archiso# reboot
```

## Configuration / provision

* Allow ssh root login `# vim /etc/ssh/sshd_config`
* Start sshd

```bash
$ ansible-playbook -i monom.ini --vault-password-file .vault-password-file -k provision/000-base.yaml
$ ansible-playbook -i monom.ini --vault-password-file .vault-password-file -k 010-configure-chroot-env.yaml
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
