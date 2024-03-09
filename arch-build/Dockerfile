FROM archlinux:latest

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN date
RUN \
    pacman-key --init
    pacman -Syu --noconfirm base-devel
    useradd builder -m
    echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

    cat <<EOM >>/etc/pacman.conf
    [multilib]
    Include = /etc/pacman.d/mirrorlist
    EOM
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
