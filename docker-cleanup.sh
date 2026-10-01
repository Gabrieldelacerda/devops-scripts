#!/bin/bash
if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker is not installed"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker daemon is not available"
  exit 1
fi

read -r -p "This will remove stopped containers, unused images, and dangling volumes. Continue? [y/N] " REPLY

if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo "Removing stopped containers..."
docker container prune -f

echo "Removing unused images..."
docker image prune -f

echo "Removing dangling volumes..."
docker volume prune -f

echo "Done!!"
