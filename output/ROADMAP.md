# Commet Matrix Client - Full Roadmap & Feature Audit

**Date**: 2026-03-09
**Version**: 0.4.0+749
**Codebase**: ~112,772 LOC Dart across 554+ files

---

## Current State Summary

Commet is a mature Flutter Matrix client with strong foundations: full E2EE with cross-signing, VoIP via LiveKit, multi-account support, custom emoji/sticker packs, threads, reactions, spaces, and unique features like calendar rooms, photo albums, and message effects. It runs on Android, Linux, and Windows.

### Commet-Unique Advantages Over Element
- Calendar room type (RFC 8984 events, recurring events, availability)
- Photo album rooms with gallery view
- Voice-specific room type with dedicated UI
- Message effects (celebration particles)
- Per-room/space color schemes
- User color assignment for visual distinction
- Donation awards system
- Deep Termux ARM64 build support

---

## Part 1: Element Feature Parity Gap Analysis

### CRITICAL MISSING (Element has, Commet lacks)

| # | Feature | Element Status | Priority | Effort |
|---|---------|---------------|----------|--------|
| 1 | **Polls** (MSC3381) | Full support | P0 | Medium |
| 2 | **Location sharing** (MSC3488/3489) | Static + live | P1 | Medium |
| 3 | **Voice messages** (MSC3245) | Record + playback w/ waveform | P0 | Medium |
| 4 | **Message forwarding** | Forward to any room | P1 | Small |
| 5 | **Screen share** (currently disabled) | Full support | P0 | Small (enable) |
| 6 | **QR code login** | Scan to auth new device | P2 | Medium |
| 7 | **Web client** | Element Web exists | P3 | Large |
| 8 | **Integration manager** | Bots, bridges UI | P2 | Large |
| 9 | **Room directory federation** | Cross-server search | P1 | Small |
| 10 | **Spoiler text** | HTML spoilers | P2 | Small |
| 11 | **LaTeX/math rendering** | Formula display | P2 | Small |
| 12 | **Message permalink/sharing** | Share deep links | P1 | Small |
| 13 | **Knock rooms** (Room v7+) | Request to join | P1 | Medium |
| 14 | **Server ACL management** | Admin UI for ACLs | P2 | Small |
| 15 | **Moderation tools** | Ban lists, Mjolnir support | P2 | Medium |
| 16 | **Keyword notification alerts** | Custom word triggers | P1 | Small |
| 17 | **Email notifications** | Digest for missed messages | P3 | Medium |
| 18 | **iOS support** | Full iOS client | P1 | Large |
| 19 | **macOS support** | Full macOS client | P2 | Medium |

### PARTIALLY IMPLEMENTED (needs completion)

| # | Feature | Current State | Needed |
|---|---------|--------------|--------|
| 20 | **Screen sharing** | Code exists, disabled in registry | Enable & test |
| 21 | **RTC data channels** | Code exists, commented out | Enable or remove |
| 22 | **Background sync** | Stub implementation | Full background sync |
| 23 | **MatrixBackgroundClient** | 10+ TODO methods | Implement all stubs |
| 24 | **Notification counts** | Incomplete on Android | Fix badge counts |
| 25 | **Update checker** | Partially implemented | Complete flow |
| 26 | **Room version upgrades** | Tombstone handling unclear | Full upgrade flow |

---

## Part 2: Full TODO List

### Tier 0 - Foundation & Fixes (Do First)

- [x] **Fix background client stubs** - MatrixBackgroundClient + MatrixBackgroundRoom stubs implemented
- [x] **Fix notification badge counts** on Android - Counts-only push handled
- [x] **Enable screen sharing** - Already enabled in ComponentRegistry
- [x] **Complete update checker** flow with UI notification
- [x] **Fix avatar refresh handling** - Already resolved
- [x] **Fix display name update handling** - Already resolved
- [x] **Implement getRoomByAlias** in MatrixBackgroundClient
- [x] **Implement joinRoomFromPreview** in MatrixBackgroundClient
- [x] **Re-enable RTC data channels** - Already enabled and functional
- [x] **Fix cross-signing error case handling** - Dead code removed
- [x] **Fix calendar settings undefined cases** - Default fallback present
- [x] **Reimplement donation awards validation** - Hex key validation added

