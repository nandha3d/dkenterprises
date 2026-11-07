#!/usr/bin/env bash
# Runs on the VPS as the app user after GitHub Actions has moved the checkout
# to the commit being deployed (see .github/workflows/deploy.yml).
set -euo pipefail

cd "$(dirname "$0")/.."
PHP="${PHP:-php8.3}"

"$PHP" /usr/local/bin/composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-progress

"$PHP" artisan down --retry=15 || true
trap '"$PHP" artisan up' EXIT

"$PHP" artisan migrate --force
# Controllers and middleware read env() at runtime, so config:cache must stay off.
"$PHP" artisan optimize:clear
"$PHP" artisan view:cache

# Drop OPcache so PHP-FPM / LiteSpeed picks up the new code.
if command -v systemctl >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo /usr/bin/systemctl reload php8.3-fpm || true
fi
touch .htaccess server.php || true

echo "Deployed $(git rev-parse --short HEAD)"
