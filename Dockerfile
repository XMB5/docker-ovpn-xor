FROM archlinux/base:latest
EXPOSE 1194/tcp
RUN ["pacman", "-Sy", "--needed", "--noconfirm", "base-devel", "git", "easy-rsa"]
COPY ./build-openvpn-xor.sh /
RUN ["/build-openvpn-xor.sh"]
COPY ./start.sh /
ENTRYPOINT ["/start.sh"]