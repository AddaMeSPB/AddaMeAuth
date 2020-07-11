import Vapor
import MongoKitten
import Twilio
import APNS
import JWTKit

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder

    guard
        let KEY_IDENTIFIER = Environment.get("KEY_IDENTIFIER"),
        let TEAM_IDENTIFIER = Environment.get("TEAM_IDENTIFIER") else {
        fatalError("No value was found at the given public key environment 'APNSAuthKey'")
    }
    let keyIdentifier = JWKIdentifier.init(string: KEY_IDENTIFIER)

    switch app.environment {
    case .production:
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(filePath: "home/ubuntu/AuthKey_\(KEY_IDENTIFIER).p8"),
                keyIdentifier: keyIdentifier,
                teamIdentifier: TEAM_IDENTIFIER
            ),
            topic: "com.tenreck.app",
            environment: .production
        )
    case .development:
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(filePath: "./AuthKey_\(KEY_IDENTIFIER).p8"),
                keyIdentifier: keyIdentifier,
                teamIdentifier: TEAM_IDENTIFIER
            ),
            topic: "com.tenreck.app2",
            environment: .sandbox
        )
    default:
        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(filePath: "./AuthKey_\(KEY_IDENTIFIER).p8"),
                keyIdentifier: keyIdentifier,
                teamIdentifier: TEAM_IDENTIFIER
            ),
            topic: "com.tenreck.app2",
            environment: .sandbox
        )
    }

    guard let jwksString = Environment.process.JWKS else {
        fatalError("No value was found at the given public key environment 'JWKS'")
    }
    try app.jwt.signers.use(jwksJSON: jwksString)
    app.twilio.configuration = .environment

    // Encoder & Decoder
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Configure custom hostname.
    switch app.environment {
    case .production:
        app.http.server.configuration.hostname = "https://addame.com"
    case .development:
        app.http.server.configuration.port = 8080
        app.http.server.configuration.hostname = "0.0.0.0"
    default:
        app.http.server.configuration.port = 8080
        app.http.server.configuration.hostname = "0.0.0.0"
    }

    try routes(app)

}
