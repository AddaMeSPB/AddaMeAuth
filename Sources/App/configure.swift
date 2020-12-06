import Vapor
import Leaf
import MongoKitten
import Twilio
import JWTKit
import Fluent
import FluentMongoDriver


// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.views.use(.leaf)

    var connectionString: String
    switch app.environment {
    case .production:
        guard let mongoURL = Environment.get("MONGO_DB_PRO") else {
            fatalError("No MongoDB connection string is available in .env_production")
        }
        connectionString = mongoURL
    case .development:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("No MongoDB connection string is available in .env_development")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
    default:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("No MongoDB connection string is available in .env_development")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
    }

    try app.initializeMongoDB(connectionString: connectionString)
    try app.databases.use(.mongo(
        connectionString: connectionString
    ), as: .mongo)

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
        app.http.server.configuration.port = 3030
        app.http.server.configuration.hostname = "0.0.0.0"
    default:
        app.http.server.configuration.port = 3030
        app.http.server.configuration.hostname = "0.0.0.0"
    }
  
    // app.http.server.configuration.supportVersions = [.two]

    try routes(app)
    try boot(app)
}
