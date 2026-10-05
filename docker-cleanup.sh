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
if ! docker container prune -f; then
  echo "[ERROR] Failed to remove stopped containers"
  exit 1
fi

echo "Removing unused images..."
if ! docker image prune -f; then
  echo "[ERROR] Failed to remove unused images"
  exit 1
fi

echo "Removing dangling volumes..."
if ! docker volume prune -f; then
  echo "[ERROR] Failed to remove dangling volumes"
  exit 1
fi

echo "[ OK ] Docker cleanup completed successfully"
