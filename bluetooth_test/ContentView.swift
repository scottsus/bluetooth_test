import SwiftUI

struct ContentView: View {
    @State private var peripheralName = "Adafruit Bluefruit LE"
    @State private var hasStartedScanning = false
    @ObservedObject private var bluetoothModel = BluetoothModel()
    
    var body: some View {
        VStack {
            if !hasStartedScanning {
                Text("Enter peripheral name")
                    .bold()
                TextField("Arduino", text: $peripheralName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Scan for devices") {
                    bluetoothModel.setPeripheralName(peripheralName)
                    bluetoothModel.beginScanning()
                    hasStartedScanning = true
                }
                .padding()
            }
            
            else {
                Text("Current Info:")
                    .font(.largeTitle)
                
                if !bluetoothModel.error.isEmpty {
                    Text(bluetoothModel.error)
                } else {
                    let infoStr = """
                    Time: \(bluetoothModel.payload["time"] ?? "Unknown")
                    Temperature: \(bluetoothModel.payload["temp"] ?? "Unknown")°C
                    Altitude: \(bluetoothModel.payload["PAltitude"] ?? "Unknown")m
                    Pressure: \(bluetoothModel.payload["pressure"] ?? "Unknown")kPA
                    Sequence: \(bluetoothModel.payload["packetNum"] ?? "Unknown")
                    """
                    Text(infoStr)
                        .font(.title)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
