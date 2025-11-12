import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let isLoading: Bool
    let canSearch: Bool
    let onSearch: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Hotels")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(height: 44)
                    .onSubmit {
                        onSearch()
                    }
                
                Button(action: onSearch) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(!canSearch)
            }
        }
    }
}