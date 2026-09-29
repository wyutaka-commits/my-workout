import SwiftUI
import WebKit

struct ContentView: View {
    private let appURL = URL(string: "https://YOUR_GITHUB_USERNAME.github.io/my-workout/")!
    var body: some View { HealthWebView(url: appURL).ignoresSafeArea(.all) }
}

struct HealthWebView: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "healthKit")
        config.userContentController = controller
        let web = WKWebView(frame: .zero, configuration: config)
        web.allowsBackForwardNavigationGestures = false
        web.load(URLRequest(url: url))
        context.coordinator.webView = web
        return web
    }
    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?
        private let store = HealthKitManager()
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let action = body["action"] as? String else { return }
            switch action {
            case "readToday":
                Task { @MainActor in
                    do {
                        try await store.requestAuthorization()
                        let summary = try await store.readToday()
                        let data = try JSONSerialization.data(withJSONObject: summary, options: [])
                        let json = String(data: data, encoding: .utf8) ?? "{}"
                        self.webView?.evaluateJavaScript("window.receiveHealthSummary(\(json))")
                    } catch {
                        let msg = error.localizedDescription.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
                        self.webView?.evaluateJavaScript("window.receiveHealthSummary({error:\"\(msg)\"})")
                    }
                }
            default: break
            }
        }
    }
}
