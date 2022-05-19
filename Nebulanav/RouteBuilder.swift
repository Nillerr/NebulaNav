import SwiftUI

protocol NavigableDestination {
    var path: [Self] { get }
}

enum Destination: View, NavigableDestination {
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
    
    var body: some View {
        switch self {
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
}

class Router<Destination: NavigableDestination>: ObservableObject {
    @Published var destination: Destination? = nil
    
    func navigate(to destination: Destination?) {
        guard let destination = destination else {
            self.destination = nil
            return
        }

        let currentPath = self.destination?.path ?? []
        let currentDepth = currentPath.count
        
        let nextPath = destination.path
        let nextDepth = nextPath.count
        
        (0..<(nextDepth - currentDepth))
            .forEach { index in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(index * 550)) {
                    self.destination = nextPath[(index.advanced(by: currentDepth))]
                }
            }
    }
}

struct Routes<Root: View, Destination: View & NavigableDestination>: View {
    @ObservedObject var router: Router<Destination>
    
    @ViewBuilder let root: () -> Root
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                root()
                    .environmentObject(router)
                
                NavigationLink(isActive: isChildActive) {
                    if let path = pathBinding.wrappedValue, let child = path.first {
                        Route(path: pathBinding, content: child, children: Array(path.dropFirst()))
                            .environmentObject(router)
                    }
                } label: { EmptyView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var pathBinding: Binding<[Destination]> {
        Binding(
            get: { router.destination?.path ?? [] },
            set: { router.destination = $0.last }
        )
    }
}

struct Route<Destination: View & NavigableDestination>: View {
    @EnvironmentObject var router: Router<Destination>
    
    @Binding var path: [Destination]
    
    let content: Destination
    let children: [Destination]
    
    var isChildActive: Binding<Bool> {
        Binding(
            get: { !children.isEmpty },
            set: { newValue in
                if let _ = children.first, !newValue {
                    path = content.path
                }
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .environmentObject(router)
            
            NavigationLink(isActive: isChildActive) {
                if let child = children.first {
                    Route(path: $path, content: child, children: Array(children.dropFirst()))
                        .environmentObject(router)
                }
            } label: { EmptyView() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

typealias NebulaRouter = Router<Destination>

struct HomeNebulaScreen: View {
    @EnvironmentObject var router: NebulaRouter
    
    @State var session: Session?
    
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
            LoginView(signedIn: { result in
                switch result {
                case .session(let session):
                    self.session = session
                default:
                    break
                }
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

struct UsageView: View {
    @StateObject var router = NebulaRouter()
    
    var body: some View {
        Routes(router: router) {
            HomeNebulaScreen()
        }
    }
}

struct UsageView_Previews: PreviewProvider {
    static var previews: some View {
        UsageView()
    }
}
