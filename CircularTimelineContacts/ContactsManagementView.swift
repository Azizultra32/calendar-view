import SwiftUI
import SwiftData
import Contacts
import ContactsUI

struct ContactsManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Contact.name) private var contacts: [Contact]

    @State private var searchText = ""
    @State private var showingContactPicker = false
    @State private var selectedContactForInteraction: Contact?

    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search contacts...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding()

                // Contact list
                if filteredContacts.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredContacts) { contact in
                                ContactCardView(
                                    contact: contact,
                                    onDelete: { deleteContact(contact) },
                                    onCreateInteraction: { selectedContactForInteraction = contact }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingContactPicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { selectedContact in
                    importContact(selectedContact)
                }
            }
            .sheet(item: $selectedContactForInteraction) { contact in
                InteractionBuilderView(contact: contact)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Contacts Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            Text("Tap the + button to add contacts from your iPhone")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showingContactPicker = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Contact")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteContact(_ contact: Contact) {
        withAnimation {
            modelContext.delete(contact)
            try? modelContext.save()
        }
    }

    private func importContact(_ cnContact: CNContact) {
        // Create new Contact from CNContact
        let contact = Contact(
            name: "\(cnContact.givenName) \(cnContact.familyName)",
            initial: String(cnContact.givenName.prefix(1))
        )

        // Import phone numbers
        if let firstPhone = cnContact.phoneNumbers.first {
            let phoneNumber = PhoneNumber(
                label: "mobile",
                number: firstPhone.value.stringValue
            )
            contact.phoneNumbers = [phoneNumber]
        }

        // Import emails
        if let firstEmail = cnContact.emailAddresses.first {
            let email = EmailAddress(
                label: "home",
                address: firstEmail.value as String
            )
            contact.emailAddresses = [email]
        }

        // Import photo
        if let imageData = cnContact.imageData {
            contact.avatarImageData = imageData
        }

        // Import social profiles
        var socialProfiles: [SocialProfile] = []
        for profile in cnContact.socialProfiles {
            if let platformName = profile.value.service,
               let username = profile.value.username {
                if let platform = SocialPlatform.from(serviceName: platformName) {
                    let socialProfile = SocialProfile(
                        platform: platform,
                        handle: username
                    )
                    socialProfiles.append(socialProfile)
                }
            }
        }
        contact.socialProfiles = socialProfiles

        // Save to SwiftData
        modelContext.insert(contact)
        try? modelContext.save()
    }
}

// MARK: - Contact Card View
private struct ContactCardView: View {
    let contact: Contact
    let onDelete: () -> Void
    let onCreateInteraction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Avatar
                if let imageData = contact.avatarImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(contact.initial)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    if let phone = contact.phoneNumbers.first {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 12))
                            Text(phone.number)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.gray)
                    }

                    if let email = contact.emailAddresses.first {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 12))
                            Text(email.address)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.gray)
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onCreateInteraction) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Interaction")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }

                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("Remove")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - iOS Contact Picker
struct ContactPickerView: UIViewControllerRepresentable {
    let onContactSelected: (CNContact) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onContactSelected: onContactSelected, dismiss: dismiss)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (CNContact) -> Void
        let dismiss: DismissAction

        init(onContactSelected: @escaping (CNContact) -> Void, dismiss: DismissAction) {
            self.onContactSelected = onContactSelected
            self.dismiss = dismiss
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onContactSelected(contact)
            dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            dismiss()
        }
    }
}

// MARK: - Interaction Builder (Placeholder)
struct InteractionBuilderView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Create Interaction")
                    .font(.title)
                Text("With \(contact.name)")
                    .foregroundColor(.gray)

                // TODO: Add form to create interaction
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Helper extension for SocialPlatform
extension SocialPlatform {
    static func from(serviceName: String) -> SocialPlatform? {
        switch serviceName.lowercased() {
        case "instagram": return .instagram
        case "twitter", "x": return .twitter
        case "facebook": return .facebook
        case "linkedin": return .linkedIn
        case "tiktok": return .tikTok
        case "snapchat": return .snapchat
        default: return nil
        }
    }
}
