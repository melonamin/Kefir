import SwiftUI

/// A view modifier that shows error alerts from ErrorManager
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorManager: ErrorManager
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorManager.currentError?.title ?? "Error",
                isPresented: $errorManager.showingError,
                presenting: errorManager.currentError
            ) { error in
                if error.isRecoverable {
                    Button("OK") {
                        errorManager.dismissError()
                    }
                } else {
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    /// Adds error alert handling to any view
    func errorAlert(errorManager: ErrorManager) -> some View {
        modifier(ErrorAlertModifier(errorManager: errorManager))
    }
}