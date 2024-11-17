//
//  Region+Code.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 30/9/2024.
//

import Foundation

public extension Region {
    enum Code {
        case country(code: String)
        case subdivision(countryCode: String, subdivisionCode: String)
    }
}

public extension Region.Code {
    func contains(_ other: Self) -> Bool {
        switch self {
        case .country(let code):
            switch other {
            case .country(let otherCode):
                return code == otherCode
            case .subdivision(let otherCountryCode, _):
                return code == otherCountryCode
            }
        case .subdivision(_, _):
            switch other {
            case .country(_):
                return false
            case .subdivision(_, _):
                return self == other
            }
        }
    }
}

extension Region.Code : Codable, CustomStringConvertible, RawRepresentable, Hashable, Sendable {
    public init?(rawValue: String) {
        guard rawValue.count == 2 || rawValue.count > 3 else {
            return nil
        }
        let countryCode = rawValue.prefix(2)
        guard rawValue.prefix(2).allSatisfy({ $0.isLetter }) else {
            return nil
        }
        
        guard rawValue.count > 3 else {
            // Country
            self = .country(code: .init(countryCode).uppercased())
            return
        }
        
        let dividerIndex = rawValue.index(rawValue.startIndex, offsetBy: 2)
        guard rawValue[dividerIndex] == "-" else {
            return nil
        }
        
        self = .subdivision(
            countryCode: .init(countryCode).uppercased(),
            subdivisionCode: .init(
                rawValue.suffix(from: rawValue.index(after: dividerIndex))
            ).uppercased()
        )
    }
    
    public var description: String {
        rawValue
    }
    
    public var rawValue: String {
        switch self {
        case .country(let code):
            code
        case .subdivision(let countryCode, let subdivisionCode):
            "\(countryCode)-\(subdivisionCode)"
        }
    }
}

extension Region.Code {
    var standard: String {
        switch self {
        case .country(_):
            "ISO3166-1"
        case .subdivision(_, _):
            "ISO3166-2"
        }
    }
}
