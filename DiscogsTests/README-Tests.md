# Tests

Critical unit tests implemented with Swift Testing.

## Files
- `NetworkingTests.swift`: Status-code error mapping and request-building verification.
- `SearchViewModelTests.swift`: Search success and no-results behavior.
- `ReleasesViewModelTests.swift`: Sorting, filtering, and paginated appending behavior.

## Notes
- API dependencies are mocked through `DiscogsAPIProtocol` and `HTTPClientProtocol`.
- Tests focus on business logic and request correctness, independent of UI rendering.
