# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the project
xcodebuild -project haemong-ios.xcodeproj -scheme haemong-ios -sdk iphonesimulator build

# Run tests
xcodebuild -project haemong-ios.xcodeproj -scheme haemong-ios test

# Clean build
xcodebuild -project haemong-ios.xcodeproj -scheme haemong-ios clean

# Build and run on simulator
xcodebuild -project haemong-ios.xcodeproj -scheme haemong-ios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Architecture Overview

This iOS app uses **The Composable Architecture (TCA)** pattern for state management and follows a unidirectional data flow.

### TCA Structure
Each feature module contains:
- **State**: `@ObservableState` struct containing all feature state
- **Action**: Enum defining all possible actions
- **Reducer**: Business logic that updates state based on actions
- **Dependencies**: Injected services (e.g., `APIClient`)

### Key Architectural Decisions

1. **Feature Modularity**: Each major screen/flow has its own Feature file in `/Features`
   - AppFeature orchestrates the entire app state and navigation
   - Child features (Auth, Login, ChatRoom, BotSettings) are composed into AppFeature

2. **Navigation Pattern**: 
   - App uses enum-based state machine for top-level navigation (`AppLaunchState`)
   - Tab-based navigation for authenticated users
   - Navigation state is managed in AppFeature.State

3. **API Architecture**:
   - Single `APIClient` dependency using `@DependencyClient` macro
   - All API calls go through centralized client
   - Token-based authentication stored in Keychain
   - Base URL currently hardcoded to `http://localhost:3000` - needs environment configuration

4. **State Composition**:
   - AppFeature contains AuthFeature and LoginFeature states
   - Other features (ChatRoom, BotSettings) are instantiated per-use in views
   - Use `Scope` to connect parent-child reducers

### Critical Implementation Notes

1. **Store Initialization**: When creating stores in views, use the TCA syntax with dependencies:
   ```swift
   Store(initialState: Feature.State()) {
       Feature()
   } withDependencies: {
       $0.apiClient = .liveValue
   }
   ```

2. **View Bindings**: Use `@Bindable` for store references and `.sending()` for two-way bindings:
   ```swift
   @Bindable var store: StoreOf<Feature>
   TextField("", text: $store.text.sending(\.textChanged))
   ```

3. **Async Effects**: Use `.run` with proper error handling:
   ```swift
   return .run { send in
       do {
           let response = try await apiClient.someCall()
           await send(.response(.success(response)))
       } catch {
           await send(.response(.failure(error)))
       }
   }
   ```

### Current Issues to Address

1. **API Configuration**: Base URL is hardcoded, needs environment-based configuration
2. **OAuth Integration**: Google Sign-In is stubbed, needs actual SDK integration
3. **Navigation**: AppView navigation logic needs testing after recent updates
4. **Test Coverage**: Test files exist but are empty/default

### App-Specific Context

- **Purpose**: Dream interpretation app ("해몽" = dream interpretation in Korean)
- **Bot System**: 4 personality types (Eastern/Western × Male/Female)
- **Chat Flow**: Daily chat rooms with user/bot message exchange
- **Authentication**: Supports email/password and OAuth (Google, Apple)