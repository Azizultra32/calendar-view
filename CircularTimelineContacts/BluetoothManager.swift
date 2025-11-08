import Foundation
import CoreBluetooth
import SwiftData
import Combine

/// Manages Bluetooth Low Energy proximity detection for nearby app users
@Observable
final class BluetoothManager: NSObject {
    // MARK: - Configuration

    // Unique service UUID for CircularTimeline app
    private static let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-4789-A012-3456789ABCDE")

    // Characteristic UUIDs
    private static let userIDCharacteristicUUID = CBUUID(string: "B1C2D3E4-F5A6-4890-B123-456789ABCDEF")
    private static let nameCharacteristicUUID = CBUUID(string: "C1D2E3F4-A5B6-4901-C234-56789ABCDEF0")

    // MARK: - Properties

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?

    var isScanning = false
    var isAdvertising = false
    var isBluetoothReady = false
    var isEnabled = false // User's privacy toggle

    // Discovered nearby users
    var nearbyUsers: [NearbyUser] = []

    // Current user's identity
    private var currentUserID: UUID
    private var currentUserName: String

    // Publishers for SwiftUI
    let nearbyUsersPublisher = PassthroughSubject<[NearbyUser], Never>()

    // MARK: - Initialization

    init(userID: UUID, userName: String) {
        self.currentUserID = userID
        self.currentUserName = userName
        super.init()
    }

    // MARK: - Public Methods

