# Keeta Agent
Keeta Agent is a helper app that lives in your toolbar for automated key management of SSH and GPG keys in the macOS Secure Enclave. Keeta Agent uniquely links `git` commits signed on your physical device to your connected GitHub account, increasing developer security beyond existing tools. The [secretive project](https://github.com/maxgoedjen/secretive) and [sekey project](https://github.com/sekey/sekey) inspired our work on Keeta Agent but were rewritten and expanded to support unique key types such as GPG.

<p align="center" width="800">
    <img src="/.github/readme/app.png" alt="Screenshot of Keeta Agent">
</p>

### Access Control

The Keeta Agent is specifically designed for Macs with Apple Silicon, featuring a built-in Secure Enclave that provides advanced security features such as Touch ID or authentication with Apple Watch. The Keeta Agent ensures that all requested actions are securely processed by automatically requiring Touch ID authentication before proceeding.

<img src="/.github/readme/touchid.png" alt="Screenshot of Keeta Agent authenticating with Touch ID" width="250">