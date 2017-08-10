//
//  TodoMapper.swift
//  todoApp
//
//  Created by Talip Göksu on 09.08.17.
//
//

import Foundation
import Kitura
import CouchDB
import LoggerAPI
import SwiftyJSON

enum MapperResult<T> {
    case success(T)
    case failure(Error?)
}

internal typealias ResultBlock<T> = (MapperResult<T>) -> Void

class TodoMapper {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func getAll(completionHandler: @escaping ResultBlock<[Todo]>) {
        database.queryByView("all_todos", ofDesign: "main_design", usingParameters: [.descending(true)]) { (result: JSON?, error: NSError?) in
            if let result = result {
                if let list = result["rows"].array {
                    let todos: [Todo] = list.map ({
                        let data = $0["value"]
                        return Todo(id: data["_id"].stringValue, title: data["title"].stringValue, createdAt: data["createdAt"].uIntValue, updatedAt: data["updatedAt"].uIntValue)
                    })
                    completionHandler(.success(todos))
                    return
                }
                completionHandler(.failure(nil))
                return
            }
            completionHandler(.failure(error))
        }
    }
    
    func getTodo(by id: String, completionHandler: @escaping ResultBlock<Todo>) {
        database.retrieve(id) { (result: JSON?, error: Error?) in
            if let result = result {
                let todo = Todo(id: result["_id"].stringValue, title: result["title"].stringValue, createdAt: result["createdAt"].uIntValue, updatedAt: result["updatedAt"].uIntValue)
                completionHandler(.success(todo))
                return
            }
            completionHandler(.failure(error))
        }
    }
    
    func create(json: JSON, completionHandler: @escaping ResultBlock<Todo>) {
        guard let title = json["title"].string,
            let createdAt = json["createdAt"].uInt,
            let updatedAt = json["updatedAt"].uInt else { completionHandler(.failure(nil)); return }
        let todoJson = JSON([
            "type": Todo.type,
            "title": title,
            "createdAt": createdAt,
            "updatedAt": updatedAt
            ])
        
        database.create(todoJson) { (id, revision, document, error) in
            if let id = id {
                Log.info("Todo \(title) created with id: \(id)")
                let todo = Todo(id: "\(id)", title: title, createdAt: createdAt, updatedAt: updatedAt)
                completionHandler(.success(todo))
                return
            }
            Log.error("Oops something went wrong; could not create todo.")
            completionHandler(.failure(error))
        }
    }
    
}
