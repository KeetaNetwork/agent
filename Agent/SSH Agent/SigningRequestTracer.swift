import Foundation
import AppKit
import Security

final class SigningRequestTracer {
    
    static func processName(from fileHandleReader: FileHandleReader) -> String {
        let firstInfo = process(from: fileHandleReader.pidOfConnectedProcess)

        var provenance = SigningRequestProvenance(root: firstInfo)
        while NSRunningApplication(processIdentifier: provenance.origin.pid) == nil && provenance.origin.parentPID != nil {
            provenance.chain.append(process(from: provenance.origin.parentPID!))
        }
        return provenance.origin.displayName
    }
    
    // MARK: - Helper
    
    /// Generates a ``SecretKit.SigningRequestProvenance.Process`` from a provided process ID.
    /// - Parameter pid: The process ID to look up.
    /// - Returns: A ``SecretKit.SigningRequestProvenance.Process`` describing the process.
    private static func process(from pid: Int32) -> SigningRequestProvenance.Process {
        var pidAndNameInfo = self.pidAndNameInfo(from: pid)
        let ppid = pidAndNameInfo.kp_eproc.e_ppid != 0 ? pidAndNameInfo.kp_eproc.e_ppid : nil
        let procName = String(cString: &pidAndNameInfo.kp_proc.p_comm.0)
        return SigningRequestProvenance.Process(pid: pid, processName: procName, appName: appName(for: pid), iconURL: iconURL(for: pid), parentPID: ppid)
    }
    
    /// Generates a `kinfo_proc` representation of the provided process ID.
    /// - Parameter pid: The process ID to look up.
    /// - Returns: a `kinfo_proc` struct describing the process ID.
    private static func pidAndNameInfo(from pid: Int32) -> kinfo_proc {
        var len = MemoryLayout<kinfo_proc>.size
        let infoPointer = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 1)
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        sysctl(&name, UInt32(name.count), infoPointer, &len, nil, 0)
        return infoPointer.load(as: kinfo_proc.self)
    }
    
    /// Looks up the URL for the icon of a process ID, if it has one.
    /// - Parameter pid: The process ID to look up.
    /// - Returns: A URL to the icon, if the process has one.
    private static func iconURL(for pid: Int32) -> URL? {
        do {
            if let app = NSRunningApplication(processIdentifier: pid), let icon = app.icon?.tiffRepresentation {
                let temporaryURL = URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID().uuidString).png"))
                let bitmap = NSBitmapImageRep(data: icon)
                try bitmap?.representation(using: .png, properties: [:])?.write(to: temporaryURL)
                return temporaryURL
            }
        } catch {
        }
        return nil
    }

    /// Looks up the application name of a process ID, if it has one.
    /// - Parameter pid: The process ID to look up.
    /// - Returns: The process's display name, if the process has one.
    private static func appName(for pid: Int32) -> String? {
        NSRunningApplication(processIdentifier: pid)?.localizedName
    }
}
