//
//  PlaceholderStorage.swift
//  MinimalSwiftUIApp
//
//  Storage contains persistence primitives (Keychain, file storage, UserDefaults, database).
//  Prefer small protocols to keep callers decoupled from specific storage backends.
//

import Foundation

protocol PlaceholderStorage {
    func save() throws
}

