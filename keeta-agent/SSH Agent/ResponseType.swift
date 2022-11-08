import Foundation

extension SSHAgent {
    /// The type of the SSH Agent Response, as described in https://tools.ietf.org/id/draft-miller-ssh-agent-01.html#rfc.section.5.1
    enum ResponseType: UInt8, CustomDebugStringConvertible {
        
        case agentFailure = 5
        case agentIdentitiesAnswer = 12
        case agentSignResponse = 14

        var debugDescription: String {
            switch self {
            case .agentFailure:
                return "AgentFailure"
            case .agentIdentitiesAnswer:
                return "AgentIdentitiesAnswer"
            case .agentSignResponse:
                return "AgentSignResponse"
            }
        }
        
        var data: Data {
            var raw = rawValue
            return Data(bytes: &raw, count: UInt8.bitWidth/8)
        }
    }
}
