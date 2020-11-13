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
    routes.postBigFile(use: create)
  }
}

class ContactController {
  func create(_ req: Request) throws -> EventLoopFuture<[Contact]> {
    if req.loggedIn == false { throw Abort(.unauthorized) }
    
    let inputData = try req.content.decode([CreateContact].self)
    
    let results =  inputData.map { ccontact -> EventLoopFuture<Contact> in
      
      return User.query(on: req.db)
        .filter(\.$phoneNumber == ccontact.phoneNumber)
        .all()
        .flatMap { users -> EventLoopFuture<Contact> in
          
          let user = users.first == nil ? User(phoneNumber: "") : users.first!

          let contact = Contact(
            phoneNumber: ccontact.phoneNumber,
            identifier: ccontact.identifier ?? "" ,
            fullName: ccontact.fullName,
            avatar: user.avatar,
            isRegister: user.phoneNumber == ccontact.phoneNumber,
            userId: ccontact.userId
          )
          
          return contact.save(on: req.db).transform(to: contact) //.map { _ in contact }
          
        }
    }
    
    return results.flatten(on: req.eventLoop)
    
  }
  
}
