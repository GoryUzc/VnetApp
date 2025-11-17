import 'package:flutter/material.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class DataTableCustom extends StatelessWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? title;
  final Function(String)? onDelete;
  final Function(String)? onEdit;
  final Function(String)? onView;

  const DataTableCustom({
    // ← Agregado 'const' aquí
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.onDelete,
    this.onEdit,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TÍTULO VISIBLE
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            columns:
                columns
                    .map((column) => DataColumn(label: Text(column)))
                    .toList(),
            rows:
                rows.map((row) {
                  final List<DataCell> cells = [];
                  for (final column in columns) {
                    final isActionsColumn = column == 'Acciones';
                    if (isActionsColumn &&
                        (onDelete != null ||
                            onEdit != null ||
                            onView != null)) {
                      cells.add(
                        DataCell(
                          Row(
                            children: [
                              if (onEdit != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed:
                                      () => onEdit!(row['id'].toString()),
                                ),
                              if (onDelete != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => onDelete!(row['id'].toString()),
                                ),
                              if (onView != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.description,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed:
                                      () => onView!(row['id'].toString()),
                                ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final value = row[column];
                      cells.add(
                        DataCell(
                          Text((value ?? '').toString()),
                          onTap: () {
                            if (onEdit != null) {
                              onEdit!(row['id'].toString());
                            }
                          },
                        ),
                      );
                    }
                  }
                  return DataRow(cells: cells);
                }).toList(),
          ),
        ),
      ],
    );
  }
}
