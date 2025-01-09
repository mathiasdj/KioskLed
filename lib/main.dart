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
      home: MQTTPage(), // Using MQTTPage instead of a simple home
    );
  }
}

class MQTTPage extends StatefulWidget {
  const MQTTPage({super.key});

  @override
  _MQTTPageState createState() => _MQTTPageState();
}

class _MQTTPageState extends State<MQTTPage> {
  final String _broker = '192.168.8.62'; // Replace with your broker's IP
  final int _port = 1883;
  final String _clientId = 'flutter_client';
  final String _topic = 'LedControl';
  late MqttServerClient _client;
  String _receivedMessage = "No messages yet";

  @override
  void initState() {
    super.initState();
    _connectToBroker();
  }

  Future<void> _connectToBroker() async {
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
      print('Connecting to the MQTT broker...');
      await _client.connect();
    } on Exception catch (e) {
      print('Connection failed: $e');
      _client.disconnect();
    }
  }

  void _onConnected() {
    print('Connected to the broker');
    setState(() {
      _client.subscribe(_topic, MqttQos.atLeastOnce);
      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage recMessage = messages[0].payload as MqttPublishMessage;
        final String message =
        MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
        setState(() {
          _receivedMessage = message;
        });
        print('Received message: $message');
      });
    });
  }

  void _onDisconnected() {
    print('Disconnected from the broker');
  }

  void _publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(_topic, MqttQos.atLeastOnce, builder.payload!);
    print('Published message: $message');
  }

  @override
  void dispose() {
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
            Text('Received Message: $_receivedMessage'),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(bottom: 50),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _publishMessage('1'); // Send 1 when Blink button is pressed
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 150),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Blink'),
                      SvgPicture.asset(
                        'assets/images/blink.svg', // Path to your SVG
                        width: 70,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage('2'); // Send 2 when Snake button is pressed
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 150),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Rainbow'),
                      SvgPicture.asset(
                        'assets/images/rainbow.svg', // Path to your SVG
                        width: 70,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 50),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _publishMessage('3'); // Send 3 when Rainbow button is pressed
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 150),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Snake'),
                      SvgPicture.asset(
                        'assets/images/snake.svg', // Path to your SVG
                        width: 70,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _publishMessage('4'); // Send 4 when Fade button is pressed
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 150),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Fade'),
                      SvgPicture.asset(
                        'assets/images/fade.svg', // Path to your SVG
                        width: 70,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 50),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _publishMessage('0'); // Send 0 when Off button is pressed
                  },
                  child: const Text('Off'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
