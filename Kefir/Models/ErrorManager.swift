import Foundation
import SwiftUI

/// Manages error handling and user feedback
@MainActor
class ErrorManager: ObservableObject {
    @Published var currentError: UserError?
    @Published var showingError = false
    
    /// Represents an error that should be shown to the user
    struct UserError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let isRecoverable: Bool
        let timestamp = Date()
    }
    
    /// Shows an error to the user
    func showError(_ error: Error, title: String = "Error", isRecoverable: Bool = true) {
        let message: String
        
        if let speakerError = error as? SpeakerError {
            message = speakerError.localizedDescription
        } else if let configError = error as? ConfigurationError {
            message = configError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        currentError = UserError(
            title: title,
            message: message,
            isRecoverable: isRecoverable
        )
        showingError = true
    }
    
    /// Shows a connection error with retry option
    func showConnectionError(_ error: Error) {
        showError(
            error,
            title: "Connection Failed",
            isRecoverable: true
        )
    }
    
    /// Shows an operation error
    func showOperationError(_ error: Error, operation: String) {
        showError(
            error,
            title: "\(operation) Failed",
            isRecoverable: true
        )
    }
    
    /// Dismisses the current error
    func dismissError() {
        showingError = false
        currentError = nil
    }
    
    /// Performs an operation with error handling
    func performOperation<T>(
        operation: String,
        action: () async throws -> T
    ) async -> T? {
        do {
            return try await action()
        } catch {
            showOperationError(error, operation: operation)
            return nil
        }
    }
}