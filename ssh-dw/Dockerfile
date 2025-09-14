FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ADD dwagent.sh /dwagent.sh
ADD entrypoint.sh /entrypoint.sh

RUN apt update && apt upgrade -y
RUN apt install -y wget curl sudo sshfs cifs-utils nano && \
    apt autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Criar usuário ubuntu e adicionar ao grupo sudo
RUN useradd -rm -d /home/ubuntu -s /bin/bash -u 1000 ubuntu && \
    usermod -aG sudo ubuntu

RUN chmod +x /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
