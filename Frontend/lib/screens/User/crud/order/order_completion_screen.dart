import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/User/worker/home_worker_screen.dart';
import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class OrderCompletionScreen extends StatefulWidget {
  final String orderId;
  const OrderCompletionScreen({super.key, required this.orderId});

  @override
  State<OrderCompletionScreen> createState() => _OrderCompletionScreenState();
}

class _OrderCompletionScreenState extends State<OrderCompletionScreen> {
  final _logger = Logger();
  final _orderService = OrderService();
  bool _loading = false;

  Future<void> _previewPdf() async {
    setState(() => _loading = true);
    try {
      await _orderService.pdfOrderView(widget.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vista previa de PDF generada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, st) {
      _logger.e('Error preview pdf', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar vista previa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _loading = true);
    try {
      await _orderService.pdfOrder(widget.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, st) {
      _logger.e('Error download pdf', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text('Cierre de instalación'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 12),
              const Text(
                'Instalación completada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Orden: ${widget.orderId}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (_loading) const CircularProgressIndicator(),
              if (!_loading) ...[
                FilledButton.icon(
                  onPressed: _previewPdf,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Previsualizar PDF'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar PDF'),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const HomeWorkerScreen(), // Cambia a HomeAdminScreen si es necesario
                      ),
                      (route) => false, // Elimina todas las rutas anteriores
                    );
                  },

                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
