# Smart Home Infrastructure Setup

This repository contains modular Docker Compose stacks for setting up and managing a self-hosted Smart Home infrastructure.

---

## 🛠 Included Stacks

| Service | Port(s) | Description |
| :--- | :--- | :--- |
| **[Home Assistant](stacks/homeassistant)** | `8123` | Central home automation & orchestration platform |
| **[Mosquitto](stacks/mosquitto)** | `1883`, `9001` | MQTT message broker for IoT communication |
| **[Zigbee2MQTT](stacks/zigbee2mqtt)** | `8080` | Zigbee bridge translating Zigbee device traffic to MQTT |
| **[Frigate](stacks/frigate)** | `5000`, `1935`, `8554` | NVR with AI object detection for IP security cameras |
| **[InfluxDB](stacks/influxdb)** | `8086` | Time-series database for historical metrics and sensor data |
| **[Grafana](stacks/grafana)** | `3000` | Analytics dashboards and metrics visualization |
| **[Dockge](stacks/dockge)** | `5001` | Web-based docker compose stack management UI |

---

## 📁 Repository Structure

```text
.
├── stacks/
│   ├── dockge/          # Docker stack management UI
│   ├── frigate/         # Camera NVR & AI object detection
│   ├── grafana/         # Metrics dashboards
│   ├── homeassistant/   # Home Assistant core server
│   ├── influxdb/        # Time-series database
│   ├── mosquitto/       # MQTT broker
│   └── zigbee2mqtt/     # Zigbee bridge
├── .gitignore           # Ignores runtime state, logs, and backups
└── README.md
```

Each stack directory contains:
- `docker-compose.yml`: Container service definition
- `.env`: Environment variables (`ROOT`, `TZ`, `USER`, `GROUP`)
- `base_config/`: Initial default configurations for service startup

---

## 🚀 Getting Started

### 1. Prerequisites
Ensure **Docker** and **Docker Compose** (v2+) are installed on your host system.

### 2. Network Setup
The stacks communicate over a shared external Docker network named `mqtt-net`. Create it before launching services:

```bash
docker network create mqtt-net
```

### 3. Environment Configuration
Each stack reads environment variables from its `.env` file:

```env
ROOT=/path/to/smarthome
TZ=Europe/Rome
USER=1000
GROUP=1000
```

*Update `ROOT` to point to the base path of your installation.*

### 4. Running a Stack
To launch an individual stack, navigate to its folder inside `stacks/` and run:

```bash
docker compose up -d
```

Alternatively, you can deploy and manage all stacks visually via **Dockge** on `http://<host-ip>:5001`.

---

## 🔒 Runtime Data & Security
Runtime data, database state, and media recordings are stored in `${ROOT}/runtime/` and are excluded from Git version control via `.gitignore`. Sensitive files such as passwds and logs are also ignored.
