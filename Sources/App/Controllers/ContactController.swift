//
//  ContactsController.swift
//  
//
//  Created by Saroar Khandoker on 12.11.2020.
//

import Vapor
import MongoKitten
import AddaAPIGatewayModels
import Fluent

extension ContactController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.postBigFile(use: getRegisterContacts)
  }
}

class ContactController {
  
  func getRegisterContacts(_ req: Request) throws -> EventLoopFuture<[User.Response]> {
    if req.loggedIn == false { throw Abort(.unauthorized) }
    
    let contacts = try req.content.decode([Contact.ReqRes].self)
    let phoneNumbers: [String] = contacts.map { return $0.phoneNumber }

    return User.query(on: req.db)
      .with(\.$attachments)
      .filter(\.$phoneNumber ~~ phoneNumbers)
      .all().map { return $0.map { $0.response } }
  }
  
}
