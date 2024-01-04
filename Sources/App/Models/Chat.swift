//
//  Chat.swift
//  
//
//  Created by Ilya Likhachev on 04.01.2024.
//

import Fluent
import Vapor

final class ChatModel: Model, Content {

    static let schema = "chats"
    
    @ID
    var id: UUID?

    @Field(key: "tgIdentifier")
    var tgIdentifier: String

    init() {}

    @Children(for: \.$chat)
    var users: [ChatUserModel]

    init(id: UUID? = nil, tgIdentifier: String) {
       self.tgIdentifier = tgIdentifier
    }
}
