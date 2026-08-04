#!/bin/bash
# Respaldo de la tabla juegos
docker compose exec -T postgres pg_dump -U gamestore -d gamestore --data-only --table=juegos > backup_juegos_$(date +%Y%m%d_%H%M%S).sql
echo "Backup de videojuegos completado."
