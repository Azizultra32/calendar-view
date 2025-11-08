import SwiftUI
import SwiftData

/// View showing nearby app users detected via Bluetooth
struct ProximityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]

    @State private var bluetoothManager: BluetoothManager
    @State private var nearbyUsers: [NearbyUser] = []
    @State private var selectedUser: NearbyUser?
    @State private var showingConnectionRequest = false

    init(bluetoothManager: BluetoothManager) {
        _bluetoothManager = State(initialValue: bluetoothManager)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
                statusBar

                if bluetoothManager.isEnabled {
                    if nearbyUsers.isEmpty {
                        emptyStateView
                    } else {
                        nearbyUsersList
                    }
                } else {
                    disabledStateView
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("", isOn: Binding(
                        get: { bluetoothManager.isEnabled },
                        set: { bluetoothManager.setEnabled($0) }
                    ))
                    .labelsHidden()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            nearbyUsers = bluetoothManager.nearbyUsers
        }
        .onReceive(bluetoothManager.nearbyUsersPublisher) { users in
            nearbyUsers = users
        }
        .sheet(item: $selectedUser) { user in
            UserConnectionSheet(user: user, onConnect: {
                connectToUser(user)
            })
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            if bluetoothManager.isScanning {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }

    private var statusColor: Color {
        if !bluetoothManager.isEnabled {
            return .gray
        } else if bluetoothManager.isBluetoothReady && bluetoothManager.isScanning {
            return .green
        } else if bluetoothManager.isBluetoothReady {
            return .yellow
        } else {
            return .red
        }
    }

    private var statusText: String {
        if !bluetoothManager.isEnabled {
            return "Proximity detection disabled"
        } else if !bluetoothManager.isBluetoothReady {
            return "Bluetooth unavailable"
        } else if bluetoothManager.isScanning {
            return "Scanning for nearby users..."
        } else {
            return "Ready to scan"
        }
    }

    // MARK: - Nearby Users List

    private var nearbyUsersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("\(nearbyUsers.count) \(nearbyUsers.count == 1 ? "person" : "people") nearby")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                ForEach(nearbyUsers) { user in
                    NearbyUserCard(user: user)
                        .onTapGesture {
                            selectedUser = user
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.wave.2")
                .font(.system(size: 64))
                .foregroundColor(.blue.opacity(0.6))

            VStack(spacing: 12) {
                Text("No One Nearby")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                Text("When someone with the app is nearby,\nthey'll appear here automatically.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Text("Make sure:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                VStack(alignment: .leading, spacing: 6) {
                    CheckItem(text: "Bluetooth is enabled")
                    CheckItem(text: "Both users have proximity enabled")
                    CheckItem(text: "You're within ~30 meters")
                }
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Disabled State

    private var disabledStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.6))

            VStack(spacing: 12) {
                Text("Proximity Detection Off")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                Text("Enable proximity detection to find\nnearby app users via Bluetooth.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                bluetoothManager.setEnabled(true)
            }) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Enable Proximity")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Helper Methods

    private func connectToUser(_ user: NearbyUser) {
        // TODO: Implement connection request flow
        print("🔵 Requesting connection to: \(user.name)")
    }
}

// MARK: - Nearby User Card

private struct NearbyUserCard: View {
    let user: NearbyUser

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(user.name.prefix(1).uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(user.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    // Distance
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text(user.distanceDescription)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.6))

                    // Signal strength indicator
                    HStack(spacing: 2) {
                        ForEach(0..<4) { bar in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(signalColor(for: bar, strength: user.signalStrength))
                                .frame(width: 3, height: CGFloat(4 + bar * 2))
                        }
                    }
                }
            }

            Spacer()

            // Connect button
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.blue)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func signalColor(for bar: Int, strength: NearbyUser.SignalStrength) -> Color {
        let activeColor: Color
        switch strength {
        case .excellent: activeColor = .green
        case .good: activeColor = .blue
        case .fair: activeColor = .yellow
        case .weak: activeColor = .red
        }

        let activeBars: Int
        switch strength {
        case .excellent: activeBars = 4
        case .good: activeBars = 3
        case .fair: activeBars = 2
        case .weak: activeBars = 1
        }

        return bar < activeBars ? activeColor : Color.white.opacity(0.2)
    }
}

// MARK: - Check Item

private struct CheckItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - User Connection Sheet

private struct UserConnectionSheet: View {
    let user: NearbyUser
    let onConnect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(user.name.prefix(1).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(spacing: 12) {
                    Text(user.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text(user.distanceDescription)
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }

                VStack(spacing: 16) {
                    Button(action: {
                        onConnect()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Send Connection Request")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        // Create quick interaction
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Create Interaction")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }
}
