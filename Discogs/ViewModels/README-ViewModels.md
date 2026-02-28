# ViewModels

MVVM presentation logic for each screen.

## Files
- `SearchViewModel.swift`: Search query handling, debounce, pagination, and empty-state marquee image loading.
- `ArtistDetailViewModel.swift`: Artist details loading and band member sorting options.
- `ReleasesViewModel.swift`: Release pagination, newest-first sorting, and filtering by year/genre/label.

## Notes
- View models are `@MainActor` to keep UI state updates safe.
- Networking is injected through `DiscogsAPIProtocol` for testability.
