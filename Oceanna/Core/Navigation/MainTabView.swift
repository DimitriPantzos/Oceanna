import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .feed
    @StateObject private var connectionService = ConnectionService.shared
    @EnvironmentObject var authService: AuthService

    enum Tab: String, CaseIterable {
        case feed = "Feed"
        case discover = "Discover"
        case messages = "Messages"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .feed: return "square.stack"
            case .discover: return "sparkle.magnifyingglass"
            case .messages: return "bubble.left.and.bubble.right"
            case .profile: return "person"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label(Tab.feed.rawValue, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)

            DiscoveryView()
                .tabItem {
                    Label(Tab.discover.rawValue, systemImage: Tab.discover.icon)
                }
                .tag(Tab.discover)

            MessagesListView()
                .tabItem {
                    Label(Tab.messages.rawValue, systemImage: Tab.messages.icon)
                }
                .tag(Tab.messages)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(OceannaTheme.Colors.primary)
        .onAppear {
            setupTabBarAppearance()
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
}
