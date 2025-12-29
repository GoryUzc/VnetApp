import 'package:flutter/material.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/theme/app_text_styles.dart';

class DeslizanteContainer extends StatefulWidget {
  final List<Map<String, dynamic>> items; // ej: contratos
  final VoidCallback onConnect; // acción al tocar

  const DeslizanteContainer({
    Key? key,
    required this.items,
    required this.onConnect,
  }) : super(key: key);

  @override
  State<DeslizanteContainer> createState() => _DeslizanteContainerState();
}

class _DeslizanteContainerState extends State<DeslizanteContainer> {
  bool _isVisible = false;

  void _show() => setState(() => _isVisible = true);
  void _hide() => setState(() => _isVisible = false);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón para abrir
        if (!_isVisible)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _show,
                icon: const Icon(Icons.keyboard_arrow_up),
                label: const Text('Ver más'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

        // Container deslizante con ListView filtrado
        if (_isVisible)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Más información',
                        style: AppTextStyles.subtitle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _hide,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.items.length,
                      itemBuilder: (_, index) {
                        final item = widget.items[index];
                        final title =
                            (item['title'] ?? item['nro_contract'] ?? 'Sin ID')
                                .toString();
                        final subtitle =
                            (item['subtitle'] ??
                                    item['tecnico'] ??
                                    'Sin técnico')
                                .toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.home_work,
                              color: AppColors.primaryColor,
                            ),
                            title: Text(title),
                            subtitle: Text(subtitle),
                            trailing: ElevatedButton(
                              onPressed: widget.onConnect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Conectar'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
