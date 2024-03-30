import CoreBluetooth

/**
 CoreBluetooth has 2 main components that we care about:
  1. CentralManager: scans for, discovers, connects to, manages peripherals - think of this as the client
  2. Peripheral: a device like the Arduino - think of this as the server
 
 On top of that, CB has 3 protocols we need to implement:
  1. CentralManagerDelegate: provides updates for the discovery of peripherals
  2. PeripheralDelegate: provides updates on a peripheral's services
  3. PeripheralManagerDelegate: provides updates on a peripheral's state: **including the payload**
 
 A peripheral has several things
  1. It offers services (battery service, device info service, etc.)
  2. Each service offers characteristics (battery level, serial number string, etc.)
  3. Each characteristic can have various properties (read, write, notify)
 */

class BluetoothModel: NSObject, ObservableObject {
    private var deviceName: String = "iPad"
    @Published var peripheralName: String = ""
    
    @Published var payload: [String: String] = [:]
    @Published var error: String = ""
    private var buffer: String = ""
    
    // Arduino-specific CBUUID
    private var CBUUID_Tx = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private var CBUUID_Rx = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    // CoreBluetooth
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
        
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func setPeripheralName(_ name: String) {
        self.peripheralName = name
    }
    
    func beginScanning() {
        if self.peripheralName.isEmpty {
            self.error = "Please set a peripheral target name."
            return
        }
        guard self.centralManager?.state == .poweredOn else {
            self.error = "\(deviceName) is not powered on."
            return
        }
        self.centralManager.scanForPeripherals(withServices: nil)
    }
    
    private func updateBuffer(_ data: String) {
        self.buffer += data
        
        // Look for a `packetNum` key-value to end the packet
        if self.buffer.range(of: "packetNum:[0-9]+", options: .regularExpression) != nil {
            self.payload = self.parsePayload(self.buffer)
            self.buffer = ""
        }
    }
    
    private func parsePayload(_ payload: String) -> [String: String] {
        var dataDict = [String: String]()
        let parts = payload.split(separator: ";").map(String.init)
        
        for part in parts {
            let kv = part.split(separator: ":", maxSplits: 1).map(String.init)
            if kv.count != 2 {
                continue
            }
            
            let key = kv[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let val = kv[1].trimmingCharacters(in: .whitespacesAndNewlines)
            dataDict[key] = val
        }
        
        return dataDict
    }
}

extension BluetoothModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("\(deviceName) is powered on.")
        case .poweredOff:
            print("\(deviceName) is powered of.")
        case .unsupported:
            print("\(deviceName) is unsupported.")
        case .unauthorized:
            print("\(deviceName) is unauthorized.")
        case .unknown:
            print("\(deviceName) is unknown.")
        case .resetting:
            print("\(deviceName) is resetting.")
        @unknown default:
            print("\(deviceName) error.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == self.peripheralName {
            self.centralManager.stopScan()
            self.centralManager.connect(peripheral, options: nil)
            self.peripheral = peripheral
            
            print("Connected to \(peripheralName).")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

extension BluetoothModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            self.error = "Error discovering peripheral services: \(error!.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else {
            self.error = "Cannot access services in \(peripheralName)."
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            self.error = "Cannot access characteristics in \(peripheralName)."
            return
        }
        
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(CBUUID_Tx) {
                txCharacteristic = characteristic
            }
            
            if characteristic.uuid.isEqual(CBUUID_Rx) {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == rxCharacteristic,
              let characteristicValue = characteristic.value,
              let ASCIIstring = NSString(
                data: characteristicValue,
                encoding: String.Encoding.utf8.rawValue
              ) else {
            self.error = "Error decoding characteristic value."
            return
        }
        
        let data = String(ASCIIstring)
        print("\(peripheralName): \(data)")
        
        self.error = ""
        self.updateBuffer(data)
    }
}

extension BluetoothModel: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("\(peripheralName) is powered on.")
        case .poweredOff:
            print("\(peripheralName) is powered off.")
        case .unsupported:
            print("\(peripheralName) is unsupported.")
        case .unauthorized:
            print("\(peripheralName) is unauthorized.")
        case .unknown:
            print("\(peripheralName) is unknown.")
        case .resetting:
            print("\(peripheralName) is resetting.")
        @unknown default:
            print("\(peripheralName) error.")
        }
    }
}
