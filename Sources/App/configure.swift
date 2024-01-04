import Vapor
import TelegramVaporBot
import Leaf
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    if let dbURLString = Environment.get("DATABASE_URL"),
    let url = URL(string: dbURLString) {
        configureDatabase(with: url, for: app)
    } else {
        configureLocalDatabase(for: app)
    }
    
    app.migrations.add(CreateChat())
    app.migrations.add(CreateChatUsers())

    // register routes
    let tgApi: String = Environment.get("TELEGRAM_BOT_TOKEN") ?? ""
        /// set level of debug if you needed
    TGBot.log.logLevel = app.logger.logLevel
    let bot: TGBot = .init(app: app, botId: tgApi)
    await TGBOT.setConnection(try await TGLongPollingConnection(bot: bot))
    // await TGBOT.setConnection(try await TGWebHookConnection(bot: bot, webHookURL: "https://127.0.0.1:8080/telegramWebHook"))
    // await DefaultBotHandlers.addHandlers(app: app, connection: TGBOT.connection)
    await RegisterUserBotHandlers.addHandlers(app: app, connection: TGBOT.connection)
    try await TGBOT.connection.start()
    
    app.http.server.configuration.hostname = "0.0.0.0"

    if let port = Environment.get("PORT").flatMap(Int.init) {
       app.http.server.configuration.port = port
    }

    if app.environment == .development {
       app.logger.logLevel = .debug
    }

    try await app.autoMigrate().get()

    app.views.use(.leaf)

    try routes(app)
}

func configureDatabase(with url: URL, for app: Application) {
  // 2
    guard let host = url.host, let user = url.user else {
        return
    }

    var configuration = TLSConfiguration.makeClientConfiguration()
    configuration.certificateVerification = .none

    let db = url.path.split(separator: "/").last.flatMap(String.init)
    app.databases.use(.postgres(configuration: .init(hostname: host,
                                                   username: user,
                                                   password: url.password,
                                                   database: db,
                                                   tlsConfiguration: configuration)), as: .psql)

    if let db = db {
        app.logger.info("Using Postgres DB \(db) at \(host)")
    }
}

func configureLocalDatabase(for app: Application) {
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
}