    /// Start proximity detection (both scanning and advertising)
    func startProximityDetection() {
        guard isEnabled else { return }

        // Initialize managers if needed
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }
    }

    /// Stop proximity detection
    func stopProximityDetection() {
        stopScanning()
        stopAdvertising()
    }

    /// Enable/disable proximity feature
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        if enabled {
            startProximityDetection()
        } else {
            stopProximityDetection()
            nearbyUsers.removeAll()
            nearbyUsersPublisher.send([])
        }
    }

    /// Update current user's display name
    func updateUserName(_ name: String) {
        currentUserName = name

        // Restart advertising with new name
        if isAdvertising {
            stopAdvertising()
            startAdvertising()
        }
    }

    // MARK: - Private Methods - Scanning

    private func startScanning() {
        guard let central = centralManager, central.state == .poweredOn else { return }

        // Scan for nearby CircularTimeline users
        central.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        isScanning = true
        print("🔵 Started scanning for nearby users...")
    }

    private func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        print("🔵 Stopped scanning")
    }

    // MARK: - Private Methods - Advertising

    private func startAdvertising() {
        guard let peripheral = peripheralManager, peripheral.state == .poweredOn else { return }

        // Create service
        let service = CBMutableService(type: Self.serviceUUID, primary: true)

        // User ID characteristic (read-only, unique identifier)
        let userIDData = currentUserID.uuidString.data(using: .utf8)!
        let userIDCharacteristic = CBMutableCharacteristic(
            type: Self.userIDCharacteristicUUID,
            properties: [.read],
            value: userIDData,
            permissions: [.readable]
        )

        // Name characteristic (read-only, display name)
        let nameData = currentUserName.data(using: .utf8)!
        let nameCharacteristic = CBMutableCharacteristic(
            type: Self.nameCharacteristicUUID,
            properties: [.read],
            value: nameData,
            permissions: [.readable]
        )

        service.characteristics = [userIDCharacteristic, nameCharacteristic]

        // Add service
        peripheral.add(service)

        // Start advertising
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID],
            CBAdvertisementDataLocalNameKey: "CircularTimeline"
        ])

        isAdvertising = true
        print("🔵 Started advertising as: \(currentUserName)")
    }

    private func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        isAdvertising = false
        print("🔵 Stopped advertising")
    }

    // MARK: - Helper Methods

    private func addOrUpdateNearbyUser(_ user: NearbyUser) {
        if let index = nearbyUsers.firstIndex(where: { $0.id == user.id }) {
            // Update existing user
            nearbyUsers[index] = user
        } else {
            // Add new user
            nearbyUsers.append(user)
        }

        nearbyUsersPublisher.send(nearbyUsers)
    }

    private func removeNearbyUser(withID id: UUID) {
        nearbyUsers.removeAll { $0.id == id }
        nearbyUsersPublisher.send(nearbyUsers)
    }

    /// Clean up users not seen in the last 30 seconds
    func cleanupStaleUsers() {
        let now = Date()
        nearbyUsers.removeAll { user in
            now.timeIntervalSince(user.lastSeen) > 30
        }
        nearbyUsersPublisher.send(nearbyUsers)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("🔵 Bluetooth is powered ON")
            isBluetoothReady = true
            if isEnabled {
                startScanning()
            }

        case .poweredOff:
            print("🔵 Bluetooth is powered OFF")
            isBluetoothReady = false
            nearbyUsers.removeAll()
            nearbyUsersPublisher.send([])

        case .unauthorized:
            print("🔵 Bluetooth is unauthorized")
            isBluetoothReady = false

        case .unsupported:
            print("🔵 Bluetooth is not supported")
            isBluetoothReady = false

        default:
            isBluetoothReady = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Calculate approximate distance from RSSI
        let distance = estimateDistance(from: RSSI.intValue)

        // Connect to read characteristics
        peripheral.delegate = self
        central.connect(peripheral, options: nil)

        print("🔵 Discovered peripheral: \(peripheral.identifier), RSSI: \(RSSI), Distance: ~\(String(format: "%.1f", distance))m")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("🔵 Connected to peripheral: \(peripheral.identifier)")
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔵 Disconnected from peripheral: \(peripheral.identifier)")
    }

    /// Estimate distance in meters from RSSI value
    /// Based on the log-distance path loss model
    private func estimateDistance(from rssi: Int) -> Double {
        let txPower = -59.0 // Calibrated RSSI at 1 meter

        if rssi == 0 {
            return -1.0 // Unknown
        }

        let ratio = Double(rssi) / txPower
        if ratio < 1.0 {
            return pow(ratio, 10)
        } else {
            return 0.89976 * pow(ratio, 7.7095) + 0.111
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == Self.serviceUUID {
                peripheral.discoverCharacteristics([
                    Self.userIDCharacteristicUUID,
                    Self.nameCharacteristicUUID
                ], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }

        // Parse user data
        if characteristic.uuid == Self.userIDCharacteristicUUID {
            if let userIDString = String(data: data, encoding: .utf8),
               let userID = UUID(uuidString: userIDString) {

                // Don't add yourself
                guard userID != currentUserID else { return }

                // Store temporarily, wait for name characteristic
                // In a real implementation, you'd batch these together
                print("🔵 Found user ID: \(userID)")
            }
        } else if characteristic.uuid == Self.nameCharacteristicUUID {
            if let userName = String(data: data, encoding: .utf8) {
                // Create nearby user
                // Note: In production, you'd want to correlate userID and name properly
                let nearbyUser = NearbyUser(
                    id: UUID(), // This should be the actual user ID from the other characteristic
                    name: userName,
                    rssi: -60, // You'd store this from discovery
                    distance: 2.5,
                    lastSeen: Date()
                )

                addOrUpdateNearbyUser(nearbyUser)
                print("🔵 Added nearby user: \(userName)")
            }
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("🔵 Peripheral manager is powered ON")
            if isEnabled {
                startAdvertising()
            }

        case .poweredOff:
            print("🔵 Peripheral manager is powered OFF")

        case .unauthorized:
            print("🔵 Peripheral manager is unauthorized")

        case .unsupported:
            print("🔵 Peripheral manager is not supported")

        default:
            break
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("🔵 Error adding service: \(error)")
        } else {
            print("🔵 Service added successfully")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("🔵 Error starting advertising: \(error)")
        } else {
            print("🔵 Advertising started successfully")
        }
    }
}

// MARK: - NearbyUser Model

struct NearbyUser: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rssi: Int // Signal strength
    var distance: Double // Estimated distance in meters
    var lastSeen: Date
    var isConnected: Bool = false
    var contact: Contact? // Matched contact if available

    var distanceDescription: String {
        if distance < 1 {
            return "Very close"
        } else if distance < 3 {
            return "Nearby"
        } else if distance < 10 {
            return "~\(Int(distance))m away"
        } else {
            return "Far"
        }
    }

    var signalStrength: SignalStrength {
        if rssi > -50 {
            return .excellent
        } else if rssi > -60 {
            return .good
        } else if rssi > -70 {
            return .fair
        } else {
            return .weak
        }
    }

    enum SignalStrength {
        case excellent
        case good
        case fair
        case weak

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "yellow"
            case .weak: return "red"
            }
        }
    }
}
