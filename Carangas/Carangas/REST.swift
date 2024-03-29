//
//  REST.swift
//  Carangas
//
//  Created by Luan Arruda on 21/11/23.
//  Copyright © 2023 Eric Brito. All rights reserved.
//

import Foundation

enum ErrorAPI {
    case url
    case taskError(error: Error)
    case noResponse
    case noData
    case responseStatusCode(code: Int)
    case invalidJSON
}

enum RESTOperation{
    case save
    case update
    case delete
}

class REST {
    
    private static let basePath = "https://carangas.herokuapp.com/cars"
    
    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = false
        config.httpAdditionalHeaders = ["Content-Type":"application/json"]
        config.timeoutIntervalForRequest = 30.0
        config.httpMaximumConnectionsPerHost = 5
        return config
    }()
    
    
    
    private static let session = URLSession(configuration: configuration) //URLSession.shared
    
    class func loadCars(onComplete: @escaping ([Car]) -> Void, onError: @escaping (ErrorAPI) -> Void) {
        guard let url = URL(string: basePath) else {
            onError(.url)
            return
        }
        
        let dataTask = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {
                guard let response = response as? HTTPURLResponse else {
                    onError(.noResponse)
                    return
                }
                if response.statusCode == 200 {
                    guard let data = data else {return}
                    do {
                        let cars = try JSONDecoder().decode([Car].self, from: data)
                        onComplete(cars)
                    } catch {
                        onError(.invalidJSON)
                    }
                } else {
                    onError(.responseStatusCode(code: response.statusCode))
                }
            } else {
                onError(.taskError(error: error!))
            }
        }
        dataTask.resume()
    }
    
    class func save(car: Car, onComplete: @escaping (Bool) -> Void, onError: @escaping (ErrorAPI) -> Void){
        applyOperation(car: car, operation: .save, onComplete: onComplete, onError: onError)
    }
    
    class func update(car: Car, onComplete: @escaping (Bool) -> Void, onError: @escaping (ErrorAPI) -> Void){
        applyOperation(car: car, operation: .update, onComplete: onComplete, onError: onError)
    }
    
    class func delete(car: Car, onComplete: @escaping (Bool) -> Void, onError: @escaping (ErrorAPI) -> Void){
        applyOperation(car: car, operation: .delete, onComplete: onComplete, onError: onError)
    }
    
    private class func applyOperation(car: Car, operation: RESTOperation, onComplete: @escaping (Bool) -> Void, onError: @escaping (ErrorAPI) -> Void){
        guard let url = URL(string: "\(basePath)/\(car._id ?? "" )") else {
            onError(.url)
            return
        }
    
        var request = URLRequest(url: url)
        
        var httpMethod = ""
        switch operation {
        case .save:
            httpMethod = "POST"
        case .update:
            httpMethod = "PUT"
        case .delete:
            httpMethod = "DELETE"
        }
        request.httpMethod = httpMethod
        
        do{
            let jsonData = try JSONEncoder().encode(car)
            request.httpBody = jsonData
        } catch {
            onError(.invalidJSON)
        }
        
        let dataTask = session.dataTask(with: request) { data, response, error in
            if error == nil {
                guard let response = response as? HTTPURLResponse else {
                    onError(.noResponse)
                    return
                }
                if response.statusCode == 200 {
                    onComplete(true)
                } else {
                    onError(.responseStatusCode(code: response.statusCode))
                }
            } else {
                onError(.taskError(error: error!))
            }
        }
        dataTask.resume()
    }
    
    

}


