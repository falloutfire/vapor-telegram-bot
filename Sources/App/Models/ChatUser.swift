//
//  ChatUser.swift
//
//
//  Created by Ilya Likhachev on 04.01.2024.
//

import Fluent
import Vapor

final class ChatUserModel: Model, Content {

    static let schema = "chatusers"
    
    @ID
    var id: UUID?

    init() {}

    @Parent(key: "chatID")
    var chat: ChatModel

    @Field(key: "tgIdentifier")
    var tgIdentifier: String
    
    init(id: UUID? = nil, tgIdentifier: String, chatID: ChatModel.IDValue) {
        self.id = id
        self.tgIdentifier = tgIdentifier
        self.$chat.id = chatID
    }
}
