FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ADD dwagent.sh /dwagent.sh
ADD entrypoint.sh /entrypoint.sh
ADD chroot-host.sh /usr/local/bin/chroot-host.sh

RUN apt update && apt upgrade -y
RUN apt install -y wget curl sudo sshfs cifs-utils nano openssh-server && \
    apt autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -rm -d /home/ubuntu -s /bin/bash -u 1000 ubuntu

RUN mkdir /run/sshd
RUN service ssh start
RUN chmod +x /entrypoint.sh
RUN chmod 755 /entrypoint.sh

RUN cat > /usr/local/bin/chroot-host.sh << 'EOF' && \
    chmod +x /usr/local/bin/chroot-host.sh
#!/bin/bash
echo "=== AUTENTICAÇÃO PARA ACESSO AO HOST ==="
echo -n "Digite a senha de acesso ao host: "
read -s HOST_ACCESS_PASSWORD
echo

# Verificar senha (pode ser passada como ENV também)
if [ "${HOST_ACCESS_PASSWORD}" != "${HOST_PASSWORD:-defaulthostpass}" ]; then
    echo "❌ Senha incorreta!"
    exit 1
fi

echo "✅ Acesso autorizado!"
echo "=== ENTRANDO NO SISTEMA HOST ==="
echo "Use com responsabilidade!"
echo "======================================"
exec chroot /host /bin/bash
EOF

EXPOSE 22

CMD ["/usr/sbin/sshd","-D"]
ENTRYPOINT ["/entrypoint.sh"]
