import Foundation

func serialNumber() -> String? {
    let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    
    defer {
        IOObjectRelease(platformExpert)
    }
    
    guard platformExpert > 0 else {
        return nil
    }
    
    let property = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
    
    guard let serialNumber = property?.takeUnretainedValue() as? String else {
        return nil
    }

    return serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
}
