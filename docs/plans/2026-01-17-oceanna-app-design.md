# Oceanna App Design

A curated creative marketplace where talent discovers talent.

## Core Identity

### What Oceanna Is

A premium, curated platform connecting creative professionals and clients through swipe-based discovery and follow-based community. One profile, fluid identity — be hireable, hiring, or both.

### The Four Pillars

| Pillar | Description |
|--------|-------------|
| **Local-first** | City-level presence, in-person availability options, no exposed addresses |
| **Speed** | Swipe discovery, quick connections, same-day possibilities |
| **Community** | Follow-based feed, real relationships, not just transactions |
| **Quality** | Human-reviewed profiles, verified completions, curated from day one |

### Identity Model

- One profile per user
- "Show me as hireable" toggle — on or off
- Algorithm subtly shifts content based on mode
- No separate accounts or personas

### Privacy Model

- Location is city-level only ("Brooklyn, NY")
- Users declare availability: In-person / Remote / Both
- Profile visibility is user-controlled
- No maps, no pins, no exact locations

### The Premium Bar

- Every profile is human-reviewed before going live
- Not approved = waitlisted, not rejected
- Curation is the moat

---

## Navigation Structure

### Four Tabs

| Tab | Purpose |
|-----|---------|
| **Feed** | Curated stream from people you follow |
| **Discover** | Swipe-based discovery (adapts to toggle) |
| **Messages** | Unified inbox — DMs, requests, notifications |
| **Profile** | Your identity, portfolio, settings |

---

## Feed

The heart of the app. Follow-based, chronological.

### Content Types

- Portfolio pieces (finished work)
- Behind-the-scenes / work-in-progress
- Personal updates
- Opportunity posts ("Looking for a photographer Saturday")
- Collaboration requests
- Milestones ("Just hit 100 projects!")
- Questions and discussions

### Behavior

- Only see posts from people you follow
- No algorithmic curation — chronological
- All content types mixed together
- Compose button for creating posts

---

## Discover

Swipe-based discovery with quick preview cards.

### Card Design

- Framed image (white border, gallery aesthetic)
- Name below image
- Top skill displayed
- Tap to expand for more details

### Interactions

| Action | Result |
|--------|--------|
| **Swipe right** | Connection request sent |
| **Swipe left** | Pass |
| **Tap** | Expand profile preview |

### Context-Aware Content

- Hireable toggle ON → Swipe through opportunity posts
- Hireable toggle OFF → Swipe through freelancer profiles

---

## Connections

### Connection Flow

1. Swipe right or tap "Connect"
2. Recipient receives connection request in inbox
3. Recipient accepts or ignores
4. Match — both notified, DM unlocks

### What Connection Unlocks

| Before Connection | After Connection |
|-------------------|------------------|
| Limited profile (user-controlled) | Full profile access |
| No messaging | DMs enabled |
| Don't see their posts | Their posts in your feed |

---

## Opportunities & Applications

### Posting Opportunities

Clients post in the main feed: "Looking for a photographer Saturday"

Opportunity posts include:
- What they need
- Budget range (optional)
- Timeline
- Location preference (in-person/remote)

### Responding to Opportunities

| Action | Description |
|--------|-------------|
| **"I'm Interested"** | One tap, low commitment signal |
| **"Apply"** | Sends profile privately, higher commitment |

### Client Reviews Applicants

- Stack view — swipe through interested freelancers
- Same card style as Discover
- Swipe right = match, DM opens

---

## Messaging

Not just chat. Project-aware and milestone-enabled.

### Features

- Messages can reference specific posts/projects
- Built-in tools: quotes, proposals, agreements
- Milestone tracking within thread
- "Mark as complete" triggers review flow

### Unified Inbox

The Messages tab contains:
- Direct message threads
- Connection requests
- Match notifications
- All activity

### Payments

Off-platform. Oceanna connects, doesn't transact. Users handle payment via Venmo, PayPal, cash, etc.

---

## Reviews & Reputation

### Verified Completion Flow

1. Either party taps "Mark as complete"
2. Both must confirm
3. Reviews unlock

### Review Format

Category ratings (1-5 stars each):
- Quality
- Communication
- Timeliness

Plus optional written testimonial.

### Display

Reviews show on profile with verified "Worked together" badge.

---

## Onboarding

### Required to Start

| Field | Required |
|-------|----------|
| Photo | Yes |
| Name | Yes |
| City | Yes |
| Skills OR "looking for" | Yes |
| Portfolio piece | Optional |
| Availability (in-person/remote/both) | Yes |
| Hireable toggle | Yes |

### Flow

1. Create account (email/password or social)
2. Add photo + name
3. Set city
4. Add skills or what you're looking for
5. Optionally add portfolio piece
6. Set availability preference
7. Set hireable toggle
8. Submit for review
9. Approved → Full access / Not yet → Waitlist

---

## Visual Design

### Design Philosophy

