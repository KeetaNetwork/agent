#!/bin/bash
# Signs Signet's app bundle inside out, as notarization needs: every Mach-O file inside it (the
# bundled GnuPG, its libraries and any framework) and then the app itself, all with the hardened
# runtime. The app gets its entitlements with the team's prefix filled in, plus the application and
# team identifiers that let its Developer ID provisioning profile allow the keychain group the
# Secure Enclave key is in (2BG69HN56W.com.keeta.agent).
#
#   scripts/sign-app.sh <Signet.app> <identity> [keychain]
#
# An identity of "-" signs ad hoc: CI does that to check this script without the certificate.
set -euo pipefail

app=$1
identity=$2
keychain=${3:-}
team=2BG69HN56W
bundle_id=com.keeta.agent
here=$(cd "$(dirname "$0")" && pwd)

args=(--force --options runtime --sign "$identity")
if [ "$identity" = - ]; then args+=(--timestamp=none); else args+=(--timestamp); fi
if [ -n "$keychain" ]; then args+=(--keychain "$keychain"); fi

main="$app/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")"

# Loose Mach-O files first (symlinks are left alone: what they point to is signed).
while IFS= read -r -d '' f; do
  [ "$f" = "$main" ] && continue
  case "$f" in "$app"/Contents/Frameworks/*.framework/*) continue ;; esac
  if file -b "$f" | grep -q 'Mach-O'; then
    codesign "${args[@]}" "$f"
  fi
done < <(find "$app/Contents" -type f -print0)

# Then any framework, as a bundle.
if [ -d "$app/Contents/Frameworks" ]; then
  while IFS= read -r -d '' framework; do
    codesign "${args[@]}" "$framework"
  done < <(find "$app/Contents/Frameworks" -maxdepth 1 -name '*.framework' -print0)
fi

# Then the app, last, since its signature seals everything inside it.
entitlements=$(mktemp -t signet-entitlements)
trap 'rm -f "$entitlements"' EXIT
sed "s/\$(AppIdentifierPrefix)/$team./g" "$here/../Agent/keeta_secretive.entitlements" > "$entitlements"
/usr/libexec/PlistBuddy \
  -c "Add :com.apple.application-identifier string $team.$bundle_id" \
  -c "Add :com.apple.developer.team-identifier string $team" \
  "$entitlements"
codesign "${args[@]}" --entitlements "$entitlements" "$app"
