import SwiftUI

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        Group {
            Text("Hello russell")
//            Text(bluetoothViewModel.helloStr)
//                .font(.largeTitle)
//            List(bluetoothViewModel.peripheralNames, id: \.self) { peripheral in
//                Text(peripheral)
        }
    }
}

#Preview {
    ContentView()
}
