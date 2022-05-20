import SwiftUI
import CardlayUI

struct MFAEnrollmentRequirement {
    let mfaToken: String
}

struct MFAChallengeRequirement {
    let mfaToken: String
    let bindingCode: String
}

struct Session {
    let accessToken: String
    let refreshToken: String
}

struct Card {
    let id: String
    let number: String
}

struct CardTransaction {
    let id: String
    let merchant: String
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct AccountView: View {
    var profile: () -> Void = {}
    var terminatedCards: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Account")
                .padding()
            
            Button("Profile", action: profile)
                .padding()
            
            Button("Terminated Cards", action: terminatedCards)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProfileView: View {
    var signOut: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Profile")
                .padding()
            
            Button("Sign out", action: signOut)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TerminatedCardsView: View {
    var terminatedCardDetails: (CardDetailViewModel) -> Void = { _ in }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Terminated Cards")
                .padding()
            
            Button("Terminated Card Details") {
//                terminatedCardDetails(Card(id: "terminated-card-1", number: "0000 1111"))
                terminatedCardDetails(CardDetailViewModel(cardId: "terminated-card-1"))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TerminatedCardDetailsView: View {
    @ObservedObject var viewModel: CardDetailViewModel
    
    var transaction: (TransactionDetailViewModel) -> Void = { _ in }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Terminated Card Details")
                .padding()
            
            Button("Transaction") {
//                transaction(CardTransaction(id: UUID().uuidString, merchant: "TERMINATED"))
                transaction(TransactionDetailViewModel(cardId: viewModel.cardId, transactionId: UUID().uuidString))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HomeView: View {
    let session: Session
    
    var requestCard: () -> Void = {}
    var card: (CardDetailViewModel) -> Void = { _ in }
    var cardTransaction: (CardDetailViewModel, TransactionDetailViewModel) -> Void = { _, _ in }
    var terminatedCardTransaction: (CardDetailViewModel, TransactionDetailViewModel) -> Void = { _, _ in }
    var account: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Home")
                .padding()
            
            Button("Request Card", action: requestCard)
                .padding()
            
            Button("Card") {
//                card(Card(id: "card-1", number: "1234 5678"))
                card(CardDetailViewModel(cardId: "card-1"))
            }
            .padding()
            
            Button("Transaction") {
//                cardTransaction(
//                    Card(id: "card-1", number: "1234 5678"),
//                    CardTransaction(id: UUID().uuidString, merchant: "IKEA ODENSE")
//                )
                
                cardTransaction(
                    CardDetailViewModel(cardId: "card-1"),
                    TransactionDetailViewModel(cardId: "card-1", transactionId: UUID().uuidString)
                )
            }
            .padding()
            
            Button("Terminated Card Transaction (Deep)") {
//                terminatedCardTransaction(Card(id: "terminated-card-1", number: "0000 1111"), CardTransaction(id: UUID().uuidString, merchant: "TERM"))
                terminatedCardTransaction(
                    CardDetailViewModel(cardId: "terminated-card-1"),
                    TransactionDetailViewModel(cardId: "terminated-card-1", transactionId: UUID().uuidString)
                )
            }
            .padding()
            
            Button("Account", action: account)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }
}

class CardDetailViewModel: ObservableObject {
    @Published private(set) var cardId: String
    
    @Published private(set) var cardNumber: String = ""
    
    init(cardId: String) {
        self.cardId = cardId
        self.cardNumber = "card-number \(cardId)"
    }
}

class TransactionDetailViewModel: ObservableObject {
    @Published private(set) var cardId: String
    @Published private(set) var transactionId: String
    
    @Published private(set) var merchant: String = ""
    
    init(cardId: String, transactionId: String) {
        self.cardId = cardId
        self.transactionId = transactionId
        self.merchant = "Merchant \(transactionId)"
    }
}

struct TransactionDetailsView: View {
    @ObservedObject var viewModel: TransactionDetailViewModel
    
    var root: () -> Void = {}
    var other: (Card, CardTransaction) -> Void = { _, _ in }
    var comment: () -> Void = {}
    var addAttachment: () -> Void = {}
    var viewAttachment: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Transaction Details (\(viewModel.transactionId))")
                .padding()
            
            Text(viewModel.merchant)
                .padding()
            
            Button("Root", action: root)
                .padding()
            
            Button("Other Transaction") {
                other(Card(id: "abc-12", number: "1234 abc"), CardTransaction(id: UUID().uuidString, merchant: "ODENSE GOKART HAL"))
            }
            .padding()
            
            Button("Comment", action: comment)
                .padding()
            
            Button("Add attachment", action: addAttachment)
                .padding()
            
            Button("View attachment", action: viewAttachment)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CardDetailsView: View {
    @ObservedObject var viewModel: CardDetailViewModel
    
    let transaction: (TransactionDetailViewModel) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Card Details")
                .padding()
            
            Button("Transaction Details") {
//                transaction(CardTransaction(id: UUID().uuidString, merchant: "IKEA ODENSE"))
                transaction(TransactionDetailViewModel(cardId: viewModel.cardId, transactionId: UUID().uuidString))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }
}

struct BiometricPromptView: View {
    let signedIn: (Session) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Biometrics Prompt")
                .padding()
            
            Button("Allow") {
                signedIn(Session(accessToken: "access-token", refreshToken: "refresh-token"))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PersonalDetailsView: View {
    enum Output {
        case session(Session)
        case biometricsPrompt
    }
    
    let confirmed: (Output) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Personal Details")
                .padding()
            
            Button("Confirm (Biometric Prompt)") {
                confirmed(.biometricsPrompt)
            }
            .padding()
            
            Button("Confirm (Session)") {
                confirmed(.session(Session(accessToken: "access-token", refreshToken: "refresh-token")))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StartView: View {
    let signIn: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Start")
                .padding()
            
            Button("Sign in online") {
                signIn()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoginView: View {
    enum Output {
        case mfaEnrollment(MFAEnrollmentRequirement)
        case mfaChallenge(MFAChallengeRequirement)
        case personalDetails
        case biometricPrompt
        case session(Session)
    }
    
    let signedIn: (Output) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Login")
                .padding()
            
            Button("Sign in (Enrollment)") {
                signedIn(.mfaEnrollment(MFAEnrollmentRequirement(mfaToken: "mfa-token")))
            }
            .padding()
            
            Button("Sign in (Challenge)") {
                signedIn(.mfaChallenge(MFAChallengeRequirement(mfaToken: "mfa-token", bindingCode: "binding-code")))
            }
            .padding()
            
            Button("Sign in (Personal Details)") {
                signedIn(.personalDetails)
            }
            .padding()
            
            Button("Sign in (Biometric Prompt)") {
                signedIn(.biometricPrompt)
            }
            .padding()
            
            Button("Sign in (Session)") {
                signedIn(.session(Session(accessToken: "access-token", refreshToken: "refresh-token")))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MFAEnrollmentView: View {
    let requirement: MFAEnrollmentRequirement
    
    let challenge: (MFAChallengeRequirement) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("MFA Enrollment")
                .padding()
            
            Button("Enroll") {
                challenge(MFAChallengeRequirement(mfaToken: "actual-mfa-token", bindingCode: "actual-binding-code"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MFAChallengeView: View {
    let challenge: MFAChallengeRequirement
    
    let passed: (MFAEnrollmentFlow.Output) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("MFA Challenge")
                .padding()
            
            Button("Pass (Personal Details)") {
                passed(.personalDetails)
            }
            .padding()
            
            Button("Pass (Biometric Prompt)") {
                passed(.biometricPrompt)
            }
            .padding()
            
            Button("Pass (Session)") {
                passed(.session(Session(accessToken: "access-token", refreshToken: "refresh-token")))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CommentView: View {
    let success: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Comment")
                .padding()
            
            Button("Save") {
                success("the comment")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AttachmentView: View {
    let delete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Attachment")
                .padding()
            
            Button("Delete") {
                delete()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AddAttachmentView: View {
    let success: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Add Attachment")
                .padding()
            
            Button("Save") {
                success()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RequestCardAmountView: View {
    @Binding var amount: String?
    
    let advance: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Amount")
                .padding()
            
            Button("Continue") {
                amount = "12"
                advance()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RequestCardPurposeView: View {
    @Binding var purpose: String?
    
    let advance: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Purpose")
                .padding()
            
            Button("Continue") {
                purpose = "Beers"
                advance()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RequestCardSummaryView: View {
    let amount: String
    let purpose: String
    
    let submit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Summary")
                .padding()
            
            Text("Amount: \(amount)")
                .padding()
            
            Text("Purpose: \(purpose)")
                .padding()
            
            Button("Submit") {
                submit()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
