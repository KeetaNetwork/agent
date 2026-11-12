# Releasing Signet

Signet is released from GitHub Actions by the **Release** workflow (`.github/workflows/release.yml`). It builds the app from `main` on GitHub's macOS runner, signs it with Keeta, Inc's Developer ID (team 2BG69HN56W), has Apple notarize the app and its disk image, then tags the commit `v<version>` and publishes a GitHub Release with `Signet-<version>.dmg` and its SHA-256.

## Releasing a version

1. Add the version's section at the top of `RELEASE_NOTES.md` on `main`. The release's notes are that newest section.
2. In Actions, run **Release** on `main` with the version, such as `2.0.0`.
3. Approve the run when the `release` environment asks.

A version is released once: the workflow refuses a version that is already tagged.

## Setting up the `release` environment (once)

In the repository's Settings, Environments, make an environment named `release`, with yourself (or the release owners) as required reviewers and deployment limited to the `main` branch. The keys live only there, never as repository or organization secrets, so no other branch's run can read them.

| Name | Kind | What it holds |
| --- | --- | --- |
| `MAC_DEVELOPER_ID_CERTIFICATE` | Secret | Keeta, Inc's **Developer ID Application** certificate with its private key, exported from Keychain Access as a `.p12` and base64-encoded (`base64 -i developer-id.p12`). The same one Workspace for Mac's releases use. |
| `MAC_DEVELOPER_ID_CERTIFICATE_PASSWORD` | Secret | The password the `.p12` was exported with. |
| `SIGNET_PROVISIONING_PROFILE` | Secret | A **Developer ID** provisioning profile for the App ID `com.keeta.agent`, base64-encoded (`base64 -i Signet.provisionprofile`). It lets Signet use its keychain group, `2BG69HN56W.com.keeta.agent`, where the Secure Enclave key is. Make it at developer.apple.com, Certificates, IDs & Profiles, Profiles, +, Developer ID. |
| `MAC_NOTARY_KEY` | Secret | An App Store Connect API key's `.p8` file, whole, with the Developer role, which `notarytool` notarizes with. |
| `MAC_NOTARY_KEY_ID` | Variable | That key's Key ID. |
| `MAC_NOTARY_ISSUER_ID` | Variable | The Issuer ID shown above App Store Connect's keys. |

## What CI checks on every pull request

The `Signet` workflow builds the app unsigned and signs it ad hoc with `scripts/sign-app.sh`, the script the release signs with. It checks that every Mach-O file in the app (the bundled GnuPG included) carries the hardened runtime, which notarization requires, and that the app's entitlements name the keychain group.

## Not yet

Signet has no auto-updater: people download each version from the Releases page.
