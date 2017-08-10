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

public func initialize() throws {
    manager.load(file: "config.json", relativeFrom: .project)
           .load(.environmentVariables)

    port = manager.port

    try setupSwiftMetrics(endpoint: router)
    
    setupDatabase(with: manager)
    
    setupRoutes(for: router)
}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}

fileprivate func setupSwiftMetrics(endpoint: Router) throws {
    let sm = try SwiftMetrics()
    let _ = try SwiftMetricsDash(swiftMetricsInstance : sm, endpoint: endpoint)
}

fileprivate func setupDatabase(with manager: ConfigurationManager) {
    let cloudantConfig = CloudantConfig(manager: manager)
    
    let couchDBConnProps = ConnectionProperties(host:     cloudantConfig.host,
                                                port:     cloudantConfig.port,
                                                secured:  cloudantConfig.secured,
                                                username: cloudantConfig.username,
                                                password: cloudantConfig.password )
    
    couchDBClient = CouchDBClient(connectionProperties: couchDBConnProps)
    
    guard let database = couchDBClient?.database(cloudantConfig.databaseName) else {
        Log.error("No CouchDB client")
        return
    }
    
    todoMapper = TodoMapper(database: database)
}
