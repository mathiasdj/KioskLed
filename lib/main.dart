import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buttons',
      debugShowCheckedModeBanner: false,
      home: MQTTPage(),
    );
  }
}

class MQTTPage extends StatefulWidget {
  const MQTTPage({super.key});

  @override
  _MQTTPageState createState() => _MQTTPageState();
}

class _MQTTPageState extends State<MQTTPage> {
  String _broker = '192.168.4.1'; // Default broker IP
  final int _port = 1883;
  final String _clientId = 'flutter_client';
  final String _topic = 'LedControl';
  late MqttServerClient _client;
  String _connectionStatus = 'Disconnected';
  String _receivedMessage = "No messages yet";
  double _currentSliderValue = 50;

  final TextEditingController _brokerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _brokerController.text = _broker; // Pre-fill with default broker IP
  }

  Future<void> _connectToBroker() async {
    setState(() {
      _connectionStatus = 'Connecting...';
    });

    // Use the broker IP entered in the text field
    _broker = _brokerController.text;

    _client = MqttServerClient(_broker, _clientId);
    _client.port = _port;
    _client.keepAlivePeriod = 20;
    _client.logging(on: true);
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client.connectionMessage = connMessage;

    try {
      await _client.connect();
    } on Exception catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
      });
      _client.disconnect();
    }
  }

  void _onConnected() {
    setState(() {
      _connectionStatus = 'Connected';
    });
    _client.subscribe(_topic, MqttQos.atLeastOnce);
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMessage = messages[0].payload as MqttPublishMessage;
      final String message =
      MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      setState(() {
        _receivedMessage = message;
      });
    });
  }

  void _onDisconnected() {
    setState(() {
      _connectionStatus = 'Disconnected';
    });
  }

  void _publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(_topic, MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter MQTT Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text('Connection Status: $_connectionStatus'),
            Text('Received Message: $_receivedMessage'),
            const SizedBox(height: 20),
            TextField(
              controller: _brokerController,
              decoration: const InputDecoration(
                labelText: 'Broker IP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connectToBroker,
              child: const Text('Connect'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStyledButton('Red', Colors.red, '255,0,0'),
                      _buildStyledButton(
                          'Green', Colors.green, '0,255,0'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStyledButton('Blue', Colors.blue, '0,0,255'),
                      _buildStyledButton('White', Colors.white, '255,255,255'),
                    ],
                  ),
                  Slider(
                    value: _currentSliderValue,
                    max: 100,
                    divisions: 10,
                    label: _currentSliderValue.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _currentSliderValue = value;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => _publishMessage('0'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    child: const Text('Off'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledButton(String text, Color color, String message) {
    return ElevatedButton(
      onPressed: () => _publishMessage(message),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(100, 150),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
