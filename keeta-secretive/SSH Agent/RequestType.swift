import Foundation

extension SSHAgent {
    // The type of the SSH Agent Request, as described in https://tools.ietf.org/id/draft-miller-ssh-agent-01.html#rfc.section.5.1
    enum RequestType: UInt8, CustomDebugStringConvertible {
        
        case requestIdentities = 11
        case signRequest = 13
        
        var debugDescription: String {
            switch self {
            case .requestIdentities:
                return "RequestIdentities"
            case .signRequest:
                return "SignRequest"
            }
        }
    }
}
