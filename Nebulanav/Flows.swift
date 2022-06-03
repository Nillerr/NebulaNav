import SwiftUI
import Detour

enum Destination: Routeable {
    case card(CardDetailViewModel)
    case cardTransaction(CardDetailViewModel, TransactionDetailViewModel)
    
    case account
    case profile
    
    case terminatedCards
    case terminatedCard(CardDetailViewModel)
    case terminatedCardTransaction(CardDetailViewModel, TransactionDetailViewModel)
    
    var path: [Destination] {
        switch self {
        case .card(let viewModel):
            return [.card(viewModel)]
        case .cardTransaction(let cardViewModel, let viewModel):
            return [.card(cardViewModel), .cardTransaction(cardViewModel, viewModel)]
            
        case .account:
            return [.account]
        case .profile:
            return [.account, .profile]
        case .terminatedCards:
            return [.account, .terminatedCards]
        case .terminatedCard(let viewModel):
            return [.account, .terminatedCards, .terminatedCard(viewModel)]
        case .terminatedCardTransaction(let cardViewModel, let viewModel):
            return [.account, .terminatedCards, .terminatedCard(cardViewModel), .terminatedCardTransaction(cardViewModel, viewModel)]
        }
    }
    
    var style: RouteStyle { .none }
}

typealias Presenter = Detour.Presenter<Sheet>
typealias Router = Detour.Router<Destination>

struct ApplicationPresentations: View {
    let presenter: Presenter
    let router: Router
    
    let presentable: Sheet
    let style: PresentationStyle
    
    @Binding var session: Session?
    
    var body: some View {
        switch presentable {
        case .login:
            LoginView(signedIn: process(output:))
        case .mfaChallenge(let challenge):
            MFAChallengeView(challenge: challenge, passed: process(output:))
        case .mfaEnrollment(let requirement):
            MFAEnrollmentFlow(requirement: requirement, enrolled: process(output:))
        case .personalDetails:
            PersonalDetailsView(confirmed: process(output:))
        case .biometricPrompt:
            BiometricPromptView(signedIn: signIn(session:))
        case .comment(let success):
            CommentView(success: success)
        case .attachment(let success):
            AttachmentView(delete: success)
        case .addAttachment(let success):
            AddAttachmentView(success: success)
        case .requestCard(let success):
            RequestCardFlow(success: success)
        default:
            Text("Not implemented yet: \(presentable.id)")
        }
    }
    
    private func process(output: LoginView.Output) {
        switch output {
        case .session(let session):
            signIn(session: session)
        case .mfaChallenge(let challenge):
            presenter.present(.mfaChallenge(challenge))
        case .mfaEnrollment(let enrollment):
            presenter.present(.mfaEnrollment(enrollment))
        case .personalDetails:
            presenter.present(.personalDetails)
        case .biometricPrompt:
            presenter.present(.biometricPrompt)
        }
    }
    
    private func process(output: MFAEnrollmentFlow.Output) {
        switch output {
        case .session(let session):
            signIn(session: session)
        case .personalDetails:
            presenter.present(.personalDetails)
        case .biometricPrompt:
            presenter.present(.biometricPrompt)
        }
    }
    
    private func process(output: PersonalDetailsView.Output) {
        switch output {
        case .session(let session):
            signIn(session: session)
        case .biometricsPrompt:
            presenter.present(.biometricPrompt)
        }
    }
    
    private func signIn(session: Session) {
        self.session = session
        presenter.dismiss()
    }
}

struct ApplicationRoutes: View {
    let presenter: Presenter
    let router: Router
    
    let destination: Destination
    
    @Binding var session: Session?
    
    var body: some View {
        switch destination {
        case .card(let card):
            CardDetailsView(viewModel: card, transaction: { trx in
                router.navigate(to: .cardTransaction(card, trx))
            })
        case .cardTransaction(_, let trx):
            TransactionDetailsView(
                viewModel: trx,
                root: { router.navigate(to: nil) },
                comment: { presenter.present(.comment(success: { _ in presenter.dismiss() })) },
                addAttachment: { presenter.present(.addAttachment(success: { presenter.dismiss() })) },
                viewAttachment: { presenter.present(.attachment(success: { presenter.dismiss() })) }
            )
        case .account:
            AccountView(
                profile: { router.navigate(to: .profile) },
                terminatedCards: { router.navigate(to: .terminatedCards) }
            )
        case .profile:
            ProfileView(signOut: {
                session = nil
                router.navigate(to: nil)
            })
        case .terminatedCards:
            TerminatedCardsView(terminatedCardDetails: { card in
                router.navigate(to: .terminatedCard(card))
            })
        case .terminatedCard(let card):
            TerminatedCardDetailsView(viewModel: card, transaction: { trx in
                router.navigate(to: .terminatedCardTransaction(card, trx))
            })
        case .terminatedCardTransaction(_, let trx):
            TransactionDetailsView(
                viewModel: trx,
                root: { router.navigate(to: nil) },
                comment: { presenter.present(.comment(success: { _ in presenter.dismiss() })) },
                addAttachment: { presenter.present(.addAttachment(success: { presenter.dismiss() })) },
                viewAttachment: { presenter.present(.attachment(success: { presenter.dismiss() })) }
            )
        }
    }
}

