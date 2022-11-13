import XCTest
@testable import Agent

final class GrabberTests: XCTestCase {

    let gpgInput = """
-----BEGIN PGP PUBLIC KEY BLOCK-----

mFIEY2o0exMIKoZIzj0DAQcCAwTlutqP6slU+r/C1siTFspwEOw9rLCEoHO5VcbC
2QKG+aAx81Mw+I79C6gWV3Fy37zB2NSjn9JDf4U1sU/ezGTTtCJEYXZpZCBTY2hl
dXR6IDxkc2NoZXV0ekBrZWV0YS5jb20+iJEEExMIADkWIQS2YL+gLISPxNRCeJeb
UJScmEer0AUCY2o0ewIbAwULCQgHAgIiAgYVCgkICwICFgACHgcCF4AACgkQm1CU
nJhHq9D0KgEAncunzV3bBf4DjmclHMPCQr/UrxuTBNKn5VXjbN1/Z5kBAO8qujHV
Is420W6zOi2DdvSbU/jqIAhvo/afKtVwMguG
=7TLp
-----END PGP PUBLIC KEY BLOCK-----
"""
    
    let randomString = UUID().uuidString
    
    func test_grab_GPGKey() {
        let expectedKey = gpgInput
        
        XCTAssertEqual(expectedKey, Grabber.gpgKey(from: gpgInput))
        XCTAssertEqual(expectedKey, Grabber.gpgKey(from: gpgInput + randomString))
        XCTAssertEqual(expectedKey, Grabber.gpgKey(from: randomString + gpgInput))
        XCTAssertEqual(expectedKey, Grabber.gpgKey(from: randomString + gpgInput + randomString))
    }
    
    let keyIDInput =
"""
gpg: revocation certificate stored as '/Users/dscheutz/.keeta_agent/openpgp-revocs.d/A998E164986E87625FEDF2D16A4319704247D564.rev'
"""
    
    func test_grab_keyID() {
        let expectedKeyId = "A998E164986E87625FEDF2D16A4319704247D564"
        
        XCTAssertEqual(expectedKeyId, Grabber.keyId(from: keyIDInput))
        XCTAssertEqual(expectedKeyId, Grabber.keyId(from: keyIDInput + randomString))
    }
    
    let keyGripInput = """
gnupg-pkcs11-scd[82711]: chan_0 -> S APPTYPE PKCS11
S SERIALNO D2760001240111503131988FDBF81111
S APPTYPE PKCS11
gnupg-pkcs11-scd[82711]: chan_0 -> S KEY-FRIEDNLY 50312962CADCCD7F6AE2F50E18D4B8433BB96DC2 /CN=Dummy on ecdsa-sha2-nistp256
gnupg-pkcs11-scd[82711]: chan_0 -> S CERTINFO 101 Roy...
S KEY-FRIEDNLY 50312962CADCCD7F6AE2F50E18D4B8433BB96DC2 /CN=Dummy on ecdsa-sha2-nistp256
gnupg-pkcs11-scd[82711]: S CERTINFO 101
"""
    
    func test_grab_keyGrip() {
        let expectedKeyGrip = "50312962CADCCD7F6AE2F50E18D4B8433BB96DC2"
        
        XCTAssertEqual(expectedKeyGrip, Grabber.keyGrip(from: keyGripInput))
    }
    
    let badSignaturesInput = """
gpg: 16 good signatures
gpg: 1 bad signature
gpg: 654 signatures not checked due to missing keys
"""
    
    let validSignaturesInput = """
gpg: 16 good signatures
gpg: 654 signatures not checked due to missing keys
"""
    
    func test_grab_signatures() {
        XCTAssertTrue(Grabber.hasBadSignatures(from: badSignaturesInput))
        XCTAssertFalse(Grabber.hasBadSignatures(from: validSignaturesInput))
    }
    
    // List keys output
    /*
     /Users/dscheutz/.keeta_agent/pubring.kbx
     ----------------------------------------
     pub   nistp256 2022-11-11 [SC]
           1C7E7D7B8D8CD1217919A7CB9C913CF83D6996DF
     uid           [ultimate] Keeta Test <test@keeta.com>
     */
}
