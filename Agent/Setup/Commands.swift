import Foundation

enum Command {
    /// GPG
    
    /// /usr/bin/env zsh -ls -c gpgconf --kill all
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
    case exportGPG(inputFilePath: String)
    
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
        case .killGPGConf, .setupGPGAgent:
            return "/usr/bin/env"
        case .checkCardStatus, .exportGPG, .checkGPGKeys, .signGPG:
            return gpgPath
        case .gitEnableGPGSigning, .gitSetSigningKey, .gitSetGPGProgram:
            return "/usr/bin/git"
        }
    }
    
    var commands: [String] {
        switch self {
        case .killGPGConf:
            return ["zsh", "-ls", "-c", "gpgconf --kill all"]
        case .setupGPGAgent:
            return ["bash", "-c", "\(gpgAgentPath) --server gpg-agent-connect <<<$'RELOADAGENT\nSCD LEARN'"]
        case .checkCardStatus:
            return ["--card-status"]
        case .exportGPG(let filePath):
            return ["--batch", "--generate-key \(filePath)"]// "--full-generate-key"]
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
