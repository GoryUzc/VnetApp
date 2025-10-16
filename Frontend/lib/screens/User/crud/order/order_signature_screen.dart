import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/api_config.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'dart:ui' as ui;

class SignatureScreen extends StatefulWidget {
  final String orderId;

  const SignatureScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  bool _isSigned = false;

  Future<Uint8List?> _getSignatureBytes() async {
    if (!_isSigned) return null;
    final state = _signatureKey.currentState;
    if (state == null) return null;

    final image = await state.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _uploadSignature() async {
    final bytes = await _getSignatureBytes();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero firma el documento')),
      );
      return;
    }

    try {
      final token = await AuthService().getToken();
      final url = ApiConfig.endpoint(
        '/orders/upload-signature/${widget.orderId}',
      );

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        http.MultipartFile.fromBytes(
          'signature',
          bytes,
          filename: 'signature_${widget.orderId}.png',
        ),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Firma guardada con éxito')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(
          'Error al subir firma: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firma del Cliente')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: SfSignaturePad(
                key: _signatureKey,
                backgroundColor: Colors.white,
                onDrawStart: () {
                  setState(() {
                    _isSigned = true;
                  });
                  return true;
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed:
                      _isSigned
                          ? () {
                            _signatureKey.currentState?.clear();
                            setState(() {
                              _isSigned = false;
                            });
                          }
                          : null,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSigned ? _uploadSignature : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Firma'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
