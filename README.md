# ansible-playbook-install-archlinux

```bash
$ ansible-playbook -i inventory.ini --vault-password-file .vault-password-file installation-base.yaml
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
