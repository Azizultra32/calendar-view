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

// MARK: - Interaction Editor
struct InteractionEditorView: View {
    let interaction: Interaction
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    @State private var selectedContacts: Set<Contact> = []
    @State private var location: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var category: InteractionCategory = .meeting
    @State private var notes: String = ""
    @State private var selectedColor: Color = .blue

    private let colorOptions: [Color] = [
        .blue, .green, .red, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Participants Section
                Section {
                    NavigationLink {
                        ParticipantEditorView(
                            allContacts: allContacts,
                            selectedContacts: $selectedContacts
                        )
                    } label: {
                        HStack {
                            Text("Participants")
                            Spacer()
                            Text("\(selectedContacts.count)")
                                .foregroundColor(.gray)
                        }
                    }

                    // Show selected participants
                    ForEach(Array(selectedContacts), id: \.id) { participant in
                        HStack(spacing: 12) {
                            if let imageData = participant.avatarImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(participant.initial)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            Text(participant.name)
                            Spacer()
                            Button(action: { selectedContacts.remove(participant) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                } header: {
                    Text("WHO")
                }

                // Time Section
                Section {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("WHEN")
                }

                // Location Section
                Section {
                    TextField("Coffee Shop, Park, etc.", text: $location)
                } header: {
                    Text("WHERE")
                }

                // Category Section
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(InteractionCategory.allCases, id: \.self) { cat in
                            HStack {
                                Text(cat.icon)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("CATEGORY")
                }

                // Color Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("COLOR")
                }

                // Notes Section
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                } header: {
                    Text("NOTES")
                }
            }
            .navigationTitle("Edit Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { updateInteraction() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Pre-populate with existing data
            selectedContacts = Set(interaction.participants)
            location = interaction.locationName ?? ""
            startDate = interaction.startTime
            endDate = interaction.endTime
            category = interaction.category
            notes = interaction.notes ?? ""
            selectedColor = interaction.color
        }
    }

    private func updateInteraction() {
        // Update existing interaction
        interaction.startTime = startDate
        interaction.endTime = endDate
        interaction.locationName = location.isEmpty ? nil : location
        interaction.category = category
        interaction.notes = notes.isEmpty ? nil : notes
        interaction.colorHex = selectedColor.toHex()

        // Update participants
        interaction.participants = Array(selectedContacts)

        // Save changes
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Participant Editor (for editing mode)
struct ParticipantEditorView: View {
    let allContacts: [Contact]
    @Binding var selectedContacts: Set<Contact>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(allContacts) { contact in
                Button(action: { toggleContact(contact) }) {
                    HStack(spacing: 12) {
                        if let imageData = contact.avatarImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(contact.initial)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .foregroundColor(.white)
                            if let phone = contact.phoneNumbers.first {
                                Text(phone.number)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        if selectedContacts.contains(contact) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Edit Participants")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func toggleContact(_ contact: Contact) {
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            selectedContacts.insert(contact)
        }
    }
}

// MARK: - Interaction Builder
struct InteractionBuilderView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    @State private var selectedContacts: Set<Contact> = []
    @State private var location: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600) // 1 hour later
    @State private var category: InteractionCategory = .meeting
    @State private var notes: String = ""
    @State private var selectedColor: Color = .blue

    private let colorOptions: [Color] = [
        .blue, .green, .red, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Participants Section
                Section {
                    NavigationLink {
                        ParticipantPickerView(
                            allContacts: allContacts,
                            selectedContacts: $selectedContacts,
                            primaryContact: contact
                        )
                    } label: {
                        HStack {
                            Text("Participants")
                            Spacer()
                            Text("\(selectedContacts.count + 1)")
                                .foregroundColor(.gray)
                        }
                    }

                    // Show selected participants
                    ForEach(Array([contact] + Array(selectedContacts)), id: \.id) { participant in
                        HStack(spacing: 12) {
                            if let imageData = participant.avatarImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(participant.initial)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            Text(participant.name)
                            Spacer()
                            if participant.id != contact.id {
                                Button(action: { selectedContacts.remove(participant) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                } header: {
                    Text("WHO")
                }

                // Time Section
                Section {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("WHEN")
                }

                // Location Section
                Section {
                    TextField("Coffee Shop, Park, etc.", text: $location)
                } header: {
                    Text("WHERE")
                }

                // Category Section
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(InteractionCategory.allCases, id: \.self) { cat in
                            HStack {
                                Text(cat.icon)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("CATEGORY")
                }

                // Color Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("COLOR")
                }

                // Notes Section
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                } header: {
                    Text("NOTES")
                }
            }
            .navigationTitle("New Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveInteraction() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Primary contact is always included
            selectedContacts = []
        }
    }

    private func saveInteraction() {
        // Create new interaction
        let interaction = Interaction(
            startTime: startDate,
            endTime: endDate,
            location: location.isEmpty ? "Unknown Location" : location,
            category: category,
            notes: notes.isEmpty ? nil : notes
        )

        // Set color
        interaction.colorHex = selectedColor.toHex()

        // Add participants (primary contact + selected)
        var participants = [contact]
        participants.append(contentsOf: Array(selectedContacts))
        interaction.participants = participants

        // Save to SwiftData
        modelContext.insert(interaction)

        // Link to all participants
        for participant in participants {
            if !participant.interactions.contains(where: { $0.id == interaction.id }) {
                participant.interactions.append(interaction)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Participant Picker
struct ParticipantPickerView: View {
    let allContacts: [Contact]
    @Binding var selectedContacts: Set<Contact>
    let primaryContact: Contact
    @Environment(\.dismiss) private var dismiss

    var availableContacts: [Contact] {
        allContacts.filter { $0.id != primaryContact.id }
    }

    var body: some View {
        List {
            ForEach(availableContacts) { contact in
                Button(action: { toggleContact(contact) }) {
                    HStack(spacing: 12) {
                        if let imageData = contact.avatarImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(contact.initial)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .foregroundColor(.white)
                            if let phone = contact.phoneNumbers.first {
                                Text(phone.number)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        if selectedContacts.contains(contact) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Add Participants")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func toggleContact(_ contact: Contact) {
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            selectedContacts.insert(contact)
        }
    }
}

// MARK: - Helper Extensions

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

extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#0000FF" }

        let r = components[0]
        let g = components[1]
        let b = components[2]

        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}

extension Contact: Hashable {
    public static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
