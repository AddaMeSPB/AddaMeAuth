import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.routes.register(collection: AuthController())
    
    try app.group("v1") { api in
        let users = app.grouped("users")
        let usersAuth = users.grouped(JWTMiddleware())
        try usersAuth.register(collection: UserController() )
    }
}
