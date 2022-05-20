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

struct BetterSheetHost<Router, Presentable, Destination: View>: View {
    let router: Router
    
    let presentation: ReferenceWritableKeyPath<Router, Presentation<Presentable>?>
    let publisher: KeyPath<Router, Published<Presentation<Presentable>?>.Publisher>
    
    var onDismiss: (Presentable) -> Void = { _ in }
    
    @ViewBuilder let destination: (Presentable) -> Destination
    
    @State var nextPresentation: Presentation<Presentable>?
    
    @State var currentSheet: Presentable?
    @State var currentFullScreenCover: Presentable?
    
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
                    enqueue(presentation)
                } else {
                    present(presentation)
                }
            } else {
                clear()
            }
        }
    }
    
    private func _onDismiss() {
//        if let previous = self.previous {
//            onDismiss(previous)
//        }
                
        if let presentation = self.nextPresentation {
            present(presentation)
        } else if router[keyPath: presentation] != nil {
            router[keyPath: presentation] = nil
        }
    }
    
    private func enqueue(_ presentation: Presentation<Presentable>) {
        nextPresentation = presentation
        
        currentSheet = nil
        currentFullScreenCover = nil
    }
    
    private func present(_ presentation: Presentation<Presentable>) {
        nextPresentation = nil
        
        currentSheet = presentation.style == .sheet ? presentation.presentable : nil
        currentFullScreenCover = presentation.style == .fullScreenCover ? presentation.presentable : nil
    }
    
    private func clear() {
        nextPresentation = nil
        
        currentSheet = nil
        currentFullScreenCover = nil
    }
}
