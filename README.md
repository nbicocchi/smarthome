
# Home Infrastructure Setup (Docker Stacks)

This document describes the minimal steps required to initialize and run the full Docker-based home infrastructure.

---

## 1. Initial Setup (Recommended)

Most of the initial configuration is automated via the provided setup script.

```bash
./scripts/runtime-setup.sh
```

> If you use the script, you can safely skip steps 2 and part of step 3 unless manual customization is needed.

---

## 2. Create the MQTT Network (Manual fallback)

If not already created by the setup script, create the shared Docker network used by MQTT and related services:

```bash
docker network create mqtt-net
```

---

## 4. Configure Shared Storage

Create a symbolic link from the project’s local `media` directory to the physical storage location used by services such as Jellyfin, Frigate, and other media-related applications.

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

Once configuration and storage are ready, start all stacks:

```bash
docker compose up -d
```

Verify that all services are running correctly before proceeding with further configuration.

