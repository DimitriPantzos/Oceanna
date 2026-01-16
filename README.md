# Oceanna

A local freelancer platform iOS app that connects creative professionals, freelancers, and clients through location-based discovery, verified profiles, and transparent portfolios.

## Features

### Core Features
- **Dual Profile System**: Separate profiles for freelancers and clients with detailed information
- **Location-Based Discovery**: Interactive map showing nearby freelancers with filtering options
- **Social Feed**: Share work, post collaboration requests, and connect with the community
- **Real-time Messaging**: Direct messaging with freelancers and clients
- **Swipe-to-Connect**: Tinder-style networking for quick local connections
- **Smart Matching**: AI-powered recommendations for projects and collaborators

### For Freelancers
- Portfolio showcase with images and project details
- Skills and services listing with pricing
- Availability calendar and location radius settings
- Ratings and reviews from clients
- Project recommendations based on skills

### For Clients
- Business profile with project preferences
- Post projects with budget and timeline
- Browse and filter local freelancers
- Hire history and ratings
- Payment verification badges

## Tech Stack

- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Cloud Functions (planned)
- **Maps**: MapKit
- **Payments**: Stripe (planned)

## Project Structure

```
Oceanna/
├── App/
│   ├── OceannaApp.swift          # App entry point
│   └── ContentView.swift          # Root view
├── Core/
│   ├── Authentication/
│   ├── Navigation/
│   │   └── MainTabView.swift     # Tab navigation
│   └── Extensions/
│       └── View+Extensions.swift
├── Models/
│   ├── User.swift
│   ├── FreelancerProfile.swift
│   ├── ClientProfile.swift
│   ├── Project.swift
│   ├── Message.swift
│   ├── Review.swift
│   ├── FeedPost.swift
│   └── Location.swift
├── Services/
│   ├── AuthService.swift
│   ├── FirestoreService.swift
│   ├── LocationService.swift
│   ├── StorageService.swift
│   ├── MessagingService.swift
│   └── MatchingService.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── DiscoveryViewModel.swift
│   ├── FeedViewModel.swift
│   ├── MessagesViewModel.swift
│   └── ProjectViewModel.swift
├── Views/
│   ├── Auth/
│   ├── Profile/
│   ├── Discovery/
│   ├── Feed/
│   ├── Messages/
│   ├── Projects/
│   └── Components/
└── Resources/
```

## Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ deployment target
- Firebase account
- CocoaPods or Swift Package Manager

### Installation

1. Clone the repository
```bash
git clone https://github.com/DimitriPantzos/Oceanna.git
cd Oceanna
```

2. Open the project in Xcode
```bash
open Oceanna.xcodeproj
```

3. Add Firebase configuration
   - Create a Firebase project at [firebase.google.com](https://firebase.google.com)
   - Download `GoogleService-Info.plist`
   - Add it to the Xcode project

4. Install dependencies via Swift Package Manager
   - Firebase iOS SDK
   - Add package: `https://github.com/firebase/firebase-ios-sdk`

5. Build and run

### Firebase Setup

Enable the following Firebase services:
- **Authentication**: Email/Password provider
- **Cloud Firestore**: Create collections for users, profiles, projects, etc.
- **Cloud Storage**: For avatars and portfolio images

### Firestore Rules (Development)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Data Models

### User Types
- **Freelancer**: Creative professionals offering services
- **Client**: Individuals or businesses hiring talent

### Key Collections
- `users`: Basic user information
- `freelancerProfiles`: Detailed freelancer data
- `clientProfiles`: Business/client information
- `projects`: Job postings
- `conversations`: Chat threads
- `posts`: Social feed content
- `reviews`: Two-way reviews

## Roadmap

### Phase 1 (Current)
- [x] User authentication
- [x] Profile management
- [x] Discovery map view
- [x] Social feed
- [x] Messaging

### Phase 2 (Planned)
- [ ] Payment integration (Stripe)
- [ ] Push notifications
- [ ] Video portfolio support
- [ ] Calendar integration

### Phase 3 (Future)
- [ ] AI-powered matching improvements
- [ ] Event mode for local meetups
- [ ] Creative Circles (community groups)
- [ ] Analytics dashboard

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or feedback, please open an issue on GitHub.