### Tier 1 - Core Feature Parity

- [x] **Native polls** (MSC3381) - Create/vote/view results in timeline (vote wired)
- [x] **Voice messages** (MSC3245) - Record from input bar, waveform display, playback
- [x] **Message forwarding** - Forward any message to another room/DM
- [x] **Location sharing** - Static pin on map via MSC3488
- [x] **Live location sharing** - Streaming location via MSC3489
- [x] **Knock room support** - Request to join restricted rooms (Room v7+)
- [x] **Room directory federation** - Public room directory with server search
- [x] **Message permalinks** - Generate and share matrix.to deep links
- [x] **Keyword notification alerts** - Custom word triggers wired to push
- [ ] **Full background sync** - Complete stub implementation for Android service
- [ ] **iOS client** - Bring up existing iOS stubs to working state

### Tier 2 - Enhanced Experience

- [x] **Spoiler text** - `<span data-mx-spoiler>` rendering and input
- [x] **LaTeX/math rendering** - Text-based math expression rendering
- [x] **Room upgrade flow** - UI for room version upgrades with tombstone
- [x] **Server ACL management** - Admin UI for `m.room.server_acl`
- [x] **Moderation tools** - Ban list management UI
- [ ] **QR code login** - Scan QR from verified device
- [ ] **Integration manager** - UI for adding bots, bridges, widgets
- [ ] **Jitsi widget fallback** - For servers without LiveKit
- [ ] **macOS support** - Native macOS build
- [ ] **Email notification digests** - Missed message summaries
- [x] **Federated user search** - Cross-server user directory queries
- [x] **Room filters** - Filter rooms by type, unread, favorites, DMs
- [x] **Favorites/Low priority** - Room tag management (m.favourite, m.lowpriority)
- [x] **Share sheet integration** - Android share-to-room intent handler
- [x] **Deep link handling** - matrix.to / matrix: URI scheme support

### Tier 3 - Polish & Nice-to-Haves

- [x] **Syntax highlighting** in code blocks (language detection)
- [x] **Message search improvements** - Global search across all rooms
- [x] **Read receipt details** - Show who read when (hover/tap)
- [x] **Room statistics** - Message counts, active users, room info panel
- [x] **Notification sound customization** - Sound preference wired to notifier
- [x] **Chat bubble style toggle** - IRC-style vs bubble-style messages
- [x] **Compact mode** - Dense layout for power users
- [x] **Multiple themes** - AMOLED, solarized, nord, dark, light
- [x] **Export chat history** - Export room messages as text/JSON
- [x] **Import/export settings** - Backup app configuration as JSON
- [x] **Offline mode** - Read cached messages via Drift database
- [x] **Message scheduling** - Compose now, send later with ScheduledTaskRunner
- [x] **Draft messages** - Auto-save unsent message drafts per room
- [x] **Quick reactions** - Configurable frequently-used reaction bar
- [x] **User notes** - Private notes about other users
- [x] **Room bookmarks** - Bookmark specific messages for later
- [x] **Font customization** - Custom font selection wired to theme
- [ ] **Auto-translation** - Translate messages via service integration
- [ ] **Web client** - Flutter web build
- [x] **Tablet layout** - Optimized two/three-pane layout

---

## Part 3: Beyond Element - Most Feature-Rich Matrix Client

### Category A: Collaboration Tools

- [ ] **Collaborative whiteboard** - NeoBoard-style infinite canvas via widget
- [ ] **Collaborative document editing** - Etherpad widget with Matrix auth
- [ ] **Task/kanban boards** - Room-based task management via custom state events
- [ ] **Shared clipboard** - Cross-device clipboard sync via Matrix
- [ ] **Screen annotation** - Draw on shared screens during calls

