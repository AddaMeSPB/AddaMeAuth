//
//  UserController.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten
import AddaAPIGatewayModels
import Fluent

final class UserController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get(":usersId", use: find)
        routes.put(use: update)
    }

  private func find(_ req: Request) throws -> EventLoopFuture<User.Response> {
        guard let _id = req.parameters.get("\(User.schema)Id"),
              let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(
                Abort(.notFound, reason: "\(#line) parameters user id is missing")
            )
        }

      return User.query(on: req.db)
        .with(\.$attachments)
        .filter(\.$id == id)
        .first()
        .unwrap(or: Abort(.notFound))
        .map { return $0.response }
    }

  private func update(_ req: Request) throws -> EventLoopFuture<User.Response> {
      
      let data = try req.content.decode(User.Response.self)

        let encoder = BSONEncoder()
        let encoded: Document = try encoder.encode(data)
        let updator: Document = ["$set": encoded]

        return req.mongoDB[User.schema]
          .updateOne(where: "_id" == data.id!, to: updator)
            .map { _ in return data }
    }

}
