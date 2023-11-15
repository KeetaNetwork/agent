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
    
    let longKeyIdsInput = """
pub  nistp256/48AD001ABA8F9248 2022-11-13 [SCA]
      CBCBC441383E2F8D6BA7C6E248AD001ABA8F9248
uid                 [ultimate] Ty <ty@keeta.com>

pub  nistp256/127B4C05D34B50AD 2022-11-13 [SCA]
      6202F16CF5C1C6FEAF889EC8127B4C05D34B50AD
uid                 [ultimate] David Scheutz <dscheutz@keeta.com>

pub  nistp256/48AD001ABA8F9248 2022-11-13 [SCA]
      CBCBC441383E2F8D6BA7C6E248AD001ABA8F9248
uid                 [ultimate] Ty <ty@keeta.com>
"""
    
    func test_grab_shortKeyId() {
        let expectedKeyId = "127B4C05D34B50AD"
        let keyCurve = "nistp256"
        let validEmail = "dscheutz@keeta.com"
        let invalidEmail = "invalid@keeta.com"
        
        XCTAssertEqual(expectedKeyId, Grabber.shortKeyId(from: longKeyIdsInput, for: validEmail, keyCurve: keyCurve))
        XCTAssertNil(Grabber.shortKeyId(from: longKeyIdsInput, for: invalidEmail, keyCurve: keyCurve))
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
    
    let singleKeysList =
"""
/Users/dscheutz/.keeta_agent/pubring.kbx
----------------------------------------
pub   nistp256/0F7095395BA8CD85 2022-11-14 [SCA]
      E20728F57570B55FA49A7C640F7095395BA8CD85
uid                 [ultimate] David Scheutz <dscheutz@keeta.com>


/Users/dscheutz/.keeta_agent/pubring.kbx
----------------------------------------
pub   nistp256/0F7095395BA8CD85 2022-11-14 [SCA]
      E20728F57570B55FA49A7C640F7095395BA8CD85
uid                 [ultimate] David Scheutz <dscheutz@keeta.com>
"""

    let multipleKeysList =
"""
/Users/dscheutz/.keeta_agent/pubring.kbx
----------------------------------------
pub   nistp256/0F7095395BA8CD85 2022-11-14 [SCA]
      E20728F57570B55FA49A7C640F7095395BA8CD85
uid                 [ultimate] David Scheutz <dscheutz@keeta.com>

/Users/dscheutz/.keeta_agent/pubring.kbx
----------------------------------------
pub   nistp256/9C913CF83D6996DF 2022-11-11 [SC]
1C7E7D7B8D8CD1217919A7CB9C913CF83D6996DF
uid           [ultimate] Keeta Test <test@keeta.com>
"""

    func test_grap_keyInformation() {
        let keyBoxDirectory = "/.keeta_agent"
        let keyCurve = "nistp256"
        let expected = Grabber.KeyInformation(email: "dscheutz@keeta.com", name: "David Scheutz", keyId: "0F7095395BA8CD85")
        
        XCTAssertEqual(expected, Grabber.keyInformation(from: singleKeysList, in: keyBoxDirectory, keyCurve: keyCurve))
        XCTAssertNil(Grabber.keyInformation(from: singleKeysList, in: keyBoxDirectory, keyCurve: "invalid_curve"))
        XCTAssertNil(Grabber.keyInformation(from: singleKeysList, in: "invalid_directory", keyCurve: keyCurve))
        XCTAssertNil(Grabber.keyInformation(from: multipleKeysList, in: keyBoxDirectory, keyCurve: keyCurve))
    }
}
