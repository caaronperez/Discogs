# Networking

This module handles all Discogs API communication.

## Files
- `APIConfig.swift`: API base URL, pagination size (`per_page = 30`), OAuth consumer config, and User-Agent.
- `HTTPClient.swift`: Generic async HTTP client that injects OAuth `Authorization` headers and maps HTTP status errors.
- `APIError.swift`: User-friendly status-code and OAuth/networking error mapping.
- `DiscogsAPI.swift`: Endpoints for artist search, artist detail, and artist releases plus data models.
- `DiscogsOAuth.swift`: Discogs OAuth 1.0a request-token + access-token flow and request signing.

## Notes
- Auth priority: OAuth 1.0a header, then personal token header, then consumer key/secret query fallback.
- OAuth and personal token are optional for read operations.
- Every paginated request uses 30 items per page.
- API status codes are mapped to app-friendly messages.
