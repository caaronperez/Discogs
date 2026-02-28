# Utilities

Shared utilities used across the app.

## Files
- `ToastManager.swift`: In-app toast state manager and reusable toast overlay view.
- `AsyncImageCache.swift`: Actor-based in-memory image cache plus reusable `CachedAsyncImage`.

## Notes
- Toasts centralize user messages for API errors, no-results states, and token guidance.
- Cached images reduce repeated network image requests and improve list/marquee performance.
