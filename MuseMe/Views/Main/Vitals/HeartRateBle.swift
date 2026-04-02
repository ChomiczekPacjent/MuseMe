//
//  BLE.swift
//  MuseMe
//
//  Created by Błażej Faber on 12/11/2025.
//

import CoreBluetooth
import Combine

class HeartRateBLE: NSObject, ObservableObject {
    static let shared = HeartRateBLE()
    
    @Published var heartRateBLE: Double = 0
    @Published var status: String = "Skanuję..."

    private var central: CBCentralManager!
    private var hrPeripheral: CBPeripheral?

    private let HR_SERVICE = CBUUID(string: "180D")
    private let HR_MEASUREMENT = CBUUID(string: "2A37")

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func start() {
        guard central.state == .poweredOn else {
            status = "Bluetooth wyłączony"
            return
        }
        status = "Skanuję urządzenia..."
        central.scanForPeripherals(withServices: [HR_SERVICE])
    }

    func stop() {
        if let p = hrPeripheral {
            central.cancelPeripheralConnection(p)
        }
        central.stopScan()
        status = "Zatrzymano"
    }
}

extension HeartRateBLE: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            start()
        } else {
            status = "Bluetooth nieaktywny (\(central.state.rawValue))"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        hrPeripheral = p
        status = "Znaleziono: \(p.name ?? "BLE") — łączę..."
        central.stopScan()
        central.connect(p, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
        status = "Połączono z \(p.name ?? "BLE")"
        p.delegate = self
        p.discoverServices([HR_SERVICE])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        status = "Rozłączono — ponawiam..."
        hrPeripheral = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.start()
        }
    }
}

extension HeartRateBLE: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach {
            peripheral.discoverCharacteristics([HR_MEASUREMENT], for: $0)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?
            .filter { $0.uuid == HR_MEASUREMENT }
            .forEach { peripheral.setNotifyValue(true, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == HR_MEASUREMENT,
              let data = characteristic.value else { return }

        let flags = data[0]
        let is16bit = (flags & 0x01) != 0
        let bpm: Int

        if is16bit, data.count >= 3 {
            bpm = Int(UInt16(data[1]) | (UInt16(data[2]) << 8))
        } else if data.count >= 2 {
            bpm = Int(data[1])
        } else { return }

        DispatchQueue.main.async {
            self.heartRateBLE = Double(bpm)
            self.status = "Odbieram HR: \(bpm)"
            
            if BPMChanger.shared.isSessionActive {
                HRSessionTracker.shared.add(bpm)
            }
        }

    }
}

