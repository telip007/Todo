import Foundation
import Kitura
import LoggerAPI
import Health
import Configuration
import SwiftMetrics
import SwiftMetricsDash
import CouchDB

public let router = Router()
public let manager = ConfigurationManager()
public var port: Int = 8080

internal var couchDBClient: CouchDBClient?
internal var todoMapper: TodoMapper?

fileprivate let dbName: String = "todo_db"

public func initialize() throws {

    manager.load(file: "config.json", relativeFrom: .project)
           .load(.environmentVariables)

    port = manager.port

    let sm = try SwiftMetrics()
    let _ = try SwiftMetricsDash(swiftMetricsInstance : sm, endpoint: router)

    setupDatabase()
    
    setupRoutes(for: router)
}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}

fileprivate func setupDatabase() {
    let cloudantConfig = CloudantConfig(manager: manager)
    
    let couchDBConnProps = ConnectionProperties(host:     cloudantConfig.host,
                                                port:     cloudantConfig.port,
                                                secured:  cloudantConfig.secured,
                                                username: cloudantConfig.username,
                                                password: cloudantConfig.password )
    
    couchDBClient = CouchDBClient(connectionProperties: couchDBConnProps)
    
    guard let database = couchDBClient?.database(dbName) else {
        Log.error("No CouchDB client")
        return
    }
    
    todoMapper = TodoMapper(database: database)
}
