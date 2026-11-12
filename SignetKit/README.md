# SignetKit

Signet's core as a Swift package, shared by the standalone Signet app (`Agent.xcodeproj`) and Workspace for Mac, which depends on it at a pinned version.

- `SignetKey.swift`: the one thing a device key does, sign a 32-byte digest. `SecureEnclaveKey.swift` (macOS) finds Keeta Agent's key by its tag `com.keeta.agent.key` in the keychain group `2BG69HN56W.com.keeta.agent`, or makes one.
- `SSHAgent.swift`, `SignetSocket.swift`, `SignetPaths.swift`: the SSH agent on `~/Library/Signet/agent.sock`, served by whichever Signet runs; another Signet stands by and takes over when the first quits. Keeta Agent's old path `~/Library/KeetaAgent/Data/socket.ssh` leads to it.
- `SSHSignature.swift`: signatures in SSH's format, as `ssh-keygen -Y sign` writes them (Workspace's device registration signs its challenge in the namespace `workspace-signet`).
- `GitSigning.swift`: git signs in SSH's format through Signet, leaving a signing setup the person already has alone unless they replace it.
- `KeetaAccount.swift`: the key's `secp256r1` Keeta account address, and statements signed as that account (P1363 over SHA3-256).
- `GitHubKeys.swift`: the key on the person's GitHub account, as a signing key and an SSH key; GPG keys and emails.
- `GPGIdentity.swift`: the GPG identity's public half, kept in Signet's folder.

```bash
swift test   # Linux or macOS; needs ssh-keygen, ssh-add and git on PATH
```

The tests talk to the agent with OpenSSH's own tools, check signatures with `ssh-keygen`, and commit with real git. The Secure Enclave key isn't covered by them, since no CI machine has one: check it on a Mac.
