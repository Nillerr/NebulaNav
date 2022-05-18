import SwiftUI

func presentations(router: Router) -> some View {
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
    @StateObject var router = Router()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                NavigationView {
                    if let session = router.session {
                        HomeFlow(router: router, session: session, signOut: { router.signOut() })
                            .background(Color.gray.ignoresSafeArea())
                    } else {
                        StartView(signIn: { router.presentation = .sheet(.login) })
                            .background(Color.white.ignoresSafeArea())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            presentations(router: router)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HomeFlow: View {
    @ObservedObject var router: Router
    
    let session: Session
    
    let signOut: () -> Void
    
    var body: some View {
        RoutesView(routes: router) { screen in
            HomeView(session: session, signOut: signOut)
        } detail: { detail in
            LevelOneRoutes(routes: detail)
        }
        .environmentObject(router)
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
