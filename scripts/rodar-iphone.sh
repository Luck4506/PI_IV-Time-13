#!/bin/bash
# Autoria de Lucas Soares Gonçalves RA 25009467
set -euo pipefail

# Resolve paths from this file, including when the repository contains spaces.
TRILHA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

fail() { printf '\n%s\n' "$*" >&2; exit 1; }
trap 'printf "\nA execução parou. Confira a mensagem acima.\n" >&2' ERR

case "${1:-}" in
  --help|-h)
    printf '%s\n' 'Uso: bash scripts/rodar-iphone.sh [--check]' \
      'Sem opções: prepara a API e abre o app no iPhone simulado.' \
      '--check: confere a preparação e os simuladores, sem abrir o app.'
    exit 0 ;;
  --check|'') ;;
  *) fail 'Opção desconhecida. Use --help.' ;;
esac
[[ $# -le 1 ]] || fail 'Use somente a opção --check ou execute sem opções.'
[[ "$(uname -s)" == Darwin ]] || fail 'Este comando precisa ser executado no Mac com Xcode.'
command -v node >/dev/null || fail 'Node.js não encontrado. Instale-o antes de executar.'
if command -v flutter >/dev/null; then
  TRILHA_FLUTTER="$(command -v flutter)"
elif [[ -x "$HOME/dev/flutter/bin/flutter" ]]; then
  TRILHA_FLUTTER="$HOME/dev/flutter/bin/flutter"
else
  fail 'Flutter não encontrado. Adicione a pasta flutter/bin ao PATH.'
fi
/usr/bin/xcrun --find simctl >/dev/null || fail 'Selecione o Xcode completo antes de continuar.'

# Inventory only: launching and debugging are delegated to Flutter.
iphone() {
  node - "$1" <<'NODE'
const { execFileSync } = require('node:child_process');
const inventory = JSON.parse(execFileSync('/usr/bin/xcrun', ['simctl', 'list', 'devices', 'available', '-j'], { encoding: 'utf8' }));
const devices = Object.entries(inventory.devices)
  .filter(([runtime]) => runtime.includes('.iOS-'))
  .flatMap(([, devices]) => devices)
  .filter(device => device.isAvailable && device.name.startsWith('iPhone'));
const eligible = process.argv[2] === 'booted' ? devices.filter(device => device.state === 'Booted') : devices;
const device = eligible.find(device => device.name === 'iPhone 16e') ?? eligible[0];
if (device) console.log(device.udid);
NODE
}

[[ -n "$(iphone available)" ]] || fail 'Nenhum iPhone simulado está instalado. Instale um runtime iOS no Xcode.'
printf '\n%s\n' 'Preparando a API TCP e os bancos…'
node "$TRILHA_ROOT/scripts/prepare-ios.mjs"
if [[ "${1:-}" == --check ]]; then
  printf '\n%s\n' 'Preparação concluída. Há um simulador iPhone disponível.'
  exit 0
fi

TRILHA_DEVICE="$(iphone booted)"
if [[ -z "$TRILHA_DEVICE" ]]; then
  printf '\n%s\n' 'Iniciando o simulador iOS…'
  "$TRILHA_FLUTTER" emulators --launch apple_ios_simulator
  for ((attempt = 0; attempt < 40; attempt++)); do
    TRILHA_DEVICE="$(iphone booted)"
    [[ -z "$TRILHA_DEVICE" ]] || break
    sleep 1
  done
fi
[[ -n "$TRILHA_DEVICE" ]] || fail 'Abra um iPhone no Device Hub, clique Start e execute este comando novamente.'
TRILHA_XCODE="$(/usr/bin/xcode-select -p)"
TRILHA_HUB="${TRILHA_XCODE%/Contents/Developer}/Contents/Applications/DeviceHub.app"
if [[ -d "$TRILHA_HUB" ]]; then
  /usr/bin/open -a "$TRILHA_HUB"
else
  /usr/bin/open -a Simulator
fi

cd "$TRILHA_ROOT/frontend"
"$TRILHA_FLUTTER" pub get
printf '\n%s\n' 'Abrindo o Gabariteii no iPhone. Mantenha este terminal aberto.' \
  'Durante a execução: r atualiza o app; q encerra a execução. A API continua em segundo plano.'
exec "$TRILHA_FLUTTER" run -d "$TRILHA_DEVICE" --debug \
  --dart-define-from-file="$TRILHA_ROOT/.local/frontend-tcp.json"
