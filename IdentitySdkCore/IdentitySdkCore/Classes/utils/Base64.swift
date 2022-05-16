import Foundation

public class Base64 {
    public static func base64UrlSafeDecode(_ input: String) -> Data? {
        let rem = input.count % 4
        
        var ending = ""
        if rem > 0 {
            let amount = 4 - rem
            ending = String(repeating: "=", count: amount)
        }
        
        let base64 = input.replacingOccurrences(of: "-", with: "+", options: NSString.CompareOptions(rawValue: 0), range: nil)
            .replacingOccurrences(of: "_", with: "/", options: NSString.CompareOptions(rawValue: 0), range: nil) + ending
        
        return Data(base64Encoded: base64, options: NSData.Base64DecodingOptions(rawValue: 0))
    }
    public static func encodeBase64(_ bytes: [UInt8]) -> String {
           return encodeBase64(Data(_: bytes))
       }
       
       public static func encodeBase64(_ data: Data) -> String {
           return data.base64EncodedString()
       }

       public static func encodeBase64URL(_ bytes: [UInt8]) -> String {
           return encodeBase64URL(Data(_: bytes))
       }

       public static func encodeBase64URL(_ data: Data) -> String {
           return data.base64EncodedString()
               .replacingOccurrences(of: "+", with: "-")
               .replacingOccurrences(of: "/", with: "_")
               .replacingOccurrences(of: "=", with: "")
       }
}
