import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.group("v1") { api in
        try api.register(collection: AuthController())

        let users = api.grouped("users")
        let usersAuth = users.grouped(JWTMiddleware())
        try usersAuth.register(collection: UserController() )
    }

}
