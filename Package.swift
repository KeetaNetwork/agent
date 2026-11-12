// swift-tools-version: 6.0
// SignetKit: Signet's core, shared by the standalone Signet app (Agent.xcodeproj) and Workspace for
// Mac. Everything but the Secure Enclave builds and is tested on Linux too, against the real
// OpenSSH and git tools; the Secure Enclave key (SecureEnclaveKey.swift) is macOS only.
import PackageDescription

let package = Package(
  name: "SignetKit",
  platforms: [.macOS(.v13)],
  products: [.library(name: "SignetKit", targets: ["SignetKit"])],
  dependencies: [
    // CryptoKit's API on every platform (re-exports CryptoKit on Apple's).
    .package(url: "https://github.com/apple/swift-crypto.git", "3.0.0"..<"5.0.0")
  ],
  targets: [
    .target(
      name: "SignetKit",
      dependencies: [.product(name: "Crypto", package: "swift-crypto")],
      path: "SignetKit/Sources/SignetKit"
    ),
    .testTarget(
      name: "SignetKitTests",
      dependencies: ["SignetKit", .product(name: "Crypto", package: "swift-crypto")],
      path: "SignetKit/Tests/SignetKitTests",
      resources: [.copy("Fixtures")]
    ),
  ]
)
