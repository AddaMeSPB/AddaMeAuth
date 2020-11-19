//
//  AttachmentController.swift
//  
//
//  Created by Saroar Khandoker on 19.11.2020.
//

import Vapor
import MongoKitten
import AddaAPIGatewayModels
import Fluent

extension AttachmentController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.post(use: create)
    routes.delete(use: delete)
  }
}

final class AttachmentController {
  func create(_ req: Request) throws -> EventLoopFuture<Attachment.ReqRes> {
    if req.loggedIn == false { throw Abort(.unauthorized) }
    
    let inputData = try req.content.decode(Attachment.ReqRes.self)
    
    let attachment = Attachment(type: inputData.type, userId: inputData.userId, imageUrlString: inputData.imageUrlString, audioUrlString: inputData.audioUrlString, videoUrlString: inputData.videoUrlString, fileUrlString: inputData.fileUrlString)
    
    return attachment.save(on: req.db).map { _ in attachment.response }
  }
  
  private func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
      if req.loggedIn == false { throw Abort(.unauthorized) }

      guard let _id = req.parameters.get("\(Attachment.schema)Id"), let id = ObjectId(_id) else {
          return req.eventLoop.makeFailedFuture(Abort(.notFound))
      }

      return Attachment.query(on: req.db)
          .filter(\.$id == id)
          .filter(\.$user.$id == req.payload.userId)
          .first()
          .unwrap(or: Abort(.notFound, reason: "No Attachment. found! by ID \(id)"))
          .flatMap { $0.delete(on: req.db) }
          .map { .ok }
  }
}
