#!/bin/bash

NOMECONTAINER="ssh-dw"

docker_repo="urbancompasspony/ssh-dw:latest"
imagem="dwservice"

SECRET0=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)

CustmN2="local_ip"
CustmN3="password"
CustmN4=""
CustmN5=""
CustmN6=""
CustmN7=""
CustmN8=""
CustmN9=""
CustmN10=""

VALUE2="hostonly"
VALUE3="$SECRET0"
VALUE4=""
VALUE5=""
VALUE6=""
VALUE7=""
VALUE8=""
VALUE9=""
VALUE10=""

function set_mkdir {
  sudo mkdir -p /srv/containers/"$NOMECONTAINER"
  sudo chmod -R 777 /srv/containers/"$NOMECONTAINER"
}

function docker_create {
  local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

  # Se NAO for numerico, execute como host!
  if [[ ! "$VALUE2" =~ $ip_regex ]]; then

    docker run -d --privileged --name="$NOMECONTAINER" --hostname="$NOMECONTAINER" \
    --network host --add-host=host.docker.internal:host-gateway \
    --no-healthcheck --restart=unless-stopped -v /etc/localtime:/etc/localtime:ro \
    -e PUID=0 -e PGID=0 \
    -e UBUNTU_PASSWORD="$VALUE3" \
    -v /srv/containers/"$NOMECONTAINER"/data:/usr/share \
    -v /:/host \
    "$docker_repo"

    return
  fi

  echo "Este sistema não admite executar com IP pré estabelecido."
  echo "Execute diretamente como hostonly!"
  echo "Saindo..."
  sleep 5
  exit 1
}

function docker_extras {
  # Aguardar o container estar rodando
  echo "Aguardando container inicializar..."
  sleep 3
  echo "✅ Container inicializado com sucesso!"
}

# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------

masterfile="/srv/system.yaml"
configfile="/srv/containers.yaml"
button_ok0="Criar"

labels=("nome_custom" "$CustmN2" "$CustmN3" "$CustmN4" "$CustmN5" "$CustmN6" "$CustmN7" "$CustmN8" "$CustmN9" "$CustmN10")

values=("$NOMECONTAINER" "$VALUE2" "$VALUE3" "$VALUE4" "$VALUE5" "$VALUE6" "$VALUE7" "$VALUE8" "$VALUE9" "$VALUE10")

function check_root {
  [ "$EUID" -ne 0 ] && {
    echo "Execute esse script como Root! Saindo..."
    exit 1
  }
}

function check_macvlan {
  if ! docker inspect macvlan 1>/dev/null 2>/dev/null; then
    echo "A macvlan não existe! Saindo..."; sleep 3
    exit 0
  fi
}

function try_pull {
  if ! docker pull "$docker_repo"; then
    echo "Erro: docker pull falhou... saindo."; sleep 3
    exit 1
  fi
}

function lockfile0 {
  if [ -f /srv/lockfile ]; then
    if ! [ -f "$configfile" ]; then
      echo ""; echo "ERRO CRITICO: NAO ENCONTREI O $configfile DESTE CONTAINER! Saindo."; sleep 5
      exit 1
    else
      yq -r "to_entries[] | select(.value.img_base | test(\"$imagem\")) | .key" "$configfile" | while read -r container; do
        process_container "$container"
      done
    fi
  else
    main_menu
  fi
}

function process_container {
  local container="$1"

  for i in "${!labels[@]}"; do
    val="$(yq -r '.["'"$container"'"].["'"${labels[$i]}"'"]' "$configfile")"
    if [[ "$val" == "null" || -z "$val" ]]; then
      eval "VALUE$((i+1))=\"\""
      values[i]=""
    else
      eval "VALUE$((i+1))=\"$val\""
      values[i]="$val"
    fi
  done

  NOMECONTAINER="$container"
  signal0
  set_mkdir
  try_pull
  docker_create
  docker_extras
  save_config
}

function load_data {
  if ! [ -f "$configfile" ]; then
    return
  fi

  if [ "$(grep -c -w "$imagem" "$configfile")" -gt 1 ]; then
    LISTANOMES=$(yq -r 'to_entries[] | select(.value.img_base == "'"$imagem"'") | .value.nome_custom' "$configfile")
    NOMECONTAINER=$(dialog --title "Imagem detectada: $imagem" --backtitle "W A R N I N G" --ok-button "Carregar" --no-cancel --inputbox "Encontrei um ou mais de um container registrado com essa imagem! Qual deseja carregar?\nValores encontrados:\n$LISTANOMES" 0 0 "" 2>&1 > /dev/tty)
  fi

  for i in "${!labels[@]}"; do
    val="$(yq -r '.["'"$NOMECONTAINER"'"].["'"${labels[$i]}"'"]' "$configfile")"
    if [[ "$val" == "null" || -z "$val" ]]; then
      eval "VALUE$((i+1))=\"${values[$i]}\""
      values[i]="${values[$i]}"
    else
      eval "VALUE$((i+1))=\"$val\""
      values[i]="$val"
    fi
  done

  if ! [ "$NOMECONTAINER" = "" ]; then
    button_ok0="Recriar"
  fi
}

