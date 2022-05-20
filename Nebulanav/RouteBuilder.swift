import SwiftUI

public protocol NavigableDestination {
    var path: [Self] { get }
}

public class Router<Destination: NavigableDestination>: ObservableObject {
    @Published public internal(set) var destination: Destination? = nil
    
    private var navigation: [DispatchWorkItem] = []
    
    public init() {
    }
    
    public func navigate(to destination: Destination?) {
        navigation.forEach { $0.cancel() }
        navigation = []
        
        guard let destination = destination else {
            self.destination = nil
            return
        }

        let currentPath = self.destination?.path ?? []
        let currentDepth = currentPath.count
        
        let nextPath = destination.path
        let nextDepth = nextPath.count
        
        // When navigating deeper than one level into a stack, `NavigationView` will fail to push consequitive views
        // unless we wait until it finished pushing the previous one.
        let work = (0..<(nextDepth - currentDepth))
            .map { iteration -> (Int, DispatchWorkItem) in
                let workItem = DispatchWorkItem {
                    let index = currentDepth + iteration
                    self.destination = nextPath[index]
                }
                
                return (iteration, workItem)
            }
        
        navigation = work.map { $1 }
        
        work.forEach { iteration, workItem in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(iteration * 550), execute: workItem)
        }
    }
}

public struct RouteNavigationLink<Destination: NavigableDestination, Content: View>: View {
    let router: Router<Destination>
    
    @Binding var isActive: Bool
    @Binding var path: [Destination]
    @Binding var children: [Destination]
    
    let content: (Destination) -> Content
    
    public init(
        router: Router<Destination>,
        isActive: Binding<Bool>,
        path: Binding<[Destination]>,
        children: Binding<[Destination]>,
        @ViewBuilder content: @escaping (Destination) -> Content
    ) {
        self.router = router
        self._isActive = isActive
        self._path = path
        self._children = children
        self.content = content
    }
    
    public var body: some View {
        NavigationLink(isActive: $isActive) {
            if let child = $children.wrappedValue.first {
                RouteView(
                    router: router,
                    path: $path,
                    destination: child,
                    children: Array(children.dropFirst()),
                    content: content
                )
            }
        } label: { EmptyView() }
    }
}

public struct Routes<Root: View, Destination: NavigableDestination, Content: View>: View {
    @ObservedObject var router: Router<Destination>
    
    let root: Root
    let content: (Destination) -> Content
    
    public init(router: Router<Destination>, @ViewBuilder root: () -> Root, @ViewBuilder content: @escaping (Destination) -> Content) {
        self.router = router
        self.root = root()
        self.content = content
    }
    
