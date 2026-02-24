import Foundation

extension Bundle {
    func string(forInfoDictionaryKey key: String) -> String? {
        object(forInfoDictionaryKey: key) as? String
    }
}
