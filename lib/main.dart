import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buttons',
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
  String _broker = '192.168.8.62'; // Default broker IP
  final int _port = 1883;
  final String _clientId = 'flutter_client';
  final String _topic = 'LedControl';
  late MqttServerClient _client;
  String _connectionStatus = 'Disconnected';
  String _receivedMessage = "No messages yet";

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
                      _buildStyledButton('Blink', 'assets/images/blink.svg', '1'),
                      _buildStyledButton(
                          'Rainbow', 'assets/images/rainbow.svg', '2'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStyledButton('Snake', 'assets/images/snake.svg', '3'),
                      _buildStyledButton('Fade', 'assets/images/fade.svg', '4'),
                    ],
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

  Widget _buildStyledButton(String text, String assetPath, String message) {
    return ElevatedButton(
      onPressed: () => _publishMessage(message),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(100, 150),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          SvgPicture.asset(
            assetPath,
            width: 70,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
