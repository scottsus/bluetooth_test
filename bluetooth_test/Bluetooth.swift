import CoreBluetooth

class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate {
    var peripheralName: String
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var txCh: CBCharacteristic!
    private var rxCh: CBCharacteristic!
    
    @Published var data: String = ""
    @Published var err: BluetoothError? = nil
        
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager.scanForPeripherals(withServices: nil)
        } else {
            self.err = BluetoothError.poweredOff
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "Adafruit Bluefruit LE" {
//            self.peripherals.append(peripheral)
            print("Appended Adafruit Bluefruit!!!")
            self.centralManager?.stopScan()
            
            self.centralManager?.connect(peripheral, options: nil)
            self.peripheral = peripheral
            print("Connecting to Adafruit!")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        peripheral.delegate = self
        print("Did connect!!!")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected.")
    }
    
}

extension BluetoothViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
//        print("Found \(characteristics.count) characteristics!")
        
        for ch in characteristics {
            if ch.uuid.isEqual(CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")) { // transmit
                txCh = ch
                print("Transmit:", txCh!)
            } else if ch.uuid.isEqual(CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")) { // receive
                rxCh = ch
                peripheral.setNotifyValue(true, for: rxCh!)
                peripheral.readValue(for: ch)
                print("Receive:", rxCh!)
            }
        }
//        print("done looking for characteristics")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        var chASCIIValue = NSString()
        guard ch == rxCh,
              let chVal = ch.value,
              let ASCIIstring = NSString(data: chVal, encoding: String.Encoding.utf8.rawValue) else { return }
        
        chASCIIValue = ASCIIstring
        print("Received: \(chASCIIValue as String)")
    }
}

extension BluetoothViewModel: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("Did update?", peripheral.state)
        if peripheral.state == .poweredOn {
            print("Peripheral is powered on")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device is subscribed, start sending over data!")
    }
}
