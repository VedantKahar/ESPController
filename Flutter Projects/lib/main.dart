import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
// import 'package:material_symbols/material_symbols.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP8266 Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DeviceControlPage(),
    );
  }
}

class DeviceControlPage extends StatefulWidget {
  @override
  _DeviceControlPageState createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  final database = FirebaseDatabase.instance.ref();

  bool _acState = false;
  bool _fanState = false;
  bool _heaterState = false;
  bool _isLoading = true;
  String _connectionStatus = 'Connecting to Firebase...';

  @override
  void initState() {
    super.initState();
    _loadDeviceStates();
  }

  Future<void> _loadDeviceStates() async {
    try {
      final snapshot = await database.child('Devices').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;

        setState(() {
          _acState = data['ac'] == 'on';
          _fanState = data['fan'] == 'on';
          _heaterState = data['heater'] == 'on';
          _connectionStatus = 'Connected to Firebase';
        });
      } else {
        _connectionStatus = 'Connected (no data found)';
      }
    } catch (e) {
      _connectionStatus = 'Firebase connection error';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _toggleDevice(String device, bool value) async {
    setState(() {
      switch (device) {
        case 'ac':
          _acState = value;
          break;
        case 'fan':
          _fanState = value;
          break;
        case 'heater':
          _heaterState = value;
          break;
      }
    });

    try {
      await database.child('Devices/$device').set(value ? 'on' : 'off');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('$device ${value ? 'turned on' : 'turned off'}'),
      //     backgroundColor: Colors.blue,
      //     duration: Duration(seconds: 1),
      //   ),
      // );
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Failed to update $device'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    }
  }

  Widget _buildDeviceCard(String deviceName, bool state, IconData icon, Color color, Function(bool) onChanged) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: state ? color : Colors.grey,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 14,
                      color: state ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: state,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP8266 Controller (Firebase)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Icon(
                  _connectionStatus.contains("Connected")
                      ? Icons.wifi
                      : Icons.wifi_off,
                  color: _connectionStatus.contains("Connected")
                      ? Colors.green
                      : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  _connectionStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _connectionStatus.contains("Connected")
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDeviceCard('Air Conditioner', _acState, Icons.ac_unit,
                    Colors.blue, (value) => _toggleDevice('ac', value)),
                _buildDeviceCard('Fan', _fanState, Icons.air , Colors.orange,
                        (value) => _toggleDevice('fan', value)),
                _buildDeviceCard('Heater', _heaterState, Icons.whatshot,
                    Colors.red, (value) => _toggleDevice('heater', value)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _loadDeviceStates,
              icon: Icon(Icons.refresh),
              label: Text('Refresh from Firebase'),
              style: ElevatedButton.styleFrom(
                padding:
                EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
