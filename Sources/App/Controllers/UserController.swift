//
//  UserController.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten

final class UserController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get(":users_id", use: show)
        routes.put(":users_id", use: update)
    }

    private func show(_ req: Request) throws -> EventLoopFuture<User> {
        guard let _id = req.parameters.get("\(User.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        return req.mongodb[User.schema].findOne("_id" == id, as: User.self)
            .unwrap(or: Abort(.notFound))
    }

    private func update(_ req: Request) throws -> EventLoopFuture<User> {
        guard let _id = req.parameters.get("\(User.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        let data = try req.content.decode(User.Req.self)

        let encoder = BSONEncoder()
        let encoded: Document = try encoder.encode(data)
        let updator: Document = ["$set": encoded]

        return req.mongodb[User.schema].updateOne(where: "_id" == id, to: updator).map { _ in
            return User(data)
        }
    }

}