struct StartFlow: View {
    let presenter: Presenter
    let router: Router
    
    @Binding var session: Session?
    
    var body: some View {
        if let session = session {
            HomeView(
                session: session,
                requestCard: { presenter.present(.requestCard(success: { presenter.dismiss() })) },
                card: { card in router.navigate(to: .card(card)) },
                cardTransaction: { card, trx in router.navigate(to: .cardTransaction(card, trx)) },
                terminatedCardTransaction: { card, trx in router.navigate(to: .terminatedCardTransaction(card, trx)) },
                account: { router.navigate(to: .account) }
            )
            .background(Color.white.ignoresSafeArea())
        } else {
            StartView(signIn: { presenter.present(.login) })
                .background(Color.gray.ignoresSafeArea())
        }
    }
}

struct ApplicationFlow: View {
    @StateObject var presenter = Presenter()
    @StateObject var router = Router()
    
    @State var pendingAction: (() -> Void)?
    
    @State var session: Session?
    
    var isSessionActive: Bool { session != nil }
    
    var body: some View {
        Presentations(presenter: presenter) {
            Routes(router: router) {
                StartFlow(presenter: presenter, router: router, session: $session)
            } content: { destination in
                ApplicationRoutes(
                    presenter: presenter,
                    router: router,
                    destination: destination,
                    session: $session
                )
            }
        } content: { presentation in
            ApplicationPresentations(
                presenter: presenter,
                router: router,
                presentable: presentation.presentable,
                style: presentation.style,
                session: $session
            )
        }
        .onOpenURL { url in
            print("onOpenURL \(url)")
            openURL(url)
        }
        .onChange(of: isSessionActive) { isActive in
            if isActive {
                pendingAction?()
                pendingAction = nil
            }
        }
    }
    
    private func openURL(_ url: URL) {
        print("Path Components: \(url.pathComponents)")
        
        switch url.pathComponents[safe: 1] {
        case "cards":
            whenSignedIn {
                if let cardId = url.pathComponents[safe: 2] {
                    let cardViewModel = CardDetailViewModel(cardId: cardId)
                    router.navigate(to: .card(cardViewModel))
                } else {
                    router.navigate(to: nil)
                }
            }
        case "account":
            whenSignedIn {
                switch url.pathComponents[safe: 2] {
                case "profile":
                    router.navigate(to: .profile)
                default:
                    router.navigate(to: .account)
                }
            }
        case "request-card":
            whenSignedIn(presents: true) {
                presenter.present(
                    .requestCard {
                        presenter.dismiss()
                        print("Card Requested (from URL)")
                    }
                )
            }
        case "login":
            session = Session(accessToken: "access-token", refreshToken: "refresh-token")
        default:
            break
        }
    }
    
    private func whenSignedIn(presents: Bool = false, perform action: @escaping () -> Void) {
        if isSessionActive {
            action()
        } else {
            pendingAction = presents ? {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(550), execute: action)
            } : action
        }
    }
}

struct MFAEnrollmentFlow: View {
    enum Output {
        case session(Session)
        case personalDetails
        case biometricPrompt
    }
    
    let requirement: MFAEnrollmentRequirement
    
    @State var isChallengeActive: Bool = false
    @State var challenge: MFAChallengeRequirement? = nil
    
    let enrolled: (Output) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MFAEnrollmentView(requirement: requirement, challenge: { challenge in
                    self.challenge = challenge
                    self.isChallengeActive = true
                })
                
                NavigationLink(item: $challenge) { challenge in
                    MFAChallengeView(challenge: challenge, passed: { output in
                        enrolled(output)
                    })
                }
                .isDetailLink(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationViewStyle(.stack)
        .onChange(of: isChallengeActive) { newValue in
            if !newValue {
                challenge = nil
            }
        }
    }
}

struct RequestCardFlow: View {
    let success: () -> Void
    
    @State var amount: String?
    @State var purpose: String?
    
    @State var isPurposeActive = false
    @State var isSummaryActive = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                RequestCardAmountView(amount: $amount) {
                    isPurposeActive = true
                }
                
                NavigationLink(isActive: $isPurposeActive) {
                    if let amount = amount {
                        VStack(spacing: 0) {
                            RequestCardPurposeView(purpose: $purpose) {
                                isSummaryActive = true
                            }
                            
                            NavigationLink(isActive: $isSummaryActive) {
                                if let purpose = purpose {
                                    RequestCardSummaryView(amount: amount, purpose: purpose) {
                                        success()
                                    }
                                }
                            }
                            .isDetailLink(false)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .isDetailLink(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationViewStyle(.stack)
    }
}
