import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/api_config.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_completion_screen.dart';
import 'dart:ui' as ui;
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

class SignatureScreen extends StatefulWidget {
  final String orderId;
  final String meetingId;

  const SignatureScreen({
    Key? key,
    required this.orderId,
    required this.meetingId,
  }) : super(key: key);

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  bool _isSigned = false;
  final MeetingService _meetingService = MeetingService();
  // final Logger _logger = Logger();

  Future<Uint8List?> _getSignatureBytes() async {
    if (!_isSigned) return null;
    final state = _signatureKey.currentState;
    if (state == null) return null;

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final image = await state.toImage(pixelRatio: pixelRatio * 2); // ui.Image
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    // ↓↓↓ comprimir ↓↓↓
    final originalBytes = byteData.buffer.asUint8List();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) return originalBytes;

    final resized = img.copyResize(decoded, width: 800); // 800 px max
    return img.encodePng(resized, level: 4); // 0-9 (4 = buena compresión)
  }

  // Sube la firma al servidor
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
          contentType: MediaType('image', 'png'),
        ),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final end = await _meetingService.endMeeting(widget.meetingId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Firma guardada con éxito')),
        );
        if (!mounted) return;
        // Ir a pantalla de cierre de instalación para generar/descargar PDF
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderCompletionScreen(orderId: widget.orderId),
          ),
        );
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al guardar firma: $e')));
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
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (_) {},
                onHorizontalDragUpdate: (_) {},
                child: SfSignaturePad(
                  key: _signatureKey,
                  backgroundColor: Colors.white,
                  strokeColor: Colors.black,
                  maximumStrokeWidth: 5.0,
                  minimumStrokeWidth: 2.0,
                  onDrawStart: () {
                    setState(() => _isSigned = true);
                    return true;
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_isSigned)
                  ElevatedButton.icon(
                    onPressed: () {
                      _signatureKey.currentState?.clear();
                      setState(() => _isSigned = false);
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSigned ? _uploadSignature : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Finalizar instalacion'),
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