### Category B: Productivity Features

- [ ] **Smart notifications** - AI-powered notification prioritization
- [x] **Message templates** - Reusable message templates per room
- [x] **Scheduled messages** - Time-delayed message sending with ScheduledTaskRunner
- [x] **Auto-responder** - Away messages with DM debounce
- [x] **Message reminders** - Snooze messages for later with notification
- [ ] **Room dashboards** - Customizable room landing pages with widgets
- [x] **Cross-room search** - Unified search across all rooms/spaces
- [x] **Command palette** - Quick action launcher (Ctrl+K style)
- [x] **Keyboard shortcuts editor** - Visual shortcut customization

### Category C: Social & Community

- [ ] **User profiles 2.0** - Rich profiles with timezone, pronouns, bio (MSC4133)
- [ ] **Community events** - Calendar events discoverable across spaces
- [x] **Public space discovery** - Public room directory supports spaces
- [x] **User status messages** - Custom status with emoji
- [x] **Activity feed** - Recent activity on home screen
- [ ] **Reputation system** - Community trust scores

### Category D: Security & Privacy

- [x] **Disappearing messages** - Retention state event (MSC1763) wired
- [x] **Message expiry** - Per-room message retention policy UI
- [x] **Panic button** - Quick logout-all-accounts button
- [ ] **Anonymous posting** - Post without revealing identity in public rooms
- [ ] **Secure file vault** - E2EE file storage using room state

### Category E: Developer & Power User

- [x] **Room state inspector** - Browse all state events in a room
- [x] **Event debugger** - View raw event JSON for any message
- [x] **Custom slash commands** - User-definable command aliases with expansion
- [ ] **Scripting/macros** - Simple automation via room events
- [ ] **Webhook support** - Incoming webhooks to rooms
- [x] **API explorer** - Built-in Matrix CS API browser in developer settings
- [x] **Performance dashboard** - Client stats, sync diagnostics, build info

---

## Part 4: Five Clever Hidden Protocol Abilities

These exploit underutilized Matrix spec capabilities that no client has fully implemented:

### 1. Room-as-Database: Structured Data Rooms
**Concept**: Use custom state events (`state_key` + `type`) as a key-value store with full E2EE, federation, and access control. Each room becomes a replicated, encrypted, access-controlled database.

**Implementation**:
- Custom state event type: `com.commet.data.record` with structured JSON content
- State key = record ID, content = arbitrary JSON schema
- Query interface: filter/sort/search over room state
- Use cases: shared password manager, contact book, inventory tracker, wiki
- Advantage: free E2EE, federation, permissions, and conflict resolution from Matrix

**Why nobody does it**: Clients only render chat-like events; no UI exists for browsing/querying custom state as structured data.

### 2. Ephemeral Presence Channels: Live Cursors & Collaborative Awareness
**Concept**: Use Matrix ephemeral events (typing indicators, EDUs) as a transport for real-time collaborative presence beyond "is typing". Send cursor positions, selection ranges, scroll positions, and interaction states.

**Implementation**:
- Extended typing notification with payload: `{"typing": true, "cursor": {"x": 120, "y": 300}, "context": "document:abc"}`
- Real-time cursor overlay on shared documents/whiteboards
- "User is viewing this message" indicators (live scroll sync)
- Collaborative reading: see where others are in a long conversation
- Live reaction previews: see emoji being selected before sent

**Why nobody does it**: Typing indicators are treated as boolean on/off; the payload field is ignored by all clients.

### 3. Portable Identity Rooms: Self-Sovereign Profile Vaults
**Concept**: Use a private, invite-only room as a portable identity container. Store verifiable credentials, signed attestations, portfolio items, and reputation proofs as room state events. Your identity travels with you across homeservers.

**Implementation**:
- Private room type `com.commet.identity.vault`
- State events for: signed credentials, portfolio links, verification proofs, reputation scores
- Export identity by sharing room invite
- Verify claims cryptographically via Matrix device signatures
- Cross-server identity portability (invite vault room to new homeserver)