    var isChildActive: Binding<Bool> {
        Binding(
            get: { router.destination != nil },
            set: { newValue in
                if !newValue && router.destination != nil {
                    router.destination = nil
                }
            }
        )
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                root
                
                RouteNavigationLink(
                    router: router,
                    isActive: isChildActive,
                    path: children,
                    children: children,
                    content: content
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var children: Binding<[Destination]> {
        Binding(
            get: { router.destination?.path ?? [] },
            set: { router.destination = $0.last }
        )
    }
}

public struct RouteView<Destination: NavigableDestination, Content: View>: View {
    let router: Router<Destination>
    
    @Binding var path: [Destination]
    
    let destination: Destination
    let children: [Destination]
    
    let content: (Destination) -> Content
    
    public init(router: Router<Destination>, path: Binding<[Destination]>, destination: Destination, children: [Destination], @ViewBuilder content: @escaping (Destination) -> Content) {
        self.router = router
        self._path = path
        self.destination = destination
        self.children = children
        self.content = content
    }
    
    var isChildActive: Binding<Bool> {
        Binding(
            get: { !children.isEmpty },
            set: { newValue in
                if let _ = children.first, !newValue {
                    path = destination.path
                }
            }
        )
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            content(destination)
            
            RouteNavigationLink(
                router: router,
                isActive: isChildActive,
                path: $path,
                children: .constant(children),
                content: content
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum Destination: NavigableDestination {
    case card(cardId: String)
    case cardTransaction(cardId: String, transactionId: String)
    
    case account
    case profile
    
    case terminatedCards
    case terminatedCard(cardId: String)
    case terminatedCardTransaction(cardId: String, transactionId: String)
    
    var path: [Destination] {
        switch self {
        case .card(let cardId):
            return [.card(cardId: cardId)]
        case .cardTransaction(let cardId, let cardTransaction):
            return [.card(cardId: cardId), .cardTransaction(cardId: cardId, transactionId: cardTransaction)]
            
        case .account:
            return [.account]
        case .profile:
            return [.account, .profile]
        
        case .terminatedCards:
            return [.terminatedCards]
        case .terminatedCard(let cardId):
            return [.terminatedCards, .terminatedCard(cardId: cardId)]
        case .terminatedCardTransaction(let cardId, let transactionId):
            return [.terminatedCards, .terminatedCard(cardId: cardId), .terminatedCardTransaction(cardId: cardId, transactionId: transactionId)]
        }
    }
}

typealias NebulaRouter = Router<Destination>

struct HomeNebulaScreen: View {
    @EnvironmentObject var router: NebulaRouter
    @EnvironmentObject var presenter: NebulaPresenter
    
    @Binding var session: Session?
    
    var body: some View {
        if let session = session {
            HomeView(
                session: session,
                signOut: { self.session = nil },
                selectTransaction: { card, trx in
                    router.navigate(to: .cardTransaction(cardId: card.id, transactionId: trx.id))
                }
            )
        } else {
            StartView(signIn: {
                presenter.present(.login)
            })
        }
    }
}

struct CardDetailsNebulaScreen: View {
    @EnvironmentObject var router: NebulaRouter
    
    let id: String
    
    var body: some View {
        CardDetailsView(card: Card(id: id, number: "card-\(id)")) { trx in
            router.navigate(to: .cardTransaction(cardId: id, transactionId: trx.id))
        }
    }
}

struct TransactionNebulaScreen: View {
    @EnvironmentObject var router: NebulaRouter
    
    let id: String
    
    var body: some View {
        TransactionDetailsView(
            transaction: CardTransaction(id: id, merchant: "trx-\(id)"),
            root: {
                router.navigate(to: nil)
            }
        )
    }
}

typealias NebulaPresenter = Presenter<Sheet>

struct UsageView: View {
    @StateObject var router = NebulaRouter()
    @StateObject var presenter = NebulaPresenter()
    
    @State var session: Session?
    
    var body: some View {
        Presentations(presenter: presenter) {
            Routes(router: router) {
                HomeNebulaScreen(session: $session)
                    .environmentObject(router)
                    .environmentObject(presenter)
            } content: { destination in
                Group {
                    switch destination {
                    case .card(cardId: let cardId):
                        CardDetailsNebulaScreen(id: cardId)
                    case .cardTransaction(cardId: let cardId, transactionId: let transactionId):
                        TransactionNebulaScreen(id: transactionId)
                    case .account:
                        Text("Account")
                    case .profile:
                        Text("Profile")
                    case .terminatedCards:
                        Text("Terminated Cards")
                    case .terminatedCard(cardId: let cardId):
                        Text("Terminated Card: \(cardId)")
                    case .terminatedCardTransaction(cardId: let cardId, transactionId: let transactionId):
                        Text("Terminated Card Transaction: \(cardId), \(transactionId)")
                    }
                }
                .environmentObject(router)
                .environmentObject(presenter)
            }
        } content: { presentation in
            Group {
                switch presentation.presentable {
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
                    Text("Not implemented yet: \(presentation.presentable.id)")
                }
            }
            .environmentObject(router)
            .environmentObject(presenter)
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

struct UsageView_Previews: PreviewProvider {
    static var previews: some View {
        UsageView()
    }
}
