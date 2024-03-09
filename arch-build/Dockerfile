FROM archlinux:latest

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN date
RUN pacman-key --init
RUN pacman -Syu --noconfirm base-devel
RUN useradd builder -m
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
