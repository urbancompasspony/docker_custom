#!/bin/bash

# Configurar senhas usando variáveis de ambiente (com valores padrão seguros)
ROOT_PASSWORD=${ROOT_PASSWORD:-"containerroot"}
UBUNTU_PASSWORD=${UBUNTU_PASSWORD:-"ubuntu"}

echo "root:${ROOT_PASSWORD}" | chpasswd
echo "ubuntu:${UBUNTU_PASSWORD}" | chpasswd

# Garantir que o usuário ubuntu existe e tem as permissões corretas
if ! id -u ubuntu > /dev/null 2>&1; then
    useradd -rm -d /home/ubuntu -s /bin/bash -u 1000 ubuntu
fi

# Exibir informações de acesso
echo "======================================"
echo "CONTAINER INICIADO - USUÁRIO: ubuntu"
echo "Para acessar o host:"
echo "$ chroot /host"
echo "======================================"

# DWService
/bin/sh /usr/share/dwagent/native/dwagsvc run &
sleep 10
/bin/sh /usr/share/dwagent/native/dwagsvc run &

# Mudar para usuário ubuntu antes de manter o container rodando
exec su - ubuntu -c "tail -f /dev/null"
