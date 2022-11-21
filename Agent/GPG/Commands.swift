import Foundation

enum Command {
    /// GPG
    
    /// /usr/bin/env zsh -ls -c gpgconf --kill all
    case killGPGConf
    
    /// ./gpg-agent --server gpg-connect-agent
    /// - inputs: RELOADAGENT, SCD LEARN
    /// - output: key grip
    case setupGPGAgent
    
    /// ./gpg-connect-agent reloadagent /bye
    case restartGPGAgent
    
    /// ./gpg --card-status
    case checkCardStatus
    
    /// ./gpg --batch --generate-key
    /// - inputs: 13, {keyGrip}, Q, {lifetime: 0}, Y, {full name}, {email}, return key, O
    /// - output: keyId
    case createGPGKey(inputFilePath: String)
    
    /// ./gpg --check-signatures
    /// - output:  good & bad signatures
    case checkGPGKeys
    
    /// ./gpg --list-keys
    /// - output:  existing GPG keys
    case listGPGKeys
    
    /// ./gpg --export --armor  {keyId}
    /// - output: public GPG key
    case exportGPGKey(keyId: String)
    
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
    
    /// General
    
    /// ln -s {source} {destination}
    case createSymlink(source: String, destination: String)
    
    var executable: String {
        switch self {
        case .killGPGConf, .setupGPGAgent, .createSymlink:
            return "/usr/bin/env"
        case .restartGPGAgent:
            return gpgAgentConnectFilePath
        case .checkCardStatus, .createGPGKey, .checkGPGKeys, .listGPGKeys, .exportGPGKey, .signGPG:
            return gpgFilePath
        case .gitEnableGPGSigning, .gitSetSigningKey, .gitSetGPGProgram:
            return "/usr/bin/git"
        }
    }
    
    var commands: [String] {
        switch self {
        case .createSymlink(let source, let destination):
            return ["ln", "-s", source, destination]
        case .killGPGConf:
            return ["zsh", "-ls", "-c", "gpgconf --kill all"]
        case .setupGPGAgent:
            return ["bash", "-c", "\(gpgAgentFilePath) --server gpg-connect-agent <<<$'RELOADAGENT\nSCD LEARN'"]
        case .restartGPGAgent:
            return ["reloadagent", "/bye"]
        case .checkCardStatus:
            return ["--card-status"]
        case .createGPGKey(let filePath):
            return ["--batch", "--expert", "--full-generate-key", "\(filePath)"]
        case .checkGPGKeys:
            return ["--check-signatures"]
        case .listGPGKeys:
            return ["--list-keys", "--keyid-format=long"]
        case .exportGPGKey(let keyId):
            return ["--export", "--armor", keyId]
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