Erewhon / Le Labo / Apple — minimal, premium, content-forward. The work is the star.

### Color Palette

Pure monochrome:
- Primary: Black (#000000)
- Background: White (#FFFFFF)
- Grays: System grays for hierarchy
- No accent colors — portfolio work brings color

### Typography

| Use | Style |
|-----|-------|
| **UI text** | SF Pro (system sans-serif) |
| **Tags, skills, metadata** | SF Mono (monospace) |

### Card Design

- Framed image with white border
- Generous padding
- Info below image, not overlaid
- Gallery/museum aesthetic

### Spacing & Layout

- Generous white space
- Content breathes
- Minimal chrome
- Focus on imagery

### Motion

- Subtle, purposeful
- Smooth swipe physics
- No flashy animations
- Micro-interactions for feedback

---

## Screen Inventory

### Tab Bar Screens

| Screen | Key Elements |
|--------|--------------|
| **Feed** | Chronological posts, post type labels, compose button |
| **Discover** | Full-screen swipe cards, like/pass buttons |
| **Messages** | Unified inbox list, unread badges |
| **Profile** | Avatar, info, toggle, skills, portfolio grid, reviews |

### Secondary Screens

| Screen | Key Elements |
|--------|--------------|
| **Expanded Profile** | Full portfolio, all skills, rates, reviews, Connect/Message button |
| **Opportunity Detail** | Client info, requirements, budget, timeline, Interest/Apply buttons |
| **Applicant Stack** | Swipe through applicants, same card style |
| **Conversation** | Chat thread, project context, quote/proposal tools |
| **Create Post** | Post type selector, content input, media upload |
| **Settings** | Privacy controls, notification preferences, account |
| **Edit Profile** | All profile fields, portfolio management |

### Onboarding Screens

| Screen | Purpose |
|--------|---------|
| **Welcome** | App intro, value prop |
| **Create Account** | Email/password or social auth |
| **Profile Setup** | Photo, name, city |
| **Skills/Intent** | Add skills or what you're looking for |
| **Portfolio** | Optional portfolio piece upload |
| **Availability** | In-person / Remote / Both |
| **Hireable Toggle** | Initial setting |
| **Review Pending** | Submitted, awaiting approval |
| **Waitlist** | Not yet approved, guidance to improve |

---

## Data Models

### User

```
User {
  id: String
  email: String
  displayName: String
  avatarUrl: String?
  city: String
  isHireable: Boolean
  availability: Enum (inPerson, remote, both)
  skills: [String]
  lookingFor: [String]?
  bio: String?
  isVerified: Boolean
  isApproved: Boolean
  createdAt: Date
}
```

### Portfolio Item

```
PortfolioItem {
  id: String
  userId: String
  imageUrl: String
  title: String
  description: String?
  tags: [String]
  createdAt: Date
}
```

### Post

```
Post {
  id: String
  authorId: String
  postType: Enum (portfolio, update, wip, opportunity, collaboration, milestone, question)
  content: String
  mediaUrls: [String]
  tags: [String]
  createdAt: Date
}
```

### Connection

```
Connection {
  id: String
  requesterId: String
  receiverId: String
  status: Enum (pending, accepted, ignored)
  createdAt: Date
  acceptedAt: Date?
}
```

### Conversation

```
Conversation {
  id: String
  participantIds: [String]
  projectReference: String?
  createdAt: Date
  lastMessageAt: Date
}
```

### Message

```
Message {
  id: String
  conversationId: String
  senderId: String
  content: String
  messageType: Enum (text, quote, proposal, milestone, completion)
  attachments: [String]?
  createdAt: Date
}
```

### Review

```
Review {
  id: String
  reviewerId: String
  revieweeId: String
  conversationId: String
  qualityRating: Int (1-5)
  communicationRating: Int (1-5)
  timelinessRating: Int (1-5)
  content: String?
  createdAt: Date
}
```

---

## Technical Considerations

### Architecture

- SwiftUI + MVVM
- Firebase Auth
- Cloud Firestore
- Cloud Storage for media
- No payment integration (off-platform)

### Key Features to Build

1. Auth flow with profile approval/waitlist
2. Profile with hireable toggle
3. Follow-based feed with multiple post types
4. Swipe-based discovery (context-aware)
5. Connection request system
6. Unified messaging inbox
7. Project-aware chat with milestone tools
8. Verified completion + review system
9. Human review admin tooling

### Privacy & Security

- City-level location only (no coordinates stored)
- User-controlled profile visibility
- Connection-gated messaging
- No payment data stored

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Profile approval rate | Track quality bar |
| Connection acceptance rate | Healthy: >40% |
| Message response rate | Healthy: >60% |
| Verified completions | Growth over time |
| Review completion rate | >70% after verified completion |

---

## Out of Scope (YAGNI)

- Payment processing
- Video calls
- Stories/ephemeral content
- Group chats
- Public comments on posts
- Algorithmic feed ranking
- Push notification preferences (v1 = all or nothing)
