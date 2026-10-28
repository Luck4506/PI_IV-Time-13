#!/bin/zsh
set -e
cd "$(dirname "$0")"
if [[ ! -f backend/.env ]]; then
  echo 'Configure backend/.env antes de iniciar.'
  exit 1
fi
if curl --silent --fail --max-time 2 http://127.0.0.1:3000/health/live >/dev/null; then
  echo 'A API já está em execução na porta 3000.'
else
  (cd backend && exec node --env-file=.env src/server.js) &
  TRILHA_API_PID=$!
  trap 'kill "$TRILHA_API_PID" 2>/dev/null || true' EXIT INT TERM
fi
echo 'Abra http://127.0.0.1:5173 para testar. Mantenha esta janela aberta.'
cd frontend
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:3000
