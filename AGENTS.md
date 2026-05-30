# 🤖 Linee Guida per Agenti AI (AGENTS.md)

Questo documento fornisce le linee guida operative, le regole di sviluppo e il contesto architetturale per gli agenti AI (come Antigravity, GitHub Copilot, o altri modelli linguistici) che lavorano su questo repository.

---

## 📌 Panoramica del Sistema

Questo progetto è un'infrastruttura per smart home basata su Docker, organizzata in **stack logici ed isolati**. 

### Principi Chiave
1. **Configurazione Centralizzata**: Tutti gli stack risiedono nella cartella `stacks/` e sono gestiti in modo indipendente tramite `docker-compose.yml`.
2. **Stato Centralizzato (`runtime/`)**: I container non scrivono dati sparsi nel sistema host, ma fanno tutti riferimento alla directory `runtime/` tramite mount di volumi relativi (es. `${ROOT}/runtime/<servizio>`).
3. **Automazione ed Orchestrazione**: Tre script principali (`scripts/`) gestiscono il controllo dello stato, i backup e il ripristino/bootstrap dell'ambiente.

---

## 📂 Struttura del Progetto

```text
smarthome/
├── backup/                # Backup generati automaticamente (Ignorato da Git)
├── runtime/               # Stato a runtime dei container (Ignorato da Git)
├── scripts/               # Script di automazione
│   ├── runtime-backup.sh  # Backup di /runtime in backup/ con rotazione (max 5)
│   ├── runtime-control.sh # Gestione dei container (start/stop/restart/status)
│   └── runtime-restore.sh # Ripristino da backup o bootstrap da base_config
└── stacks/                # Configurazione dei Docker Compose stack
    ├── iot/               # Home Assistant, Mosquitto MQTT, Zigbee2MQTT
    ├── management/        # Dockge, Portainer
    ├── media/             # Jellyfin
    ├── monitoring/        # InfluxDB, Grafana
    └── proxy/             # Nginx Proxy Manager
```

---

## 🚦 Regole Operative per l'Agente AI

### 1. Gestione dei Servizi (Docker Compose)
* **NON** eseguire direttamente comandi generici `docker compose up` o `docker compose down` nella cartella degli stack a meno che non sia strettamente necessario per il debugging.
* Utilizza sempre lo script di controllo centralizzato:
  ```bash
  ./scripts/runtime-control.sh {start|stop|restart|status}
  ```
  *(Nota: sono accettati anche gli alias `up` e `down` al posto di `start` e `stop`)*.

### 2. Gestione dei Percorsi e Ambiente
* Tutti i percorsi nei file `docker-compose.yml` devono fare riferimento alla variabile `${ROOT}`, che mappa il percorso assoluto della cartella principale del progetto. **Non cablare mai percorsi assoluti dell'host**.
* Utilizza sempre la variabile di ambiente `${TZ}` per configurare il fuso orario all'interno dei container (default: `Europe/Rome`).

### 3. Modifica delle Configurazioni (Template `base_config` vs `runtime/`)
* **NON** modificare direttamente i file all'interno di `runtime/` per impostare configurazioni iniziali dei servizi. La cartella `runtime/` è volatile e viene ricreata o sovrascritta.
* **Procedura corretta**:
  1. Se devi aggiungere file di configurazione predefiniti per un nuovo stack o servizio, posizionali in `stacks/<nome-stack>/base_config/`.
  2. Lo script `runtime-restore.sh` si occuperà di copiarli ricorsivamente in `runtime/` durante il bootstrap iniziale (`cp -rn`).
  3. Se il sistema è già attivo e devi applicare una configurazione immediatamente, applica la modifica sia al file corrispondente sotto `runtime/` (ambiente attivo) sia in `base_config/` (per preservarla nei ripristini futuri).

### 4. Aggiunta di un Nuovo Stack Docker
Se ti viene richiesto di implementare un nuovo stack:
1. Crea una cartella dedicata in `stacks/<nuovo_stack>/`.
2. Crea il file `docker-compose.yml` (ed eventualmente `.env` per variabili specifiche).
3. Se lo stack richiede directory o file di configurazione iniziali, crea la struttura corrispondente in `stacks/<nuovo_stack>/base_config/` (ad esempio, `stacks/<nuovo_stack>/base_config/<servizio>/config.yaml`).
4. **Aggiorna gli script bash**: devi aggiungere il nome del nuovo stack all'array `STACKS` presente in:
   - [runtime-control.sh](file:///home/nicola/smarthome/scripts/runtime-control.sh)
5. **Documentazione**: Aggiorna il [README.md](file:///home/nicola/smarthome/README.md) per inserire i dettagli del nuovo stack nella tabella e aggiornare il diagramma Mermaid se necessario.

### 5. Ciclo di Backup e Ripristino
* Prima di effettuare modifiche strutturali o aggiornare i container, consiglia all'utente (o effettua autonomamente) un backup preventivo:
  ```bash
  ./scripts/runtime-backup.sh
  ```
* Se devi ripristinare il sistema allo stato del backup più recente:
  ```bash
  ./scripts/runtime-restore.sh
  ```
  *Nota: Questo script ferma i container, rinomina `runtime/` in `runtime_old_<timestamp>` per sicurezza, estrae il file `backup/latest.zip` e riavvia tutti i servizi.*

---

## 📝 Convenzioni degli Script
* Gli script devono iniziare con `#!/usr/bin/env bash` e impostare `set -euo pipefail`.
* Utilizza sempre percorsi assoluti derivati dinamicamente rispetto alla posizione dello script:
  ```bash
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  ```
* Assicurati che l'output degli script utilizzi emoji identificative ed evidenzi in modo chiaro i successi (✅), le avvertenze (⚠️), gli errori (❌) e i passaggi in corso (🚀, 🛑, 📦, 🗜️, 🚚).
