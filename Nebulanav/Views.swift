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

protocol OptionalType {
    associatedtype Wrapped
    
    var wrapped: Wrapped? { get }
    
    static var createNil: Self { get }
}

extension Optional: OptionalType {
    var wrapped: Wrapped? { self }
    
    static var createNil: Wrapped? { nil }
}

extension Binding where Value : OptionalType {
    var isActive: Binding<Bool> {
        Binding<Bool>(get: { wrappedValue.wrapped != nil }, set: { newValue in
            if !newValue {
                wrappedValue = .createNil
            }
        })
    }
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
    @EnvironmentObject var router: ApplicationRouter
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Account")
                .padding()
            
            Button("Profile") {
                router.navigate(to: .contact)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProfileView: View {
    @EnvironmentObject var router: ApplicationRouter
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Profile")
                .padding()
            
            Button("Sign out") {
                router.signOut()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TerminatedCardsView: View {
    @EnvironmentObject var router: ApplicationRouter
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Terminated Cards")
                .padding()
            
            Button("Terminated Card Details") {
                router.navigate(to: .terminatedCardDetails(Card(id: "terminated-card-1", number: "0000 1111")))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TerminatedCardDetailsView: View {
    @EnvironmentObject var router: ApplicationRouter
    
    let card: Card
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Terminated Card Details")
                .padding()
            
            Button("Transaction") {
                router.navigate(to: .terminatedCardTransactionDetails(Card(id: "terminated-card-1", number: "0000 1111"), CardTransaction(id: UUID().uuidString, merchant: "TERMINATED")))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HomeScreen: View {
    @EnvironmentObject var router: ApplicationRouter
    
    let session: Session
    
    let signOut: () -> Void
    
    var body: some View {
        HomeView(
            session: session,
            signOut: signOut,
            requestCard: {
                router.presentation = .fullScreenCover(
                    .requestCard {
                        router.presentation = nil
                        print("Card Request submitted")
                    }
                )
            },
            selectCard: {
                router.navigate(to: .cardDetails($0))
            },
            selectTransaction: {
                router.navigate(to: .transactionDetails($0, $1))
            },
            selectTerminatedTransaction: {
                router.navigate(to: .terminatedCardTransactionDetails($0, $1))
            },
            selectAccount: {
                router.navigate(to: .account)
            }
        )
    }
}

struct HomeView: View {
    @EnvironmentObject var router: ApplicationRouter
    
    let session: Session
    
    let signOut: () -> Void
    
    var requestCard: () -> Void = { }
    var selectCard: (Card) -> Void = { _ in }
    var selectTransaction: (Card, CardTransaction) -> Void = { _, _ in }
    var selectTerminatedTransaction: (Card, CardTransaction) -> Void = { _, _ in }
    var selectAccount: () -> Void = { }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Home")
                .padding()
            
            Button("Request Card") {
                requestCard()
            }
            .padding()
            
            Button("Card") {
                selectCard(Card(id: "card-1", number: "1234 5678"))
            }
            .padding()
            
            Button("Transaction") {
                selectTransaction(Card(id: "card-1", number: "1234 5678"), CardTransaction(id: UUID().uuidString, merchant: "IKEA ODENSE"))
            }
            .padding()
            
            Button("Terminated Card Transaction (Deep)") {
                selectTerminatedTransaction(Card(id: "terminated-card-1", number: "0000 1111"), CardTransaction(id: UUID().uuidString, merchant: "TERM"))
            }
            .padding()
            
            Button("Account") {
                selectAccount()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }
}

// Enables swipe-to-dismiss when navigation bar is hidden: https://stackoverflow.com/questions/59921239/hide-navigation-bar-without-losing-swipe-back-gesture-in-swiftui
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

struct TransactionDetailsScreen: View {
    @EnvironmentObject var router: ApplicationRouter
    
    let transaction: CardTransaction
    
    var body: some View {
        TransactionDetailsView(
            transaction: transaction,
            root: {
                router.navigate(to: nil)
            },
            other: {
                router.navigate(to: .transactionDetails($0, $1))
            },
            comment: {
                router.presentation = .fullScreenCover(
                    .comment {
                        router.presentation = nil
                        print("Added comment: \($0)")
                    }
                )
            },
            addAttachment: {
                router.presentation = .fullScreenCover(
                    .addAttachment {
                        router.presentation = nil
                        print("Added attachment")
                    }
                )
            },
            viewAttachment: {
                router.presentation = .fullScreenCover(
                    .attachment {
                        router.presentation = nil
                        print("Deleted attachment")
                    }
                )
            }
        )
    }
}

struct TransactionDetailsView: View {
    let transaction: CardTransaction
    
    var root: () -> Void = { }
    var other: (Card, CardTransaction) -> Void = { _, _ in }
    var comment: () -> Void = { }
    var addAttachment: () -> Void = { }
    var viewAttachment: () -> Void = { }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Transaction Details (\(transaction.id))")
                .padding()
            
            Text(transaction.merchant)
                .padding()
            
            Button("Root") {
                root()
            }
            .padding()
            
            Button("Other Transaction") {
                other(Card(id: "abc-12", number: "1234 abc"), CardTransaction(id: UUID().uuidString, merchant: "ODENSE GOKART HAL"))
            }
            .padding()
            
            Button("Comment") {
                comment()
            }
            .padding()
            
            Button("Add attachment") {
                addAttachment()
            }
            .padding()
            
            Button("View attachment") {
                viewAttachment()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CardDetailsView: View {
    let card: Card
    
    let transaction: (CardTransaction) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Card Details")
                .padding()
            
            Button("Transaction Details") {
                transaction(CardTransaction(id: UUID().uuidString, merchant: "IKEA ODENSE"))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct BetterNavigationLink<Value, Destination: View>: View {
    @Binding var item: Value?
    
    var isDetailLink: Bool = false
    
    @ViewBuilder let destination: (Value) -> Destination
    
    var body: some View {
        NavigationLink(isActive: $item.isActive) {
            if let value = item {
                destination(value)
            }
        } label: { EmptyView() }
            .isDetailLink(isDetailLink)
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
