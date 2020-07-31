//
//  DatabaseManager.swift
//  iSpread
//
//  Created by Alex Koiv on 7/25/20.
//  Copyright © 2020 Alex Koiv. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()

    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
            ], withCompletionBlock: {error, _ in
                guard error == nil else {
                    print("Failed to write to database")
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        // append to user dictionary
                        let newElement = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: {
                            error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                        
                    }
                    else {
                        // create array
                        let newCollection: [[String: String]] = [
                            ["name": user.firstName + " " + user.lastName,
                             "email": user.safeEmail
                            ]
                        ]
                        self.database.child("users").setValue(newCollection, withCompletionBlock: {
                            error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                })
                
                completion(false)
        })
    }
}

public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
    database.child("users").observeSingleEvent(of: .value, with: {snapshot in
        guard let value = snapshot.value as? [[String: String]] else {
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
        completion(.success(value))
    })
}

public enum DatabaseError: Error {
    case failedToFetch
}

/*
 users => [
    [
        "name":
        "safe_email":
    ],
    [
        "name":
        "safe_email":
    ]
 ]
 */


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePicturFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}