function save_config {
  sudo touch "$configfile"

  datetime0=$(date +"%d-%m-%Y_%H:%M")
  sudo yq -i ".\"${NOMECONTAINER}\".instalacao = \"${datetime0}\"" "$configfile"
  sudo yq -i ".\"${NOMECONTAINER}\".img_base = \"${imagem}\"" "$configfile"

  for i in "${!labels[@]}"; do
    sudo yq -i ".\"${NOMECONTAINER}\".\"${labels[$i]}\" = \"${values[$i]}\"" "$configfile"
  done
}

function main_menu {
  load_data

  form_args=()
  for idx in "${!labels[@]}"; do
    line=$((idx+1))
    form_args+=("${labels[$idx]}:" "$line" 1 "${values[$idx]}" "$line" 17 150 0)
  done

  if ! form=$(dialog --ok-label "$button_ok0" --title "Novo Container" --form "Imagem Base: $imagem" 17 80 0 \
    "${form_args[@]}" 3>&1 1>&2 2>&3 3>&- > /dev/tty); then
    return
  fi

  mapfile -t VALUES <<< "$form"
  for i in {1..10}; do
    eval "VALUE$i=\"\${VALUES[$((i-1))]}\""
    values[i-1]="${VALUES[$((i-1))]}"
  done

  NOMECONTAINER="${VALUES[0]}"

  check_IP
}

function check_IP {
  local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

  # Se NAO for numerico, ignore a verificacao.
  if [[ ! "$VALUE2" =~ $ip_regex ]]; then
    save_config
    mkdir0
    try_pull
    docker_create
    docker_extras
    cleanup0
    return
  fi

  # Valor numerico exemplo 192.168.0.1? Verifique!
  if ip_conflict_check "$VALUE2" "$NOMECONTAINER" "$configfile"; then
    dialog --title "ERRO" --msgbox "Conflito de IP detectado no $configfile:\nMesmo IP de outro container!" 7 40
    main_menu
  elif grep -wq "$VALUE2" "$masterfile"; then
    dialog --title "ERRO" --msgbox "Conflito de IP detectado no $masterfile:\nMesmo IP do host!" 7 40
    main_menu
  else
    save_config
    mkdir0
    try_pull
    docker_create
    docker_extras
    cleanup0
  fi
}

function ip_conflict_check {
  local ip="$1"; local mycontainer="$2"; local configfile="$3"
  yq 'to_entries | map(select(.key != "'"$mycontainer"'")) | .[].value.local_ip' "$configfile" | grep -wq "$ip"
}

function mkdir0 {
  if [ -d "/srv/containers/$NOMECONTAINER" ]; then
    if ! dialog --title "WARNING" --yes-label "Prosseguir" --no-label "CANCELAR" --yesno "Foram identificados dados de volumes! \n\nParando e removendo container caso esteja rodando. \n\nSe precisar, apague o conteudo de /srv/containers/$NOMECONTAINER manualmente" 14 50; then
      exit 0
    fi
    signal0
  fi
  signal0
  set_mkdir
}

function signal0 {
  if [ -d /srv/containers/"$NOMECONTAINER" ]; then
    if docker stop "$NOMECONTAINER"; then
      docker rm "$NOMECONTAINER"
      clear; echo "SIGTERM + STOP + CLEAN: O container $NOMECONTAINER estava executando, foi parado e removido. Continuando..."; sleep 3
      return
    elif docker rm "$NOMECONTAINER"; then
      clear; echo "STOP + CLEAN: O container $NOMECONTAINER estava parado e foi removido. Continuando..."; sleep 3
      return
    else
      clear; echo "CLEAN: O container $NOMECONTAINER nao estava executando. Continuando..."; sleep 3
    fi

    return
  fi

  if docker rm -f "$NOMECONTAINER"; then
    clear; echo "SIGKILL + RM: O container $NOMECONTAINER estava executando SEM VOLUME! Foi morto e removido. Continuando..."; sleep 3
  fi
}

function cleanup0 {
  for i in {1..10}; do
    unset "VALUE$i"
  done

  for i in {1..10}; do
    unset "CustmN$i"
  done

  echo ""; echo "Limpando imagens desnecessarias..."
  docker image prune -af
  sleep 1
}

check_root
check_macvlan
lockfile0

exit 0
