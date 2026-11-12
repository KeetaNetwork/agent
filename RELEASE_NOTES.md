# Signet release notes

## 2.0: Keeta Agent is now Signet

- **The new name.** Keeta Agent is now Signet. It updates in place: the same app identity, the same Secure Enclave key, the same GPG and SSH public keys.
- **Signs in SSH's format.** A new setup points git at your Secure Enclave key in SSH's format, through a small helper that reaches Signet even from apps that don't pass `SSH_AUTH_SOCK` on, such as Xcode and Tower. A GPG setup you already have is left as it is.
- **GitHub verifies SSH-signed commits.** Connecting GitHub adds your SSH key as a signing key as well as for SSH. If you connected GitHub with Keeta Agent, connect again once to add it.
- **One socket, `~/Library/Signet/agent.sock`.** Keeta Agent's old path leads to it, so earlier setups keep working.
- **Works beside Workspace for Mac.** When Workspace for Mac serves your key, Signet stands by and takes over if Workspace quits. You can keep both installed.
- **Your GPG identity is kept** in `~/Library/Signet` (its public key, fingerprint and creation time), ready for signing without GnuPG.
- Needs macOS 13 or later.
