import SwiftUI

struct EmployeesList: View {
    let hotelId: UUID
    @StateObject private var viewModel: EmployeesViewModel

    init(hotelId: UUID) {
        self.hotelId = hotelId
        _viewModel = StateObject(wrappedValue: EmployeesViewModel(hotelId: hotelId))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.employees.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $viewModel.selectedEmployee) { employee in
            EmployeeDetailPanel(
                employee: employee,
                isProcessing: viewModel.isProcessing(employee.id),
                onChangeRole: { role in
                    Task {
                        await viewModel.updateRole(for: employee.id, to: role)
                    }
                },
                onRemove: {
                    Task {
                        await viewModel.removeEmployee(employee)
                    }
                }
            )
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                viewModel.retryLoad()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadEmployees()
        }
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Employees")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Text("\(viewModel.totalCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search employees...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)

                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // Employee list grouped by role
            ScrollView {
                LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                    ForEach(viewModel.sortedRoles, id: \.self) { role in
                        if let roleEmployees = viewModel.employeesByRole[role], !roleEmployees.isEmpty {
                            Section {
                                VStack(spacing: 12) {
                                    ForEach(roleEmployees) { employee in
                                        EmployeeCard(
                                            employee: employee,
                                            isSelected: viewModel.selectedEmployee?.id == employee.id,
                                            onTap: {
                                                viewModel.selectEmployee(employee)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            } header: {
                                HStack {
                                    Text(role.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text("\(roleEmployees.count)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color(.systemGroupedBackground))
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }

            if viewModel.filteredEmployees.isEmpty && !viewModel.searchText.isEmpty {
                searchEmptyView
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading employees...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Employees")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No employees have been added to this hotel yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Results")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No employees match '\(viewModel.searchText)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -100)
    }
}

#Preview("Populated") {
    EmployeesList(hotelId: UUID())
}

#Preview("Loading") {
    struct LoadingPreview: View {
        var body: some View {
            EmployeesList(hotelId: UUID())
                .onAppear {
                    // Simulate loading state
                }
        }
    }
    return LoadingPreview()
}

#Preview("Search Active") {
    struct SearchPreview: View {
        var body: some View {
            EmployeesList(hotelId: UUID())
        }
    }
    return SearchPreview()
}
