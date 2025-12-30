import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:signature/signature.dart';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/api_config.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_completion_screen.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';

class SignatureScreen extends StatefulWidget {
  final String orderId;
  final String meetingId;

  const SignatureScreen({
    Key? key,
    required this.orderId,
    required this.meetingId,
  }) : super(key: key);

  @override
  SignatureScreenState createState() => SignatureScreenState();
}

class SignatureScreenState extends State<SignatureScreen> {
  late final SignatureController _sigController;
  final MeetingService _meetingService = MeetingService();
  final Logger _logger = Logger();
  String meetingId = '';

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(
      penStrokeWidth: 8.0,
      penColor: Colors.black,
      exportPenColor: Colors.black,
      onDrawStart: () => _logger.d('✍️ Inicio de firma'),
      onDrawEnd: () => _logger.d('✅ Trazo finalizado'),
    );
  }

  @override
  void dispose() {
    _sigController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _exportSignaturePng() async {
    if (_sigController.isEmpty) {
      _logger.w('⚠️ Firma vacía');
      return null;
    }
    final bytes = await _sigController.toPngBytes();
    if (bytes == null || bytes.isEmpty) {
      _logger.e('❌ No se pudo exportar la firma a PNG');
      return null;
    }
    _logger.d('🖼️ PNG exportado: ${bytes.length} bytes');
    return bytes;
  }

  Future<void> _confirmAndUpload() async {
    final bytes = await _exportSignaturePng();
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La firma está vacía. Por favor, dibuja tu firma.'),
        ),
      );
      return;
    }

    // Vista previa antes de enviar
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vista previa de la firma'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueGrey, width: 1),
                    color: Colors.white,
                  ),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tamaño: ${bytes.length} bytes',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _uploadToBackend(bytes);
    await _meetingService.endMeeting(widget.meetingId);
  }

  Future<void> _uploadToBackend(Uint8List bytes) async {
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

      _logger.d('📤 Subiendo firma al backend...');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _logger.d('📥 Respuesta backend: ${response.statusCode}');

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        if (!mounted) return;
        // Ir a la vista del PDF
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderCompletionScreen(orderId: widget.orderId),
          ),
        );
      } else {
        _logger.e('❌ Error subiendo firma: ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error subiendo firma (${response.statusCode}).'),
          ),
        );
      }
    } catch (e) {
      _logger.e('❌ Excepción en subida: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
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
              color: const Color(0xFFE3F2FD), // azul claro para delimitar
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Capa inferior informativa
                  Container(
                    color: Colors.red.withOpacity(0.05),
                    child: const Center(
                      child: Text(
                        'ÁREA DE FIRMA',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Área de firma
                  Container(
                    color: Colors.white,
                    child: Signature(
                      controller: _sigController,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _sigController.clear();
                    },
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmAndUpload,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar y continuar'),
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
