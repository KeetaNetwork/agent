import Foundation

enum Command {
    /// export SSH_AUTH_SOCK=/Users/dscheutz/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
    case socketAuth(path: String)
    
    /// GPG
    
    /// /usr/bin/env bash -c 'gpgconf --kill all'
    case killGPGConf
    
    /// ./gpg-agent --server gpg-connect-agent
    /// - inputs: RELOADAGENT, SCD LEARN
    /// - output: key grip
    case setupGPGAgent
    
    /// ./gpg --card-status
    case checkCardStatus
    
    /// ./gpg --expert --full-generate-key
    /// - inputs: 13, {keyGrip}, Q, {lifetime: 0}, Y, {full name}, {email}, return key, O
    /// - output: keyId
    case exportGPG
    
    /// ./gpg --check-signatures
    /// - output:  good & bad signatures
    case checkGPGKeys
    
    /// echo -n "{message}" | ./gpg --armor --clearsign --textmode -u {keyId}
    /// - output: GPG signed message
    case signGPG(message: String, keyId: String)
    
    /// Git
    
    /// git config --global commit.gpgsign true
    case gitEnableGPGSigning
    
    /// git config --global user.signingkey {keyId}
    case gitSetSigningKey(keyId: String)
    
    /// git config --global agent-program {gpg-agent path}
    case gitSetGPGProgram(path: String)
    
    var executable: String {
        switch self {
        case .socketAuth:
            return "usr/bin"
        case .killGPGConf:
            return "/usr/bin/env"
        case .setupGPGAgent:
            return Bundle.main.url(forResource: "gnupg/bin/gpg-agent", withExtension: "")!.path
//            return "./gpg-agent"
        case .checkCardStatus, .exportGPG, .checkGPGKeys, .signGPG:
            return Bundle.main.url(forResource: "gnupg/bin/gpg", withExtension: "")!.path
//            return "./gpg"
        case .gitEnableGPGSigning, .gitSetSigningKey, .gitSetGPGProgram:
            return "/usr/bin/git"
        }
    }
    
//    var isAlias: Bool {
//        switch self {
//        case .killGPGConf, .setupGPGAgent, .checkCardStatus, .exportGPG, .checkGPGKeys, .signGPG:
//            return false
//        case .gitEnableGPGSigning, .gitSetSigningKey, .gitSetGPGProgram:
//            return true
//        }
//    }

    var commands: [String] {
        switch self {
        case .socketAuth(let path):
            return ["export", "SSH_AUTH_SOCK=\(path)"]
        case .killGPGConf:
            return ["bash", "-c", "'gpgconf --kill all'"]
        case .setupGPGAgent:
            return ["-server", "gpg-connect-agent"]
        case .checkCardStatus:
            return ["--card-status"]
        case .exportGPG:
            return ["-expert --full-generate-key"]
        case .checkGPGKeys:
            return ["--check-signatures"]
        case .signGPG(let message, let keyId):
            return ["echo", "-n \"\(message)\"", "| ./gpg", "--armor", "--clearsign", "--textmode", "-u \(keyId)"]
        case .gitEnableGPGSigning:
            return ["config", "--global", "commit.gpgsign", "true"]
        case .gitSetSigningKey(let keyId):
            return ["config", "--global", "user.signingkey", keyId]
        case .gitSetGPGProgram(let path):
            return ["config", "--global", "gpg.program", path]
        }
    }
}