**Why nobody does it**: Identity is treated as server-bound (displayname/avatar on homeserver). No client uses rooms as identity containers.

### 4. Ghost Rooms: Invisible Overlay Networks
**Concept**: Create "shadow" rooms that mirror the membership of existing rooms but carry different content streams. Enables parallel communication channels attached to any room - think IRC channels-within-channels.

**Implementation**:
- Room state event `com.commet.ghost.parent` links to parent room
- Auto-sync membership from parent room
- Use cases:
  - **Side channel**: Moderators discuss in shadow room while monitoring public room
  - **Topic streams**: Multiple topic-specific overlays on one community room
  - **Annotation layer**: Comments and highlights attached to a content room
  - **Bot traffic**: Separate bot output from human conversation
- Power levels inherited from parent with optional overrides

**Why nobody does it**: Rooms are treated as standalone; no client creates linked room hierarchies beyond spaces.

### 5. Time-Locked Message Vaults: Future-Dated Content Release
**Concept**: Use Matrix's event content encryption + custom state events to implement time-locked messages. Content is encrypted with a key that is only revealed via a scheduled state event at a future time.

**Implementation**:
- Sender encrypts message content with a symmetric key
- Sends encrypted content as regular message
- Stores decryption key in a `com.commet.timelock` state event with `reveal_at` timestamp
- A room bot or the sender's client sends the key as a new event when the time arrives
- Uses existing Megolm for transport encryption + additional time-lock layer
- Use cases:
  - **Scheduled announcements**: Embargo releases
  - **Dead drops**: Information revealed only at specified time
  - **Timed puzzles/games**: ARGs, scavenger hunts
  - **Exam/quiz mode**: Questions revealed simultaneously to all participants
  - **Will/inheritance**: Content released on conditions

**Why nobody does it**: No client has added an application-layer encryption concept beyond Megolm. The spec's custom events + custom encryption combine to enable this entirely within the protocol.

---

## Part 5: Architecture Improvements

### Code Quality

- [ ] Split large classes (>500 LOC) - MatrixClient, MatrixRoom
- [ ] Add unit test coverage (currently only integration_test/)
- [ ] Remove disabled/dead code (RTC data channels, commented features)
- [ ] Add inline documentation for complex features
- [ ] Reduce widget nesting depth (some trees >10 levels)
- [ ] Formalize dependency injection (currently implicit via constructors)

### Performance

- [ ] Implement sliding sync (MSC4186) for faster startup
- [ ] Add lazy loading for room member lists
- [ ] Implement message pagination caching
- [ ] Add image caching strategy with size limits
- [ ] Profile and optimize initial sync time
- [ ] Add connection quality indicator

### Testing

- [ ] Unit tests for all client/ classes
- [ ] Widget tests for core UI components
- [ ] Integration tests for critical flows (login, send message, E2EE)
- [ ] Performance benchmarks in CI
- [ ] Screenshot regression tests

---

## Implementation Priority Order

**Phase 1 - Fix & Enable** (1-2 weeks)
1. Enable screen sharing (already coded)
2. Fix all TODO/stub methods in background client
3. Fix notification badge counts
4. Fix avatar/display name update handling

**Phase 2 - Core Parity** (3-6 weeks)
5. Voice messages (MSC3245)
6. Native polls (MSC3381)
7. Message forwarding
8. Knock room support
9. Message permalinks

**Phase 3 - Rich Features** (4-8 weeks)
10. Location sharing
11. Spoiler text + LaTeX
12. Room filters & favorites
13. Share sheet integration
14. Moderation tools

**Phase 4 - Innovation** (ongoing)
15. Room-as-Database (clever feature #1)
16. Collaborative whiteboard widget
17. Command palette
18. User profiles 2.0 (MSC4133)
19. Sliding sync (MSC4186)

**Phase 5 - Platform Expansion**
20. iOS client
21. macOS client
22. Web client (Flutter web)
