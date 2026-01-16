import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .discover

    enum Tab: String, CaseIterable {
        case discover = "Discover"
        case feed = "Feed"
        case messages = "Messages"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .discover: return "map"
            case .feed: return "square.stack"
            case .messages: return "message"
            case .profile: return "person.circle"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoveryView()
                .tabItem {
                    Label(Tab.discover.rawValue, systemImage: Tab.discover.icon)
                }
                .tag(Tab.discover)

            FeedView()
                .tabItem {
                    Label(Tab.feed.rawValue, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)

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
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
