# Discogs Explorer

Discogs Explorer is an iOS SwiftUI app built with MVVM that searches artists through the Discogs API, shows artist details (including band members), and navigates artist releases with sorting and filtering.


<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-28 at 05 37 45" src="https://github.com/user-attachments/assets/bf67172d-a8f3-43cd-94fd-cda87469b4bb" />



https://github.com/user-attachments/assets/3be767e2-d2a4-48b0-8f58-37491ea98fd1



## Setup and Run
1. Clone the repository:
   - `git clone https://github.com/caaronperez/Discogs`
2. Open the project in Xcode.
3. Build and run the `Discogs` scheme on an iOS simulator/device.
4. **Optional**: Add your Discogs `consumerKey` and `consumerSecret` in `Networking/APIConfig.swift` if you have you own app.
5. Run the app, open **Discogs Account**, tap **Connect with Discogs**, authorize in Safari, and paste the verifier code to complete sign in.

Discogs API docs: https://www.discogs.com/developers

## SwiftLint Setup
1. Install SwiftLint:
   - Homebrew: `brew install swiftlint`
3. Keep `.swiftlint.yml` at project root.


## Architecture and Reasoning

This app is using MVVM with SwiftUI.

• Views: only UI and navigation.
• ViewModels: business logic, screen state, filtering/sorting/pagination.
• Networking: all API requests, decoding and error mapping.
• Utilities: reusable helpers (toast manager, image cache).
• Mocks/Tests: fake data for previews and tests.

This architecture keeps networking testable and prevents business logic from leaking into views.
It iss easier to maintain and easier to test too.
If one API changes, I only touch networking/viewmodel mostly, not all screens.
Also with MVVM the views stay smaller and less complicated, and you can debug things faster when something goes wrong.

It also scales better if later I add more endpoints or screens, because structure is already separated and not mixed everywhere.

## Analysis and Development Process

Brief description of analysis and development process

I started by organizing the project first, because if not it gets messy super fast.
So I separated things by folders (Networking, View​Models, Views, Utilities, Tests) and then I was building feature by feature.

First I made the API calls work (search artists, artist detail, artist releases), after that I connected it to the UI screens.
Then I added pagination, loading states, empty states and better error messages, so app dont feel broken when something fails.

After core functionality was ready, I worked on UX details (animations, image loading, filters, sorting, auth settings screen).
At the end I added mocks and unit tests for important logic, and configured SwiftLint to keep code cleaner.

So basically, it was: structure first, then core logic, then UI polish, then testing/refactor.

## Functional Highlights
- Native SwiftUI search bar (`.searchable`) on the main screen.
- In-app Discogs OAuth flow (request token + verifier exchange) with Keychain credential storage. (This was the longest part since it needs an OAuth manager comunicating with the keychain)
- Empty state with animated image rows sourced from Discogs API thumbnails
- Artist result list with thumbnails and detail navigation
- Artist detail with member sorting options for bands
- Releases sorted newest-to-oldest by year
- Filtering by year, --genre-- not fully completed, and label.
- Friendly error handling mapped from Discogs HTTP status codes, mapped from the developer documentation.


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
