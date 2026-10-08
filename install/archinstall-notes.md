# Arch install

## Setup

```text
Boot     systemd-boot + UKI, PRESETS=('default')
FS       ext4, ESP 1G на /boot, fmask/dmask 0077
Swap     zram ram/2 zstd pri 100 + swapfile, zswap.enabled=0
Ядра     linux + linux-lts
CPU      amd-ucode | intel-ucode
GPU      nvidia-open-dkms, early KMS, без хука kms
Сеть     NetworkManager
Locale   en_US.UTF-8 + ru_RU.UTF-8, KEYMAP=us
User     zsh, wheel, sudoers.d
```

- UKI: без entries, microcode встроен, пересобирается хуком mkinitcpio.
- DKMS, а не prebuilt: упала сборка под новое ядро → lts живёт, `-Syu` не блокируется.
- Early KMS: greetd стартует раньше модуля. Hibernation не нужна.
- modeset/fbdev включены в nvidia-utils по умолчанию.
- NVIDIA в pacstrap: один `mkinitcpio -P` в chroot.
- Обновление драйвера пересобирает UKI само: dkms-хук идёт перед mkinitcpio-хуком.
- zswap выключен, иначе перехватывает страницы перед zram.
- `arch-chroot -S`: bootctl пишет NVRAM.

## 1. Live ISO

```bash
ls /sys/firmware/efi/efivars
iwctl                                 # station wlan0 connect "SSID"
timedatectl set-ntp true
lsblk -o NAME,SIZE,MODEL              # диск по MODEL, нумерация плавает

DISK=/dev/nvmeXn1
ESP=${DISK}p1                         # sdX: ${DISK}1
ROOT=${DISK}p2
```

## 2. Разметка

```bash
cfdisk $DISK
```

1. `Delete` все старые разделы.
2. `New` → `1G`, `Type` → `EFI System`.
3. `New` → остаток, `Type` → `Linux root (x86-64)`. Это 8304;
   `Linux filesystem` (8300) тоже сработает, root задаётся через UUID.
4. `Write` → `yes` → `Quit`.

```bash
mkfs.fat -F32 -n EFI $ESP
mkfs.ext4 -L arch $ROOT
mount $ROOT /mnt
mount --mkdir $ESP /mnt/boot
```

Неинтерактивно, если `$DISK` точно верный:

```bash
sgdisk --zap-all $DISK
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI -n2:0:0 -t2:8304 -c2:arch $DISK
```

## 3. pacstrap

```bash
pacstrap -K /mnt \
  base linux linux-headers linux-lts linux-lts-headers linux-firmware amd-ucode \
  nvidia-open-dkms nvidia-utils \
  networkmanager sudo git vim zsh man-db man-pages efibootmgr zram-generator

genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's/fmask=0022,dmask=0022/fmask=0077,dmask=0077/' /mnt/etc/fstab
arch-chroot -S /mnt
```

## 4. chroot

```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

sed -i 's/^#\(en_US.UTF-8\)/\1/; s/^#\(ru_RU.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf

echo HOSTNAME > /etc/hostname
printf '127.0.0.1 localhost\n::1 localhost\n127.0.1.1 HOSTNAME.localdomain HOSTNAME\n' > /etc/hosts

printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\nswap-priority = 100\n' \
  > /etc/systemd/zram-generator.conf
mkswap -U clear --size 32G --file /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

cat /etc/hostname /etc/hosts; tail -n 3 /etc/fstab

passwd
useradd -m -G wheel -s /usr/bin/zsh USER
passwd USER
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel
visudo -c
```

## 5. NVIDIA в initramfs

```bash
sed -i '/^MODULES=/s/()/(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
sed -i '/^HOOKS=/s/ kms//' /etc/mkinitcpio.conf
grep -E '^(MODULES|HOOKS)=' /etc/mkinitcpio.conf
```

## 6. UKI + systemd-boot

```bash
echo "root=UUID=$(blkid -s UUID -o value "$(blkid -L arch)") rw quiet zswap.enabled=0" > /etc/kernel/cmdline
cat /etc/kernel/cmdline

sed -i \
  -e 's/^default_image/#default_image/' \
  -e 's|^#default_uki="/efi/|default_uki="/boot/|' \
  /etc/mkinitcpio.d/*.preset

bootctl install
cat > /boot/loader/loader.conf <<'EOF'
default arch-linux.efi
timeout 3
console-mode keep
EOF

mkinitcpio -P
rm -f /boot/initramfs-*.img
bootctl list
```

## 7. Выход

```bash
systemctl enable NetworkManager systemd-timesyncd systemd-boot-update
exit
efibootmgr                            # Linux Boot Manager; лишнее: efibootmgr -b XXXX -B
umount -R /mnt
reboot
```

Если записи нет:

```bash
efibootmgr --create --disk $DISK --part 1 \
  --loader '\EFI\systemd\systemd-bootx64.efi' --label "Linux Boot Manager" --unicode
```

## 8. Первая загрузка

```bash
nmcli device wifi connect "SSID" password "PASS"
nvidia-smi
swapon --show                         # zram0 100, /swapfile -2

git clone https://github.com/wordyarc/arch-dotfiles.git ~/ProjectsVault/arch-dotfiles
cd ~/ProjectsVault/arch-dotfiles && ./bootstrap.sh
reboot
```

## После

- Windows рядом: `reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f`
- Первое обновление nvidia-open-dkms: после `Install DKMS modules` должно идти `Updating linux initcpios`.
- Suspend сломан → `nvidia-suspend.service`, `nvidia-resume.service`.
- Steam/Wine → multilib, `lib32-nvidia-utils`.
- VA-API → `libva-nvidia-driver`, `NVD_BACKEND` в hyprland.lua.

