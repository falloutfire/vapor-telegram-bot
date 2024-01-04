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
    
//    func getAllEmployees(_ req: Request) async throws -> [Person] {
//      // 1
//      let employees = try await Person
//        .query(on: req.db)
//         // 2
//        // .join(parent: \.$company, method: .inner)
//        .join(parent: \.$company, method: .inner)
//        .all()
//
//      // 3
//      for employee in employees {
//        employee.$company.value = try employee.joined(Company.self)
//      }
//
//      // 4
//      return employees
//    }

    private static func commandRegisterUserHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/register"]) { 
            update, bot in
            guard let userId = update.message?.from?.id else { return }
            guard let chatId = update.message?.chat.id else { fatalError("chat id not found") }
            let stringChatId = String(chatId)
            let stringUserId = String(userId)

            let chatModel: ChatModel
            let models = try await ChatModel.query(on: app.db).filter(\.$tgIdentifier == stringChatId).all()
            if let value = models.first {
                chatModel = value
            } else {
                chatModel = try await createChat(app: app, chatId: stringChatId)
            }
            
            let savedUser = try await createChatUser(app: app, chat: chatModel, userId: stringUserId)

            let members = await getMembersFromDb(app: app, bot: bot, chatId: chatId)
            let text = await getStringListMembers(members: members, prefixText: "Вы успешно зарегестрированы!\n")

            let params: TGSendMessageParams = .init(chatId: .chat(chatId), text: text)
            // try await bot.sendMessage(params: params)
            try await update.message?.reply(text: text, bot: bot)
        })
    }
    
    static func createChat(app: Vapor.Application, chatId: String) async throws -> ChatModel {
        let model = ChatModel(tgIdentifier: chatId)
        return try await model.save(on: app.db).map { model }.get()
    }

    static func createChatUser(app: Vapor.Application, chat: ChatModel, userId: String) async throws -> ChatUserModel {
        let chatID = try chat.requireID()
        let model = ChatUserModel(tgIdentifier: userId, chatID: chatID)
        return try await model.save(on: app.db).map { model }.get()
    }

    static func getAllChatUsers(app: Vapor.Application) async throws -> [ChatUserModel] {
        try await ChatUserModel.query(on: app.db).all()
    }

    private static func commandPlayerUsersHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/players"]) {
            update, bot in
            guard let chatId = update.message?.chat.id else { fatalError("chat id not found") }

            let members = await getMembers(bot: bot, chatId: chatId)
            let text = await getStringListMembers(members: members)

            let params: TGSendMessageParams = .init(chatId: .chat(chatId), text: text)
            try await bot.sendMessage(params: params)
            // try await update.message?.reply(text: "pong", bot: bot)
        })
    }

    private static func commandPlayGameUserHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/pups"]) {
            update, bot in
            guard let chatId = update.message?.chat.id else { fatalError("chat id not found") }

            let members = await getMembersFromDb(app: app, bot: bot, chatId: chatId)
            guard let randomMember = members.shuffled().first else { return }
            let name = randomMember.user.username ?? randomMember.user.firstName + (randomMember.user.lastName ?? "")
            let text = "И пупсик этого дня - @\(name)"

            let params: TGSendMessageParams = .init(chatId: .chat(chatId), text: text)
            try await bot.sendMessage(params: params)
            // try await update.message?.reply(text: "pong", bot: bot)
        })
    }

    private static func getMembersFromDb(app: Vapor.Application, bot: TGBot, chatId: Int64) async -> [TGChatMember] {
        var members: [TGChatMember] = []
        let stringChatId = String(chatId)
        
        let users = try? await getAllChatUsers(app: app)
        
        for i in (users ?? []) {
            if let id = Int64(i.tgIdentifier) {
                let chatMemberParam = TGGetChatMemberParams(chatId: .chat(chatId), userId: id)

                if let safeMember = try? await bot.getChatMember(params: chatMemberParam) { members.append(safeMember) }
            }
        }
        return members
    }

    private static func getMembers(bot: TGBot, chatId: Int64) async -> [TGChatMember] {
        var members: [TGChatMember] = []
        let stringChatId = String(chatId)
        for i in (self.registerUserInChats[stringChatId] ?? []) {
            if let index = Int64(i) { 
                let chatMemberParam = TGGetChatMemberParams(chatId: .chat(chatId), userId: index)

                if let safeMember = try? await bot.getChatMember(params: chatMemberParam) { members.append(safeMember)
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
