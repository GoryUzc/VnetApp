// lib/widgets/data_table_custom.dart
import 'package:flutter/material.dart';

class DataTableCustom extends StatelessWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final Function(String)? onDelete;
  final Function(String)? onEdit;

  const DataTableCustom({
    super.key,
    required this.columns,
    required this.rows,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns:
            columns.map((column) => DataColumn(label: Text(column))).toList(),
        rows:
            rows.map((row) {
              final List<DataCell> cells = [];
              for (final column in columns) {
                final isActionsColumn = column == 'Acciones';
                if (isActionsColumn && (onDelete != null || onEdit != null)) {
                  cells.add(
                    DataCell(
                      Row(
                        children: [
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => onEdit!(row['id'].toString()),
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => onDelete!(row['id'].toString()),
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
    );
  }
}
