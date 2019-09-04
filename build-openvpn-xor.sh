#!/bin/bash

# compile using all cores
sed -i -E -e "s/^#?MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/" /etc/makepkg.conf

# allow 'nobody' to run sudo with no password
echo 'nobody ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# run makepkg as 'nobody' because root is not allowed to run makepkg
sudo -u nobody /bin/bash -c "$(cat <<EOF

git clone https://aur.archlinux.org/openvpn-xor-git /tmp/openvpn-xor-git
cd /tmp/openvpn-xor-git
makepkg -sir --noconfirm
cd /tmp
rm -rf openvpn-xor-git

EOF
)"

# revoke sudo priveleges for nobody
head -n -1 /etc/sudoers > sudoers-tmp
mv sudoers-tmp /etc/sudoers

rm /build-openvpn-xor.sh
