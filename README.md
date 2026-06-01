# Home Infrastructure Setup (Docker Stacks) — Sintesi

## 1. MQTT network

```bash
docker network create mqtt-net
```

## 2. Shared storage

```bash
ln -s /mnt/storage/media media
```

## 3. Base configuration

```bash
cp -r base_config/* runtime/
```

## 4. Start stacks

```bash
docker compose up -d
```
