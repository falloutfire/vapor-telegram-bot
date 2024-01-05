//
//  RegisterUserBotHandlers.swift
//
//
//  Created by Ilya Likhachev on 04.01.2024.
//

import Foundation
import Vapor
import TelegramVaporBot
import FluentKit

final class RegisterUserBotHandlers {

    private static var registerUserInChats: [String: Set<String>] = [:]
    
    static func addHandlers(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await commandRegisterUserHandler(app: app, connection: connection)
        await commandPlayerUsersHandler(app: app, connection: connection)
        await commandPlayGameUserHandler(app: app, connection: connection)
    }

    private static func commandRegisterUserHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/register"]) { 
            update, bot in
            guard let userId = update.message?.from?.id else {
                app.logger.info("Cannot get userId")
                return
            }
            guard let chatId = update.message?.chat.id else {
                app.logger.info("Cannot get chatId")
                return
            }
            let stringChatId = String(chatId)
            let stringUserId = String(userId)

            guard let chatModel = try? await getChatOrCreateChat(app: app, chatId: stringChatId) else {
                app.logger.info("Cannot get or save chat")
                return
            }
            
            guard let savedUser = try? await getChatOrCreateUser(app: app, chat: chatModel, userId: stringUserId) else {
                app.logger.info("Cannot get or save user")
                return
            }
            let members = try await getMembersFromDb(app: app, bot: bot, chatId: chatId)
            let text = await getStringListMembers(members: members, prefixText: "Вы успешно зарегестрированы!\n\n")

            let params: TGSendMessageParams = .init(chatId: .chat(chatId), text: text)
            try await bot.sendMessage(params: params)
        })
    }

    static func getChatOrCreateChat(app: Vapor.Application, chatId: String) async throws -> ChatModel? {
        let chatModel: ChatModel?
        if let model = try? await ChatModel.query(on: app.db).filter(\.$tgIdentifier == chatId).first() {
            chatModel = model
        } else {
            chatModel = try? await createChat(app: app, chatId: chatId)
        }
        return chatModel
    }
    
    static func createChat(app: Vapor.Application, chatId: String) async throws -> ChatModel? {
        let model = ChatModel(tgIdentifier: chatId)
        return try? await model.save(on: app.db).map { model }.get()
    }

    static func createChatUser(app: Vapor.Application, chat: ChatModel, userId: String) async throws -> ChatUserModel? {
        let chatID = try chat.requireID()
        let model = ChatUserModel(tgIdentifier: userId, chatID: chatID)
        return try? await model.save(on: app.db).map { model }.get()
    }

    static func getChatOrCreateUser(app: Vapor.Application, chat: ChatModel, userId: String) async throws -> ChatUserModel? {
        guard let chatId = chat.id else { return nil }
        let chatUserModel = try? await ChatUserModel.query(on: app.db)
            .group(.and) { q in
                q.filter(\.$tgIdentifier == userId)
                q.filter(\.$chat.$id == chatId)
            }
            .first()

        if let chatUserModel = chatUserModel {
            return chatUserModel
        } else {
            return try? await createChatUser(app: app, chat: chat, userId: userId)
        }
    }

    static func getAllChatUsers(app: Vapor.Application, chat: ChatModel) async throws -> [ChatUserModel]? {
        try? await ChatUserModel.query(on: app.db).filter(\.$chat.$id == chat.requireID()).all()
    }

    private static func commandPlayerUsersHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/players"]) {
            update, bot in
            guard let chatId = update.message?.chat.id else { fatalError("chat id not found") }

            let members = try await getMembersFromDb(app: app, bot: bot, chatId: chatId)
            let text = await getStringListMembers(members: members)

            let params: TGSendMessageParams = .init(chatId: .chat(chatId), text: text)
            try await bot.sendMessage(params: params)
        })
    }

    private static func commandPlayGameUserHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/pups"]) {
            update, bot in
            guard let chatId = update.message?.chat.id else { fatalError("chat id not found") }

            let members = try await getMembersFromDb(app: app, bot: bot, chatId: chatId)
            guard !members.isEmpty, let randomMember = members.shuffled().first else { return }
            var name: String
            if let username = randomMember.user.username {
                name = "@\(username)"
            } else {
                name = "\(randomMember.user.firstName + " " + (randomMember.user.lastName ?? ""))"
            }
            let text = "И пупсик этого дня - \(name)"

            let params: TGSendMessageParams = .init(chatId: .chat(chatId), text: text)
            try await bot.sendMessage(params: params)
        })
    }

    private static func getMembersFromDb(
        app: Vapor.Application,
        bot: TGBot,
        chatId: Int64
    ) async throws -> [TGChatMember] {
        var members: [TGChatMember] = []
        let stringChatId = String(chatId)
        if
            let chatModel = try? await ChatModel.query(on: app.db).filter(\.$tgIdentifier == stringChatId).first(),
            let users = try? await getAllChatUsers(app: app, chat: chatModel)
        {
            for i in users {
                if let id = Int64(i.tgIdentifier) {
                    let chatMemberParam = TGGetChatMemberParams(chatId: .chat(chatId), userId: id)
                    if let safeMember = try? await bot.getChatMember(params: chatMemberParam) {
                        members.append(safeMember)
                    }
                }
            }
        }
        return members
    }

    private static func getStringListMembers(members: [TGChatMember], prefixText: String? = nil) async -> String {
        var text = prefixText ?? ""
        text.append("Текущие участники: ")
        
        for (index, member) in members.enumerated() {
            let name = member.user.username ?? member.user.firstName + (member.user.lastName ?? "")
            text.append("\n\(index + 1). \(name)")
        }
        return text
    }
}
