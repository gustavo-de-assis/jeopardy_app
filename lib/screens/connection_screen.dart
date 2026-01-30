import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  late TextEditingController _portController;
  late String _host;
  late String _protocol;
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(Uri.base.origin);
    _host = uri.host;
    _protocol = uri.scheme;
    _portController = TextEditingController(text: "3000");
    
    // Listen for connection status
    GameSocketService().onConnectionStatusChanged = (connected) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          if (connected) {
            _errorMessage = null;
            // Connection success! Now we can proceed.
            // We'll let the user click "ENTER LOBBY" manually to confirm.
          } else {
            _errorMessage = "Failed to connect. Check if the server is running and the port is correct.";
          }
        });
      }
    };
  }

  String get _apiUrl => "$_protocol://$_host:${_portController.text}";

  void _handleConnect() {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final finalApiUrl = _apiUrl;
    debugPrint("Connecting Host to API: $finalApiUrl");
    
    // Set base URL for API service
    ref.read(apiServiceProvider).setBaseUrl(finalApiUrl);
    
    // Initialize Socket connection
    GameSocketService().initConnection(finalApiUrl);
    
    // If it's already connected (re-clicking), proceed directly
    if (GameSocketService().isConnected) {
       Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = GameSocketService().isConnected;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'JEOPARTY',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'gyparody',
                  shadows: [
                    Shadow(offset: Offset(4, 4), blurRadius: 10, color: Colors.black45),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'HOST CONNECTION',
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 4,
                  color: Colors.amber,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isConnected ? Colors.green.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: _apiUrl,
                      version: QrVersions.auto,
                      size: 260.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    if (isConnected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text("CONNECTED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Scan this to connect mobile players',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  children: [
                    const Text(
                      'API Port (default: 3000)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _portController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      enabled: !isConnected,
                      style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                           _errorMessage = null; 
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 40),
              _isConnecting 
                ? const CircularProgressIndicator(color: Colors.amber)
                : ElevatedButton(
                    onPressed: isConnected ? () => Navigator.of(context).pushReplacementNamed('/') : _handleConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? Colors.green : Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    child: Text(
                      isConnected ? 'ENTER LOBBY' : 'CONNECT TO SERVER',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }
}
