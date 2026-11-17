#!/bin/zsh
set -e
cd "$(dirname "$0")"
if [[ $# -eq 0 && -f backend/.env.neo4j-local ]]; then
  exec node scripts/iniciar.mjs --neo4j-local
fi
exec node scripts/iniciar.mjs "$@"
