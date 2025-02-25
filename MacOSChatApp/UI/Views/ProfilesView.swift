import SwiftUI

struct ProfilesView: View {
    var body: some View {
        VStack {
            Text("Profiles")
                .font(.title)
            
            Spacer()
            
            List {
                ProfileRow(name: "Default Profile", modelName: "gpt-3.5-turbo", isDefault: true)
                ProfileRow(name: "GPT-4 Profile", modelName: "gpt-4", isDefault: false)
                ProfileRow(name: "Ollama Local", modelName: "llama2", isDefault: false)
            }
            
            Spacer()
            
            HStack {
                Button("Add Profile") {
                    // Placeholder for add profile action
                }
                
                Spacer()
                
                Button("Edit") {
                    // Placeholder for edit action
                }
                
                Button("Delete") {
                    // Placeholder for delete action
                }
            }
            .padding()
        }
        .padding()
    }
}

struct ProfileRow: View {
    let name: String
    let modelName: String
    let isDefault: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(modelName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isDefault {
                Text("Default")
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// Preview provider for SwiftUI Canvas
struct ProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilesView()
    }
}
