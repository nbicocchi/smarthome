#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# CONFIGURAZIONE
# ==========================================

SOURCE="/home/nicola/smarthome"
DEST="/srv/media/smarthome"
ARCHIVE="/srv/media/smarthome-backup.tar.gz"

TEMP_ARCHIVE=""
CONTAINERS_STOPPED=false

# ==========================================
# LOCK - EVITA BACKUP CONTEMPORANEI
# ==========================================

exec 9>/run/smarthome-backup.lock

flock -n 9 || {
    echo "ERRORE: un backup è già in esecuzione"
    exit 1
}

# ==========================================
# CONTROLLI PRELIMINARI
# ==========================================

[[ -d "$SOURCE" ]] || {
    echo "ERRORE: directory sorgente non trovata"
    exit 1
}

[[ -d /srv/media ]] || {
    echo "ERRORE: directory /srv/media non trovata"
    exit 1
}

command -v docker >/dev/null
command -v rsync >/dev/null
command -v tar >/dev/null

# Se /srv/media è un filesystem montato
# abilita questa verifica:
#
# mountpoint -q /srv/media || exit 1

# ==========================================
# CONTAINER ATTUALMENTE ATTIVI
# ==========================================

mapfile -t RUNNING_CONTAINERS < <(
    docker ps -q --no-trunc
)

echo "Container attivi: ${#RUNNING_CONTAINERS[@]}"

# ==========================================
# FUNZIONE RIAVVIO CONTAINER
# ==========================================

restart_containers() {

    if [[ "$CONTAINERS_STOPPED" != true ]]; then
        return 0
    fi

    echo "Riavvio dei container Docker..."

    local result=0

    if (( ${#RUNNING_CONTAINERS[@]} > 0 )); then
        docker start "${RUNNING_CONTAINERS[@]}" || result=1
    fi

    if (( result == 0 )); then
        CONTAINERS_STOPPED=false
        echo "Container riavviati correttamente"
    else
        echo "ERRORE: alcuni container non sono ripartiti"
        return 1
    fi
}

# ==========================================
# CLEANUP AUTOMATICO
# ==========================================

cleanup() {

    local exit_code=$?

    trap - EXIT INT TERM
    set +e

    # Elimina l'archivio temporaneo
    if [[ -n "$TEMP_ARCHIVE" ]]; then
        rm -f "$TEMP_ARCHIVE"
    fi

    # Riavvia i container in caso di errore
    if [[ "$CONTAINERS_STOPPED" == true ]]; then
        restart_containers || exit_code=1
    fi

    exit "$exit_code"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# ==========================================
# AVVIO BACKUP
# ==========================================

echo "=========================================="
echo " Avvio backup smarthome"
echo " Data: $(date)"
echo "=========================================="

# ==========================================
# 1. ARRESTO CONTAINER
# ==========================================

if (( ${#RUNNING_CONTAINERS[@]} > 0 )); then

    echo "Arresto dei container Docker..."

    # Imposta il flag prima del tentativo,
    # così il cleanup interviene anche
    # in caso di arresto parziale.
    CONTAINERS_STOPPED=true

    docker stop --timeout 60 "${RUNNING_CONTAINERS[@]}"

fi

# ==========================================
# 2. BACKUP RSYNC
# ==========================================

echo "Sincronizzazione con rsync..."

mkdir -p "$DEST"

rsync -a --delete \
    --exclude='/runtime/frigate/media/' \
    "$SOURCE/" "$DEST/"

echo "Sincronizzazione completata"

# ==========================================
# 3. RIAVVIO IMMEDIATO CONTAINER
# ==========================================

restart_containers

# ==========================================
# 4. CREAZIONE ARCHIVIO
# ==========================================

echo "Creazione archivio compresso..."

TEMP_ARCHIVE=$(mktemp "${ARCHIVE}.tmp.XXXXXX")

tar -czf "$TEMP_ARCHIVE" \
    -C /srv/media smarthome

# ==========================================
# 5. VERIFICA ARCHIVIO
# ==========================================

echo "Verifica integrità archivio..."

tar -tzf "$TEMP_ARCHIVE" > /dev/null

# ==========================================
# 6. PERMESSI
# ==========================================

chown nicola:nicola "$TEMP_ARCHIVE"
chmod 600 "$TEMP_ARCHIVE"

# ==========================================
# 7. SOSTITUZIONE ATOMICA ARCHIVIO
# ==========================================

mv -f "$TEMP_ARCHIVE" "$ARCHIVE"
TEMP_ARCHIVE=""

# ==========================================
# COMPLETAMENTO
# ==========================================

echo "=========================================="
echo " Backup completato correttamente"
echo " Archivio: $ARCHIVE"
echo " Dimensione: $(du -h "$ARCHIVE" | cut -f1)"
echo " Data: $(date)"
echo "=========================================="
