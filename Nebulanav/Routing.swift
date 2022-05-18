import SwiftUI

protocol LevelRouter: ObservableObject {
    associatedtype Screen
    associatedtype DetailRouter
    
    var screen: Screen { get }
    var detail: DetailRouter? { get set }
}

class Router: ObservableObject, LevelRouter {
    // MARK: Sheets
    @Published var presentation: Presentation<Sheet>? {
        didSet {
            print("didSet presentation = \(presentation?.sheet?.id ?? presentation?.fullScreenCover?.id ?? "<nil>")")
        }
    }
    
    // MARK: Navigation
    @Published var session: Session? {
        didSet {
            if session == nil {
                navigate(to: nil)
            }
        }
    }
    
    var screen: String { "" }
    
    @Published var detail: LevelOneRouter?
    
    func signOut() {
        session = nil
        presentation = nil
        detail = nil
    }
    
    func signIn(session: Session) {
        self.session = session
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(550)) {
                completion(detail)
            }
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                completion(detail)
            }
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                completion(detail)
            }
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                completion(detail)
            }
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

enum Presentation<Sheet> {
    case sheet(Sheet)
    case fullScreenCover(Sheet)
    
    var sheet: Sheet? {
        if case .sheet(let sheet) = self {
            return sheet
        }
        
        return nil
    }
    
    var fullScreenCover: Sheet? {
        if case .fullScreenCover(let sheet) = self {
            return sheet
        }
        
        return nil
    }
}

struct BetterSheetHost<Router, Sheet, Destination: View>: View {
    let router: Router
    
    let presentation: ReferenceWritableKeyPath<Router, Presentation<Sheet>?>
    let publisher: KeyPath<Router, Published<Presentation<Sheet>?>.Publisher>
    
    var onDismiss: (Sheet) -> Void = { _ in }
    
    @ViewBuilder let destination: (Sheet) -> Destination
    
    @State var nextPresentation: Presentation<Sheet>?
    
    @State var currentSheet: Sheet?
    @State var currentFullScreenCover: Sheet?
    
    var body: some View {
        Group {
            VStack {}
                .sheet(isPresented: $currentSheet.isActive, onDismiss: _onDismiss) {
                    if let current = currentSheet {
                        destination(current)
                    }
                }
            
            VStack {}
                .fullScreenCover(isPresented: $currentFullScreenCover.isActive, onDismiss: _onDismiss) {
                    if let current = currentFullScreenCover {
                        destination(current)
                    }
                }
        }
        .onReceive(router[keyPath: publisher]) { presentation in
            if let presentation = presentation {
                if currentSheet != nil || currentFullScreenCover != nil {
                    nextPresentation = presentation
                    
                    currentSheet = nil
                    currentFullScreenCover = nil
                } else {
                    nextPresentation = nil
                    
                    currentSheet = presentation.sheet
                    currentFullScreenCover = presentation.fullScreenCover
                }
            } else {
                nextPresentation = nil
                
                currentSheet = nil
                currentFullScreenCover = nil
            }
        }
    }
    
    private func _onDismiss() {
//        if let previous = self.previous {
//            onDismiss(previous)
//        }
                
        if let nextPresentation = self.nextPresentation {
            self.nextPresentation = nil
            
            self.currentSheet = nextPresentation.sheet
            self.currentFullScreenCover = nextPresentation.fullScreenCover
        } else if router[keyPath: presentation] != nil {
            router[keyPath: presentation] = nil
        }
    }
}

extension Router {
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
