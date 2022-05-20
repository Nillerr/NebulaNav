import SwiftUI

class ApplicationRouter: ObservableObject, LevelRouter {
    // MARK: Sheets
    @Published var presentation: Presentation<Sheet>? {
        didSet {
            print("didSet presentation = \(presentation?.presentable.id ?? "<nil>")")
        }
    }
    
    // MARK: Navigation
    @Published var screen: Screen = .login
    @Published var detail: LevelOneRouter?
    
    enum Screen {
        case login
        case home(Session)
    }
    
    func signOut() {
        screen = .login
        presentation = nil
        detail = nil
    }
    
    func signIn(session: Session) {
        self.screen = .home(session)
        self.presentation = nil
    }
    
    func navigate(to destination: Destination?) {
        if let destination = destination {
            navigate(to: destination)
        } else {
            detail = nil
        }
    }
    
    private func navigate(to destination: Destination) {
        switch destination {
        case .cardDetails(let cardId):
            navigate(detail: .cardDetails(cardId)) { detail in
                detail.navigate(to: nil)
            }
        case .account:
            navigate(detail: .account) { detail in
                detail.navigate(to: nil)
            }
        case .transactionDetails(let card, let transaction):
            navigate(detail: .cardDetails(card)) { detail in
                detail.navigate(to: .transactionDetails(transaction))
            }
        case .terminatedCards:
            navigate(detail: .account) { detail in
                detail.navigate(to: .terminatedCards)
            }
        case .contact:
            navigate(detail: .account) { detail in
                detail.navigate(to: .contact)
            }
        case .terminatedCardDetails(let card):
            navigate(detail: .account) { detail in
                detail.navigate(to: .terminatedCardDetails(card))
            }
        case .terminatedCardTransactionDetails(let card, let transaction):
            navigate(detail: .account) { detail in
                detail.navigate(to: .terminatedCardTransactionDetails(card, transaction))
            }
        }
    }
    
    private func navigate(detail screen: LevelOneRouter.Screen, completion: @escaping (LevelOneRouter) -> Void) {
        if let detail = detail {
            detail.screen = screen
            completion(detail)
        } else {
            let detail = LevelOneRouter(screen: screen)
            self.detail = detail
            
            deferredNav(detail: detail, completion: completion)
        }
    }
    
    enum Destination {
        // Level One
        case cardDetails(Card)
        case account
        
        // Level Two
        case transactionDetails(Card, CardTransaction)
        case terminatedCards
        case contact
        
        // Level Three
        case terminatedCardDetails(Card)
        
        // Level Four
        case terminatedCardTransactionDetails(Card, CardTransaction)
    }
}

class LevelOneRouter: ObservableObject, LevelRouter {
    enum Screen {
        case cardDetails(Card)
        case account
    }
    
    @Published var screen: Screen
    @Published var detail: LevelTwoRouter?
    
    init(screen: Screen) {
        self.screen = screen
    }
    
    func navigate(to destination: Destination?) {
        if let destination = destination {
            navigate(to: destination)
        } else {
            detail = nil
        }
    }
    
    private func navigate(to destination: Destination) {
        switch destination {
        case .transactionDetails(let transaction):
            navigate(detail: .transactionDetails(transaction)) { detail in
                detail.navigate(to: nil)
            }
        case .terminatedCards:
            navigate(detail: .terminatedCards) { detail in
                detail.navigate(to: nil)
            }
        case .contact:
            navigate(detail: .contact) { detail in
                detail.navigate(to: nil)
            }
        case .terminatedCardDetails(let card):
            navigate(detail: .terminatedCards) { detail in
                detail.navigate(to: .terminatedCardDetails(card))
            }
        case .terminatedCardTransactionDetails(let card, let transaction):
            navigate(detail: .terminatedCards) { detail in
                detail.navigate(to: .terminatedCardTransactionDetails(card, transaction))
            }
        }
    }
    
    private func navigate(detail screen: LevelTwoRouter.Screen, completion: @escaping (LevelTwoRouter) -> Void) {
        if let detail = detail {
            detail.screen = screen
            
            completion(detail)
        } else {
            let detail = LevelTwoRouter(screen: screen)
            self.detail = detail
            
            deferredNav(detail: detail, completion: completion)
        }
    }
    
    enum Destination {
        // Level Two
        case transactionDetails(CardTransaction)
        case terminatedCards
        case contact
        
