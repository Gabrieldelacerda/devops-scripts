#!/bin/bash

echo "Removing stopped containers..."
docker container prune -f

echo "Removing unused images..."
docker image prune -a -f

echo "Removing dangling volumes..."
docker volume prune -f

echo "Done!!"
