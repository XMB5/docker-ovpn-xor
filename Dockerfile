FROM archlinux/base:latest
EXPOSE 1194/tcp
# update all packages because if some libraries are outdated,
# programs that expect the newest version of the library might not work
RUN ["pacman", "-Syu", "--needed", "--noconfirm", "base-devel", "git", "easy-rsa"]
COPY ./build-openvpn-xor.sh /
RUN ["/build-openvpn-xor.sh"]
RUN ["/bin/bash", "-c", "pacman -Rns --noconfirm git && rm -rf /var/lib/pacman/*"]
COPY ./start.sh /
ENTRYPOINT ["/start.sh"]