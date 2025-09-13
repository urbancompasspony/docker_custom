#!/bin/bash
echo "=== ACESSO AO SISTEMA HOST ==="
echo "Você está entrando no sistema host via chroot."
echo "Use com responsabilidade!"
echo "======================================"
exec chroot /host /bin/bash
