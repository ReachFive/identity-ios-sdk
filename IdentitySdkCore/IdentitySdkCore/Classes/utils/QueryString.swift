import Foundation

//TODO à supprimer
public class QueryString {
    public static func parseQueriesStrings(query: String) -> Dictionary<String, String?> {
        query.split(separator: "&").reduce(Dictionary<String, String?>(), { (acc, param) in
            var mutAcc = acc
            let splited = param.split(separator: "=")
            let key: String = String(splited.first!)
            let value: String? = splited.count > 1 ? String(splited[1]) : nil
            mutAcc.updateValue(value, forKey: key)
            return mutAcc
        })
    }
}
