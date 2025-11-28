import SwiftUI

struct EmployeesList: View {
    let hotelId: UUID

    @State private var searchText = ""
    @State private var selectedEmployee: EmployeeMock?
    @State private var showingDetailPanel = false
    @State private var isLoading = false

    // Using mock data for UI-first implementation
    private var employees: [EmployeeMock] {
        MockData.employees
    }

    private var filteredEmployees: [EmployeeMock] {
        if searchText.isEmpty {
            return employees
        }
        return employees.filter { employee in
            employee.name.localizedCaseInsensitiveContains(searchText) ||
            employee.email.localizedCaseInsensitiveContains(searchText) ||
            employee.role.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var employeesByRole: [HotelRole: [EmployeeMock]] {
        Dictionary(grouping: filteredEmployees) { $0.role }
    }

    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if employees.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingDetailPanel) {
            if let employee = selectedEmployee {
                EmployeeDetailPanel(employee: employee)
            }
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

                    Text("\(employees.count)")
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

                    TextField("Search employees...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
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
                    ForEach(sortedRoles, id: \.self) { role in
                        if let roleEmployees = employeesByRole[role], !roleEmployees.isEmpty {
                            Section {
                                VStack(spacing: 12) {
                                    ForEach(roleEmployees) { employee in
                                        EmployeeCard(
                                            employee: employee,
                                            isSelected: selectedEmployee?.id == employee.id,
                                            onTap: {
                                                selectedEmployee = employee
                                                showingDetailPanel = true
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

            if filteredEmployees.isEmpty && !searchText.isEmpty {
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

            Text("No employees match '\(searchText)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -100)
    }

    private var sortedRoles: [HotelRole] {
        // Sort roles in logical order: Admin, Manager, Front Desk, Housekeeping, Maintenance
        let order: [HotelRole] = [.admin, .manager, .frontDesk, .housekeeping, .maintenance]
        return order.filter { employeesByRole[$0] != nil }
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
