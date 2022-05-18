import SwiftUI

func presentations(router: ApplicationRouter) -> some View {
    BetterSheetHost(router: router, presentation: \.presentation, publisher: \.$presentation, onDismiss: { current in
        print("onDismiss: \(current.id)")
    }) { sheet in
        switch sheet {
        case .login:
            LoginView(signedIn: router.process(output:))
        case .mfaChallenge(let challenge):
            MFAChallengeView(challenge: challenge, passed: router.process(output:))
        case .mfaEnrollment(let requirement):
            MFAEnrollmentFlow(requirement: requirement, enrolled: router.process(output:))
        case .personalDetails:
            PersonalDetailsView(confirmed: router.process(output:))
        case .biometricPrompt:
            BiometricPromptView(signedIn: router.signIn(session:))
        case .comment(let success):
            CommentView(success: success)
        case .attachment(let success):
            AttachmentView(delete: success)
        case .addAttachment(let success):
            AddAttachmentView(success: success)
        case .requestCard(let success):
            RequestCardFlow(success: success)
        default:
            Text("Not implemented yet: \(sheet.id)")
        }
    }
}

struct ApplicationFlow: View {
    @StateObject var router = ApplicationRouter()
    
    @State var pendingAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationView {
                RoutesView(routes: router) { screen in
                    switch screen {
                    case .login:
                        StartView(signIn: { router.presentation = .sheet(.login) })
                            .background(Color.gray.ignoresSafeArea())
                    case .home(let session):
                        HomeView(session: session, signOut: { router.signOut() })
                            .background(Color.white.ignoresSafeArea())
                    }
                } detail: { detail in
                    LevelOneRoutes(routes: detail)
                }
                .environmentObject(router)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            presentations(router: router)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onOpenURL { url in
            print("onOpenURL \(url)")
            openURL(url)
        }
        .onReceive(router.$screen) { screen in
            if case .home(_) = screen {
                pendingAction?()
                pendingAction = nil
            }
        }
    }
    
    private func openURL(_ url: URL) {
        print("Path Components: \(url.pathComponents)")
        
        switch url.pathComponents[safe: 1] {
        case "cards":
            whenSignedIn { [router] in
                if let cardId = url.pathComponents[safe: 2] {
                    router.navigate(to: .cardDetails(Card(id: cardId, number: "number-\(cardId)")))
                } else {
                    router.navigate(to: nil)
                }
            }
        case "account":
            whenSignedIn { [router] in
                switch url.pathComponents[safe: 2] {
                case "profile":
                    router.navigate(to: .contact)
                default:
                    router.navigate(to: .account)
                }
            }
        case "request-card":
            whenSignedIn(presents: true) { [router] in
                router.presentation = .sheet(
                    .requestCard {
                        router.presentation = nil
                        print("Card Requested (from URL)")
                    }
                )
            }
        case "login":
            router.signIn(session: Session(accessToken: "access-token", refreshToken: "refresh-token"))
        default:
            break
        }
    }
    
    private func whenSignedIn(presents: Bool = false, perform action: @escaping () -> Void) {
        if case .home = router.screen {
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
    
    @State var challenge: MFAChallengeRequirement? = nil
    
    let enrolled: (Output) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MFAEnrollmentView(requirement: requirement, challenge: { challenge in
                    self.challenge = challenge
                })
                
                BetterNavigationLink(item: $challenge) { challenge in
                    MFAChallengeView(challenge: challenge, passed: { output in
                        enrolled(output)
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationViewStyle(.stack)
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
                            } label: { EmptyView() }
                                .isDetailLink(false)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } label: { EmptyView() }
                    .isDetailLink(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationViewStyle(.stack)
    }
}
