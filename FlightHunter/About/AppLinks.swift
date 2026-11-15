import Foundation

enum AppLinks {
    static let privacyPolicy = "https://1kickdown.github.io/flighthunter-site/privacy.html"
    static let supportEmail = "idaniyar363@gmail.com"

    static var privacyPolicyURL: URL? {
        privacyPolicy.isEmpty ? nil : URL(string: privacyPolicy)
    }

    static var supportURL: URL? {
        supportEmail.isEmpty ? nil : URL(string: "mailto:\(supportEmail)")
    }
}
