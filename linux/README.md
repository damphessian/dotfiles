## Fonts
```
mkdir ~/.local/share/fonts
cp -r ~/Dropbox/fonts/**/* ~/.local/share/fonts
fc-cache -fv
```

## Toshy

https://github.com/RedBearAK/toshy

```
bash -c "$(curl -L https://raw.githubusercontent.com/RedBearAK/toshy/main/scripts/bootstrap.sh ||
 wget -O - https://raw.githubusercontent.com/RedBearAK/toshy/main/scripts/bootstrap.sh)"
```

### Merge config and data home dirs

1. Remove versioned toshy config
2. Copy data dir contents to dotfiles subdirectory
3. Link to dotfiles subdirectory
4. Back up upstream toshy config
5. Stage updated toshy config
6. Copy customized toshy config to overwrite
7. Pick-and-patch from the unstaged changes diff
8. Commit updates

```
mv ~/.config/* $XDG_CONFIG_HOME
ln -s $XDG_CONFIG_HOME ~/.config

mv ~/.local/share/* $XDG_DATA_HOME
ln -s $XDG_DATA_HOME ~/.local/share
```

## Set keyboard delay and repeat interval

Accessibility > Keyboard

## Keybinding config

### Load

```
dconf load /org/gnome/ < gnome-keybindings-backup.conf
```

### Save

```
dconf dump /org/gnome/ > gnome-keybindings-backup.conf
```

### Disable standalone super key

#### Ubuntu

```sh
gsettings get org.gnome.shell.keybindings toggle-overview
# @as []
```

```sh
gsettings get org.gnome.mutter overlay-key
 # ''
```

```
gsettings set org.gnome.shell.keybindings toggle-overview "[]"
gsettings set org.gnome.mutter overlay-key ''
```

```
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false
for i in {1..9}; do
  gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
done
```

## Deprecated Installs

### CUDA Toolkit
```
sudo ubuntu-drivers autoinstall
sudo apt install nvidia-cuda-toolkit
```

### PopOS

Locate and edit the COSMIC extension's main JavaScript file, often named
`extension.js`.

The path is likely

```
/usr/share/gnome-shell/extensions/pop-cosmic@system76.com/extension.js
```

Search for this line and comment it out:

``` javascript
overview_toggle(overlay_key_action);
```

### TeX

May take several hours to complete:
https://www.tug.org/texlive/quickinstall.html

```
wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

zcat < install-tl-unx.tar.gz | tar xf -

sudo ./install-tl --no-interaction --paper=letter --no-doc-install --no-src-install
sudo ln -s /usr/local/texlive/[YYYY] /usr/local/texlive/current
```

### input-remapper-2

https://github.com/sezanzeb/input-remapper
```
wget https://github.com/sezanzeb/input-remapper/releases/download/2.1.1/input-remapper-2.1.1.deb
sudo apt install -f ./input-remapper-2.1.1.deb
```

### Ulauncher

https://ulauncher.io

```
sudo add-apt-repository universe -y
sudo add-apt-repository ppa:agornostal/ulauncher -y
sudo apt update
sudo apt install ulauncher
```

### Kitty
```
~/.dotfiles/lib/install-kitty
```
