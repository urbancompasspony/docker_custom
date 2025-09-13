#!/bin/bash
ROOT_PASSWORD=${ROOT_PASSWORD:-"containerroot$(date +%s)"}
UBUNTU_PASSWORD=${UBUNTU_PASSWORD:-"ubuntu"}

echo "root:${ROOT_PASSWORD}" | chpasswd
echo "ubuntu:${UBUNTU_PASSWORD}" | chpasswd

echo "======================================"
echo "CONTAINER INICIADO - ACESSO AO HOST DISPONÍVEL"
echo "Para acessar o host: sudo /usr/local/bin/chroot-host.sh"
echo "======================================"

/bin/sh /usr/share/dwagent/native/dwagsvc run &
sleep 10
/bin/sh /usr/share/dwagent/native/dwagsvc run &

# Keep container running!
tail -f /dev/null
