# Smart Home Docker Stack

A Docker-based smart home stack, designed as an alternative to Home Assistant OS.

This is a **personal project** built for my own smart home. It is shared as a reference, not as a turnkey solution: configuration choices reflect my setup and may need adapting to yours.

Run **Debian + Docker** to host Home Assistant and supporting services in containers, without dedicating the entire machine to Home Assistant OS.

Keep control of your operating system, manage services independently, and use the same machine for other applications.

## Included services

Each service has its own `compose.yaml` under [`stacks/`](stacks/).

| Service | Purpose |
| --- | --- |
| Home Assistant | Smart home management and automation |
| Mosquitto | MQTT messaging between devices and services |
| Zigbee2MQTT | Zigbee device integration over MQTT |
| Frigate | Video surveillance and camera management |
| tlapse | Timelapse recording from RTSP streams |
| InfluxDB | Time-series data storage |
| Grafana | Dashboards and data visualization |
| Beszel | Host and container monitoring |
| Portainer | Web-based Docker management |

## Repository layout

- [`stacks/`](stacks/) — Docker Compose definitions for individual services.
- `runtime/` — Local configuration and persistent data, excluded from Git.
- [`scripts/`](scripts/) — Stack backup and daily timelapse merging utilities.

## Getting started

1. Install Debian, Docker Engine, and the Docker Compose plugin.
2. Configure the services for your setup: update IP addresses, credentials, storage paths, and hardware devices. Application configuration files are not included in this repository.
3. Create the shared external network once:

```bash
docker network create mqtt-net
```

4. Start the services you need from the repository root. For example:

```bash
docker compose -f stacks/homeassistant/compose.yaml up -d
```

## Notes

> [!NOTE]
> This stack does not include the Home Assistant Supervisor. Container management, updates, and backups are your responsibility.

> [!WARNING]
> Adapt the scripts to your local paths and users before running them. The backup script temporarily stops **all running containers on the host**, not just those in this repository.
