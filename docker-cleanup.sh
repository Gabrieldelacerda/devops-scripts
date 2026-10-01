#!/bin/bash
if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker is not installed"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker daemon is not available"
  exit 1
fi

echo "Removing stopped containers..."
docker container prune -f

echo "Removing unused images..."
docker image prune -a -f

echo "Removing dangling volumes..."
docker volume prune -f

echo "Done!!"
