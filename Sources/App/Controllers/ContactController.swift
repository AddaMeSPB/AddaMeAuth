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
  
  func create(_ req: Request) throws -> EventLoopFuture<[Contact.ReqRes]> {
    if req.loggedIn == false { throw Abort(.unauthorized) }
    
    let inputData = try req.content.decode([Contact.ReqRes].self)
    
    return Contact.query(on: req.db).filter(\.$user.$id == req.payload.userId).all().flatMap { contactsRes in
      let contacts = contactsRes.map { $0.response }
      
      let setOriginal = Set(inputData)
      let setServerContacts = Set(contacts)
      let uniqServer = setOriginal.subtracting(setServerContacts)
      let uniqOrg = setServerContacts.subtracting(setOriginal)
      
      if uniqServer.isEmpty && uniqOrg.isEmpty {
        return Contact.query(on: req.db)
          .filter(\.$user.$id == req.payload.userId)
          .filter(\.$isRegister == true)
          .all()
          .map { return $0.map { return $0.response } }
      }
      
      let newContacts = uniqServer.isEmpty ? uniqOrg : uniqServer
      
      let results = newContacts.compactMap { (contact: Contact.ReqRes) -> EventLoopFuture<Contact.ReqRes> in
        
        return User.query(on: req.db)
          .filter(\.$phoneNumber == contact.phoneNumber)
          .all()
          .flatMap { users -> EventLoopFuture<Contact.ReqRes> in
            
            let user = users.first == nil ? User(phoneNumber: "") : users.first!
            
            let contact = Contact(
              phoneNumber: contact.phoneNumber,
              identifier: contact.identifier ?? "",
              fullName: contact.fullName,
              avatar: user.attachments.last?.imageUrlString,
              isRegister: user.phoneNumber == contact.phoneNumber,
              userId: contact.userId
            )
            
            return contact.save(on: req.db).transform(to: contact.response) //.map { _ in contact }
            
          }
        
      }
      
      return results.flatten(on: req.eventLoop)
      
    }
  }
  
}
