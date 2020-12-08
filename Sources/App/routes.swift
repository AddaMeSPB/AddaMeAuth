import Vapor
import Leaf

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
    
    let contacts = api.grouped("contacts")
    let contactsAuth = contacts.grouped(JWTMiddleware())
    try contactsAuth.register(collection: ContactController() )
    
    let attachments = api.grouped("attachments")
    let attachmentsAuth = attachments.grouped(JWTMiddleware())
    try attachmentsAuth.register(collection: AttachmentController())
    
    let device = api.grouped("devices")
    let devicesAuth = device.grouped(JWTMiddleware())
    try devicesAuth.register(collection: DeviceController() )
  }
  
}
