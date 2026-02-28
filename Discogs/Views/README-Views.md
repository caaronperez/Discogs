# Views

SwiftUI UI layer for search, detail, releases, and shared components.

## Files
- `Search/SearchView.swift`: Main screen, native searchable field, empty state, and search results list.
- `Artist/ArtistDetailView.swift`: Artist profile, band members section, and navigation to releases.
- `Releases/ReleasesListView.swift`: Artist albums list sorted by newest release date with pagination.
- `Releases/ReleaseFilterSheet.swift`: Filter controls by year, genre, and label.
- `Components/GlassToolbarModifier.swift`: Liquid Glass-inspired toolbar button styling.
- `Components/SearchBarModifier.swift`: Search toolbar behavior helper.
- `Components/ImageMarqueeView.swift`: Animated empty-state image rows with alternating direction.
- `Settings/TokenSettingsView.swift`: Discogs token editor.

## Notes
- Navigation transitions use zoom-style animation.
- Empty state prompts token setup and artist search flow.
