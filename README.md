# Discogs Explorer

Discogs Explorer is an iOS SwiftUI app built with MVVM that searches artists through the Discogs API, shows artist details (including band members), and navigates artist releases with sorting and filtering.


<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-28 at 05 37 45" src="https://github.com/user-attachments/assets/bf67172d-a8f3-43cd-94fd-cda87469b4bb" />



https://github.com/user-attachments/assets/3be767e2-d2a4-48b0-8f58-37491ea98fd1


## Project Structure - This map has been automatically generated
- `Networking/`
  - `APIConfig.swift`
  - `HTTPClient.swift`
  - `APIError.swift`
  - `DiscogsAPI.swift`
  - `README-Networking.md`
- `Utilities/`
  - `ToastManager.swift`
  - `AsyncImageCache.swift`
  - `README-Utilities.md`
- `ViewModels/`
  - `SearchViewModel.swift`
  - `ArtistDetailViewModel.swift`
  - `ReleasesViewModel.swift`
  - `README-ViewModels.md`
- `Views/`
  - `Search/SearchView.swift`
  - `Artist/ArtistDetailView.swift`
  - `Releases/ReleasesListView.swift`
  - `Releases/ReleaseFilterSheet.swift`
  - `Components/GlassToolbarModifier.swift`
  - `Components/SearchBarModifier.swift`
  - `Components/ImageMarqueeView.swift`
  - `Settings/TokenSettingsView.swift`
  - `README-Views.md`
- `../DiscogsTests/`
  - `NetworkingTests.swift`
  - `SearchViewModelTests.swift`
  - `ReleasesViewModelTests.swift`
  - `README-Tests.md`
- Root files
  - `.swiftlint.yml`
  - `Scripts/run-swiftlint.sh`
  - `README.md`
  - `ContentView.swift`
  - `Package.swift`

## Setup and Run
1. Clone the repository:
   - `git clone <your-repo-url>`
2. Open the project in Xcode.
3. Build and run the `Discogs` scheme on an iOS simulator/device.
4. **Optional**: Add your Discogs `consumerKey` and `consumerSecret` in `Networking/APIConfig.swift` if you have you own app.
5. Run the app, open **Discogs Account**, tap **Connect with Discogs**, authorize in Safari, and paste the verifier code to complete sign in.

Discogs API docs: https://www.discogs.com/developers

## SwiftLint Setup
1. Install SwiftLint:
   - Homebrew: `brew install swiftlint`
3. Keep `.swiftlint.yml` at project root.

### Interpreting SwiftLint Results
- Warnings indicate style/maintainability issues.
- Errors indicate stricter quality violations.
- Reporter is set to `xcode`, so issues appear in Issue Navigator.

## Architecture and Reasoning
- Pattern: **MVVM** with strict separation of concerns.
- Views: SwiftUI rendering and navigation.
- ViewModels: query debounce, pagination, filtering, sorting, and screen state.
- Networking: reusable HTTP client, API service abstraction, and model decoding.
- Utilities: toast notifications and image caching for UX/performance.

This architecture keeps networking testable and prevents business logic from leaking into views.

## Analysis and Development Process
1. Defined folder boundaries by concern (Networking, Utilities, ViewModels, Views, Tests).
2. Implemented Discogs API integration with authentication header and pagination (`per_page=30`).
3. Built empty-state-first main UX with animated API image marquee.
4. Added artist detail flow and releases discography with filter sheet.
5. Added unit tests for API request composition and view model logic.
6. Added static analysis script/config plus module documentation.

## Functional Highlights
- Native SwiftUI search bar (`.searchable`) on the main screen.
- In-app Discogs OAuth flow (request token + verifier exchange) with Keychain credential storage.
- Empty state with animated image rows sourced from Discogs API thumbnails.
- Artist result list with thumbnails and detail navigation.
- Artist detail with member sorting options for bands.
- Releases sorted newest-to-oldest by year.
- Filtering by year, genre (from available release format metadata), and label.
- Friendly error handling mapped from Discogs HTTP status codes.
