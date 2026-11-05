# Sourced by the race scripts. The CLI names containers after the project
# folder, which differs between machines, so find the running database.
DB=${SUPABASE_DB_CONTAINER:-$(docker ps --filter 'name=^supabase_db_' --format '{{.Names}}' | head -n 1)}
if [ -z "$DB" ]; then
  echo "no local Supabase database is running: run supabase start" >&2
  exit 1
fi
PSQL=(docker exec -i "$DB" psql -U postgres -d postgres -Atq -v ON_ERROR_STOP=1)
