import SwiftUI

protocol LevelRouter: ObservableObject {
    associatedtype Screen
    associatedtype DetailRouter
    
    var screen: Screen { get }
    var detail: DetailRouter? { get set }
}

/**
 This function addresses the issue of pushing several views onto a navigation stack.
 */
func deferredNav<T>(detail: T, completion: @escaping (T) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(550)) {
        completion(detail)
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
