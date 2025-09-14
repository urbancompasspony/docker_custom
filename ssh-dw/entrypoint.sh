#!/bin/bash

# Garantir que estamos executando como root para configurações iniciais
if [ "$(id -u)" != "0" ]; then
    echo "Entrypoint deve ser executado como root inicialmente"
    exit 1
fi

# Configurar senha do usuário ubuntu usando variável de ambiente
UBUNTU_PASSWORD=${UBUNTU_PASSWORD:-"ubuntu"}

echo "ubuntu:${UBUNTU_PASSWORD}" | chpasswd

# Garantir que o usuário ubuntu existe e tem as permissões corretas
if ! id -u ubuntu > /dev/null 2>&1; then
    useradd -rm -d /home/ubuntu -s /bin/bash -u 1000 ubuntu
fi

# Adicionar ubuntu ao grupo sudo se não estiver
usermod -aG sudo ubuntu

# Configurar sudoers para que ubuntu possa usar sudo
echo "ubuntu ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/ubuntu
chmod 440 /etc/sudoers.d/ubuntu

# Criar alias útil para chroot com bash interativo
echo 'alias chroot-host="chroot /host /bin/bash -l"' >> /root/.bashrc
echo 'alias chroot-host="chroot /host /bin/bash -l"' >> /home/ubuntu/.bashrc

# Adicionar mensagem de boas-vindas ao .bashrc do ubuntu
cat >> /home/ubuntu/.bashrc << 'EOF'

# === SSH-DW Container ===
echo "┌──────────────────────────────────────┐"
echo "│        🐳 SSH-DW Container           │"
echo "├──────────────────────────────────────┤"
echo "│ sudo -i       → Virar root           │"
echo "└──────────────────────────────────────┘"
EOF

# Adicionar mensagem de boas-vindas ao .bashrc do root
cat >> /root/.bashrc << 'EOF'

# === SSH-DW Container (ROOT) ===
echo "┌──────────────────────────────────────┐"
echo "│      🔧 SSH-DW Container (ROOT)      │"
echo "├──────────────────────────────────────┤"
echo "│ chroot-host   → Acessar host         │"
echo "└──────────────────────────────────────┘"
EOF

# DWService (executar como root)
/bin/sh /usr/share/dwagent/native/dwagsvc run &
sleep 10
/bin/sh /usr/share/dwagent/native/dwagsvc run &

# Mudar para usuário ubuntu e manter container rodando
exec su - ubuntu -c "tail -f /dev/null"
