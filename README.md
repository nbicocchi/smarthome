Here is a clean minimal **README in English** based on your steps:

---

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

## 4. Copy Base Configuration

Copy base configuration files into the runtime directory:

```text
base_config → runtime/
```

Example:

```bash
cp -r base_config/* runtime/
```

---

## Notes

* Ensure `mqtt-net` exists before starting services
* Always verify ownership using `USER:GROUP` defined in `.env`
* First run is required to generate runtime directories
* Configuration files must be placed before final startup

