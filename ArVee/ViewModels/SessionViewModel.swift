import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var sessionId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var transactions: [InputRow] = []
    @Published var proofs: [InputRow] = []

    private let api = APIService.shared

    var hasSession: Bool { sessionId != nil }

    func createSession() async {
        isLoading = true
        errorMessage = nil
        do {
            let id = try await api.createSession()
            sessionId = id
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadSession(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await api.loadSessionInputs(sessionId: id)
            sessionId = response.sessionId
            transactions = response.transactions
            proofs = response.proofs
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func clear() {
        sessionId = nil
        transactions = []
        proofs = []
        errorMessage = nil
    }
}
