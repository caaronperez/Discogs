//
//  ReleaseFilterSheet.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import SwiftUI

struct ReleaseFilterSheet: View {
    @ObservedObject var viewModel: ReleasesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.ui.filterSortSectionTitle) {
                    Picker(viewModel.ui.filterSortByTitle, selection: $viewModel.selectedSort) {
                        ForEach(ArtistReleaseSort.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }

                    Picker(viewModel.ui.filterOrderTitle, selection: $viewModel.selectedSortOrder) {
                        ForEach(ArtistReleaseSortOrder.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }

                Section(viewModel.ui.filterYearSectionTitle) {
                    Picker(viewModel.ui.filterYearPickerTitle, selection: $viewModel.filters.year) {
                        Text(viewModel.ui.filterAllOptionTitle).tag(Int?.none)
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text(String(year)).tag(Optional(year))
                        }
                    }
                }

                Section(viewModel.ui.filterGenreSectionTitle) {
                    Picker(viewModel.ui.filterGenrePickerTitle, selection: $viewModel.filters.genre) {
                        Text(viewModel.ui.filterAllOptionTitle).tag(String?.none)
                        ForEach(viewModel.availableGenres, id: \.self) { genre in
                            Text(genre).tag(Optional(genre))
                        }
                    }
                }

                Section(viewModel.ui.filterLabelSectionTitle) {
                    Picker(viewModel.ui.filterLabelPickerTitle, selection: $viewModel.filters.label) {
                        Text(viewModel.ui.filterAllOptionTitle).tag(String?.none)
                        ForEach(viewModel.availableLabels, id: \.self) { label in
                            Text(label).tag(Optional(label))
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .appThemeBackground()
            .navigationTitle(viewModel.ui.filterSheetTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(viewModel.ui.filterResetButtonTitle) {
                        viewModel.resetFilters()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.ui.filterDoneButtonTitle) {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedSort) { _, _ in
            Task { await viewModel.reloadWithCurrentSort() }
        }
        .onChange(of: viewModel.selectedSortOrder) { _, _ in
            Task { await viewModel.reloadWithCurrentSort() }
        }
    }
}

#Preview {
    ReleaseFilterSheetPreview()
}

private struct ReleaseFilterSheetPreview: View {
    @StateObject private var viewModel = ReleasesViewModel(
        artistID: 100,
        api: MockDiscogsAPI(releasesResponsesByPage: [1: .previewReleases], defaultReleasesResponse: .previewReleases)
    )

    var body: some View {
        ReleaseFilterSheet(viewModel: viewModel)
            .task {
                await viewModel.loadInitial()
            }
    }
}
