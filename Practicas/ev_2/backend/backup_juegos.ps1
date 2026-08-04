# Respaldo de la tabla juegos
$date = Get-Date -Format "yyyyMMdd_HHmmss"
docker compose exec -T postgres pg_dump -U gamestore -d gamestore --data-only --table=juegos > "backup_juegos_$date.sql"
Write-Host "Backup de videojuegos completado: backup_juegos_$date.sql"
