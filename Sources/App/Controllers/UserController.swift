//
//  UserController.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten
import AddaAPIGatewayModels

final class UserController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get(":usersId", use: find)
        routes.put(":usersId", use: update)
    }

    private func find(_ req: Request) throws -> EventLoopFuture<User> {
        guard let _id = req.parameters.get("\(User.schema)Id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        return User.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { $0 }
            
            // req.mongoDB[User.schema].findOne("_id" == id, as: User.self)
            //.unwrap(or: Abort(.notFound))
    }

    private func update(_ req: Request) throws -> EventLoopFuture<User> {
        guard let _id = req.parameters.get("\(User.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        let data = try req.content.decode(User.self)

        let encoder = BSONEncoder()
        let encoded: Document = try encoder.encode(data)
        let updator: Document = ["$set": encoded]

        return req.mongoDB[User.schema].updateOne(where: "_id" == id, to: updator).map { _ in
            return data
        }
    }

}
