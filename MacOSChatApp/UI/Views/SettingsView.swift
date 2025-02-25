import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            APIConfigView()
                .tabItem {
                    Label("API", systemImage: "key.fill")
                }
            
            ModelSettingsView()
                .tabItem {
                    Label("Model", systemImage: "gear")
                }
            
            ProfilesView()
                .tabItem {
                    Label("Profiles", systemImage: "person.crop.circle")
                }
            
            AppearanceView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }
            
            AdvancedView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

// Placeholder tab views
struct APIConfigView: View {
    var body: some View {
        VStack {
            Text("API Configuration")
                .font(.title)
            
            Spacer()
            
            Text("This is a placeholder for API configuration settings.")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct ModelSettingsView: View {
    var body: some View {
        VStack {
            Text("Model Settings")
                .font(.title)
            
            Spacer()
            
            Text("This is a placeholder for model settings.")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct AppearanceView: View {
    var body: some View {
        VStack {
            Text("Appearance")
                .font(.title)
            
            Spacer()
            
            Text("This is a placeholder for appearance settings.")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct AdvancedView: View {
    var body: some View {
        VStack {
            Text("Advanced Settings")
                .font(.title)
            
            Spacer()
            
            Text("This is a placeholder for advanced settings.")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// Preview provider for SwiftUI Canvas
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