        // Level Three
        case terminatedCardDetails(Card)
        
        // Level Four
        case terminatedCardTransactionDetails(Card, CardTransaction)
    }
}

class LevelTwoRouter: ObservableObject, LevelRouter {
    enum Screen {
        case transactionDetails(CardTransaction)
        case terminatedCards
        case contact
    }
    
    @Published var screen: Screen
    @Published var detail: LevelThreeRouter?
    
    init(screen: Screen) {
        self.screen = screen
    }
    
    func navigate(to destination: Destination?) {
        if let destination = destination {
            navigate(to: destination)
        } else {
            detail = nil
        }
    }
    
    private func navigate(to destination: Destination) {
        switch destination {
        case .terminatedCardDetails(let card):
            navigate(detail: .terminatedCardDetails(card)) { detail in
                detail.navigate(to: nil)
            }
        case .terminatedCardTransactionDetails(let card, let transaction):
            navigate(detail: .terminatedCardDetails(card)) { detail in
                detail.navigate(to: .terminatedCardTransactionDetails(transaction))
            }
        }
    }
    
    private func navigate(detail screen: LevelThreeRouter.Screen, completion: @escaping (LevelThreeRouter) -> Void) {
        if let detail = detail {
            detail.screen = screen
            
            completion(detail)
        } else {
            let detail = LevelThreeRouter(screen: screen)
            self.detail = detail
            
            deferredNav(detail: detail, completion: completion)
        }
    }
    
    enum Destination {
        // Level Three
        case terminatedCardDetails(Card)
        
        // Level Four
        case terminatedCardTransactionDetails(Card, CardTransaction)
    }
}

class LevelThreeRouter: ObservableObject, LevelRouter {
    enum Screen {
        case terminatedCardDetails(Card)
    }
    
    @Published var screen: Screen
    @Published var detail: LevelFourRouter?
    
    init(screen: Screen) {
        self.screen = screen
    }
    
    func navigate(to destination: Destination?) {
        if let destination = destination {
            navigate(to: destination)
        } else {
            detail = nil
        }
    }
    
    private func navigate(to destination: Destination) {
        switch destination {
        case .terminatedCardTransactionDetails(let transaction):
            navigate(detail: .transactionDetails(transaction)) { detail in
                // Nothing
            }
        }
    }
    
    private func navigate(detail screen: LevelFourRouter.Screen, completion: @escaping (LevelFourRouter) -> Void) {
        if let detail = detail {
            detail.screen = screen
            completion(detail)
        } else {
            let detail = LevelFourRouter(screen: screen)
            self.detail = detail
            
            deferredNav(detail: detail, completion: completion)
        }
    }
    
    enum Destination {
        // Level Four
        case terminatedCardTransactionDetails(CardTransaction)
    }
}

class LevelFourRouter: ObservableObject {
    enum Screen {
        case transactionDetails(CardTransaction)
    }
    
    @Published var screen: Screen
    
    init(screen: Screen) {
        self.screen = screen
    }
}

extension Presentation {
    static func sheet(_ presentable: Presentable) -> Self {
        .init(presentable: presentable, style: .sheet)
    }
    
    static func fullScreenCover(_ presentable: Presentable) -> Self {
        .init(presentable: presentable, style: .fullScreenCover)
    }
}

extension ApplicationRouter {
    func process(output: LoginView.Output) {
        switch output {
        case .session(let session):
            signIn(session: session)
        case .mfaChallenge(let challenge):
            presentation = .sheet(.mfaChallenge(challenge))
        case .mfaEnrollment(let enrollment):
            presentation = .sheet(.mfaEnrollment(enrollment))
        case .personalDetails:
            presentation = .sheet(.personalDetails)
        case .biometricPrompt:
            presentation = .sheet(.biometricPrompt)
        }
    }
    
    func process(output: MFAEnrollmentFlow.Output) {
        switch output {
        case .session(let session):
            signIn(session: session)
        case .personalDetails:
            presentation = .sheet(.personalDetails)
        case .biometricPrompt:
            presentation = .sheet(.biometricPrompt)
        }
    }
    
    func process(output: PersonalDetailsView.Output) {
        switch output {
        case .session(let session):
            signIn(session: session)
        case .biometricsPrompt:
            presentation = .sheet(.biometricPrompt)
        }
    }
}
