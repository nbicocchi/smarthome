# Home Infrastructure Setup (Docker Stacks)

This document describes the minimal steps required to initialize and run the full Docker-based home infrastructure.

---

## 1. Create the MQTT Network

Create the shared Docker network used by MQTT and related services:

```bash
docker network create mqtt-net
```

---

## 2. Distribute Environment File

Copy the shared `.env` file into all stack directories:

```text
scripts/.env → each stack folder
```

Example:

```bash
cp scripts/.env stacks/*/
```

---

## 3. Initialize Stack Directories

Start all Docker stacks once to:

* create required runtime directories
* initialize volumes
* apply correct `USER:GROUP` permissions defined in `.env`

```bash
docker compose up -d
```

Run this inside each stack directory.

---

## 4. Configure Shared Storage

Create a symbolic link from the project's local `media` directory to the physical storage location used by services such as Jellyfin, Frigate, and other media-related applications.

Example:

```bash
ln -s /mnt/storage/media media
```

Result:

```text
project/
├── media -> /mnt/storage/media
├── stacks/
└── scripts/
```

This allows all containers to access the same persistent media storage while keeping the project structure clean and portable.

---

## 5. Copy Base Configuration

Copy base configuration files into the runtime directory:

```text
base_config → runtime/
```

Example:

```bash
cp -r base_config/* runtime/
```

---

## 6. Start the Infrastructure

Once the configuration has been copied and storage has been configured, start all stacks:

```bash
docker compose up -d
```

Verify that all services are running correctly before proceeding with further configuration.
