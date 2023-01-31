import Foundation

public class QueryString {
    public static func parseQueriesStrings(query: String) -> Dictionary<String, String?> {
        query.split(separator: "&").reduce(Dictionary<String, String?>(), { (acc, param) in
            var mutAcc = acc
            let split = param.split(separator: "=")
            let key: String = String(split.first!)
            let value: String? = split.count > 1 ? String(split[1]) : nil
            mutAcc.updateValue(value, forKey: key)
            return mutAcc
        })
    }
}
