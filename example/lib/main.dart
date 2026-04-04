import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:sharara_bluetooth/sharara_bluetooth.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});
  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  Stream<dynamic>? _deviceStream;
  bool _isConnecting = false;
  bool _isScanning = false;
  String? _connectingAddress;

  @override
  void initState() {
    super.initState();
    _toggleDiscovery();
  }

  Future<void> _toggleDiscovery() async {
    if (_isScanning) {
      await ShararaBluetooth.instance.cancelDiscovery();
    } else {
      _deviceStream = await ShararaBluetooth.instance.startDiscovery();
    }
    setState(() => _isScanning = !_isScanning);
  }

  Future<void> _handleConnect(BluetoothDevice device) async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _connectingAddress = device.address;
    });
    try {
      if (_isScanning) {
        await ShararaBluetooth.instance.cancelDiscovery();
        setState(() => _isScanning = false);
        await Future.delayed(const Duration(milliseconds: 600));
      }
      final bool success = await device.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Connected to ${device.name}" : "Connection Failed"),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingAddress = null;
        });
      }
    }
  }

  // --- REWRITTEN PRINT TEST: Using Frida Burst Logic ---
  Future<void> _printTest(BluetoothDevice device) async {
    final profile= await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm72, profile);
    final bytes = <int>[];
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text("Hello World"));
    bytes.addAll(generator.feed(2));
    await device.writeData(bytes);

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Printer Setup", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop_circle : Icons.search, color: Colors.blueAccent),
            onPressed: _toggleDiscovery,
          )
        ],
      ),
      body: Column(
        children: [
          if (_isScanning) const LinearProgressIndicator(backgroundColor: Colors.transparent),
          Expanded(
            child: StreamBuilder(
              stream: _deviceStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data is! List) {
                  return const Center(child: Text("Search for devices to begin", style: TextStyle(color: Colors.grey)));
                }
                final List<BluetoothDevice> devices = snapshot.data;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  itemBuilder: (context, index) => _buildDeviceTile(devices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BluetoothDevice device) {
    final isThisConnecting = _connectingAddress == device.address;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                child: const Icon(Icons.print, color: Colors.blueAccent),
              ),
              title: Text(device.name ?? "Unknown Printer", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(device.address ?? "", style: const TextStyle(fontSize: 12)),
              trailing: FutureBuilder<bool>(
                future: device.isConnected,
                builder: (context, snapshot) {
                  final connected = snapshot.data ?? false;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: connected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.circle, size: 12, color: connected ? Colors.green : Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isThisConnecting ? null : () => _handleConnect(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isThisConnecting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Connect", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => device.disconnect(),
                    icon: const Icon(Icons.link_off, color: Colors.redAccent),
                  ),
                  IconButton(
                    onPressed: () => _printTest(device),
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}