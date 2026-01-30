import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ScanServerScreen extends ConsumerStatefulWidget {
  const ScanServerScreen({super.key});

  @override
  ConsumerState<ScanServerScreen> createState() => _ScanServerScreenState();
}

class _ScanServerScreenState extends ConsumerState<ScanServerScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isScanning = false;

  void _onConnect(String url) {
    if (url.isEmpty) return;
    
    // Normalize URL
    String normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http')) {
      normalizedUrl = 'http://$normalizedUrl';
    }

    debugPrint('Connecting to: $normalizedUrl');
    
    // Initialize services
    GameSocketService().initConnection(normalizedUrl);
    ref.read(apiServiceProvider).setBaseUrl(normalizedUrl);
    
    // Navigate to Home
    if (mounted) {
       Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'JEOPARTY',
                    style: TextStyle(
                      fontSize: 60,
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
                    'PLAYER CONNECT',
                    style: TextStyle(
                      fontSize: 18,
                      letterSpacing: 4,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 60),
                  if (_isScanning)
                    Column(
                      children: [
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.amber, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MobileScanner(
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  final String code = barcode.rawValue!;
                                  debugPrint('Barcode found! $code');
                                  setState(() => _isScanning = false);
                                  _onConnect(code);
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => setState(() => _isScanning = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cancel Scan'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isScanning = true),
                          icon: const Icon(Icons.qr_code_scanner, size: 28),
                          label: const Text('SCAN HOST QR CODE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                            minimumSize: const Size(double.infinity, 70),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR ENTER MANUALLY',
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 1),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                        const SizedBox(height: 25),
                        TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g., http://192.168.1.5:3000',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.amber, width: 1),
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.amber, size: 30),
                                onPressed: () => _onConnect(_urlController.text),
                              ),
                            ),
                          ),
                          onSubmitted: (val) => _onConnect(val),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
