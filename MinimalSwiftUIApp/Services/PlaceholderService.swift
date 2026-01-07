//
//  PlaceholderService.swift
//  MinimalSwiftUIApp
//
//  Services coordinate external interactions (networking, OS APIs, etc.).
//  Keep implementations small and testable; wire them through dependency injection later.
//

import Foundation

protocol PlaceholderService {
    func ping() async throws
}

