import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey:key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

enum Config {
    static var baseURL: URL {
        return try! URL(string: "wss://" + Configuration.value(for: "REMOTE_GPIO_URL") + "/ws?name=ios")!
    }
    
    static var cfAccessClientId: String {
        return try! Configuration.value(for: "CF_ACCESS_CLIENT_ID")
    }
    
    static var cfAccessClientSecret: String {
        return try! Configuration.value(for: "CF_ACCESS_CLIENT_SECRET")
    }
}

