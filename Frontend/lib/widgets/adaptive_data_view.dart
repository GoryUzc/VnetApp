import 'package:flutter/material.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class AdaptiveDataView extends StatefulWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? title;
  final Function(String)? onDelete;
  final Function(String)? onEdit;
  final Function(String)? onView;
  final Function()? onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final Map<String, String> columnLabels;

  const AdaptiveDataView({
    super.key,
    required this.columns,
    required this.rows,
    required this.title,
    this.onDelete,
    this.onEdit,
    required this.onView,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.columnLabels,
    required this.hasMore,
  });

  @override
  State<AdaptiveDataView> createState() => _AdaptiveDataViewState();
}

class _AdaptiveDataViewState extends State<AdaptiveDataView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, bool> _expandedItems = {};
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredRows = [];

  @override
  void initState() {
    super.initState();
    _filteredRows = List.from(widget.rows);
    _searchController.addListener(_onSearchChanged);
    _setupScrollListener();
  }

  @override
  void didUpdateWidget(AdaptiveDataView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _filteredRows = List.from(widget.rows);
      _applySearchFilter();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          widget.hasMore &&
          !widget.isLoadingMore &&
          widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    });
  }

  void _onSearchChanged() {
    _applySearchFilter();
  }

  void _applySearchFilter() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredRows = List.from(widget.rows);
      } else {
        _filteredRows =
            widget.rows.where((row) {
              return row.entries.any((entry) {
                final value = entry.value?.toString().toLowerCase() ?? '';
                return value.contains(query);
              });
            }).toList();
      }
      _expandedItems.clear();
    });
  }

  List<String> get _importantColumns {
    final importantKeywords = ['nombre', 'fecha', 'estado', 'cliente'];
    final result = <String>[];

    for (final column in widget.columns) {
      final lowerColumn = column.toLowerCase();

      //Incluir ID y acciones
      if (lowerColumn == 'id' || lowerColumn == 'acciones') {
        result.add(column);
        continue;
      }

      if (importantKeywords.any((keyword) => lowerColumn.contains(keyword))) {
        result.add(column);
      }

      if (result.length >= 6) break;
    }

    return result;
  }

  String _getColumnLabel(String column) {
    return widget.columnLabels[column] ?? column;
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return '${value.day}/${value.month}/${value.year}, ${value.hour}:${value.minute}';
    }
    final str = value.toString();

    if (str.length > 30) {
      return '${str.substring(0, 27)}...';
    }
    return str;
  }

  Widget _buildMobileCard(Map<String, dynamic> row, int index) {
    final isExpanded = _expandedItems[index] ?? false;
    final importantCols = _importantColumns;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2.00,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expandedItems[index] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (row.containsKey('id'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ID: ${row['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    importantCols
                        .where(
                          (col) =>
                              col != 'id' &&
                              col != 'Acciones' &&
                              row.containsKey(col),
                        )
                        .take(3)
                        .map((col) => _buildFieldRow(col, row[col]))
                        .toList(),
              ),

              if (!isExpanded && widget.columns.length > importantCols.length)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Toca para ver más',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.columns
                          .where(
                            (col) => col != 'Acciones' && row.containsKey(col),
                          )
                          .where(
                            (col) =>
                                !importantCols.contains(col) || col == 'id',
                          )
                          .map((col) => _buildFieldRow(col, row[col]))
                          .toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Acciones
              if (widget.onEdit != null ||
                  widget.onView != null ||
                  widget.onDelete != null)
                _buildMobileActions(row),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getColumnLabel(label),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatValue(value),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActions(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (widget.onView != null)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Ver'),
              onPressed: () => widget.onView!(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

        if (widget.onView != null && widget.onEdit != null)
          const SizedBox(width: 8),

        if (widget.onEdit != null)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
              onPressed: () => widget.onEdit!(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.1),
                foregroundColor: Colors.amber[800],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

        if (widget.onEdit != null && widget.onDelete != null)
          const SizedBox(width: 8),

        if (widget.onDelete != null)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_outlined, size: 16),
              label: const Text('Eliminar'),
              onPressed: () => _showDeleteDialog(id, row),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletView() {
    final importantCols =
        _importantColumns
            .where((col) => col != 'Acciones')
            .take(4) // Máximo 4 columnas en tablet
            .toList();

    if (importantCols.isEmpty) return _buildMobileView();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 16,
        columns: [
          ...importantCols.map(
            (col) => DataColumn(
              label: Text(
                _getColumnLabel(col),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (widget.onEdit != null ||
              widget.onView != null ||
              widget.onDelete != null)
            const DataColumn(label: Text('Acciones')),
        ],
        rows:
            _filteredRows.map((row) {
              return DataRow(
                cells: [
                  ...importantCols.map((col) {
                    return DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          _formatValue(row[col]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    );
                  }),
                  if (widget.onEdit != null ||
                      widget.onView != null ||
                      widget.onDelete != null)
                    DataCell(_buildDesktopActions(row)),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 16,
        columns: [
          ...widget.columns.map(
            (col) => DataColumn(
              label: Text(
                _getColumnLabel(col),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        rows:
            _filteredRows.map((row) {
              return DataRow(
                cells:
                    widget.columns.map((col) {
                      if (col == 'Acciones') {
                        return DataCell(_buildDesktopActions(row));
                      }

                      return DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            _formatValue(row[col]),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        onTap:
                            widget.onEdit != null && row['id'] != null
                                ? () => widget.onEdit!(row['id'].toString())
                                : null,
                      );
                    }).toList(),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDesktopActions(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onView != null)
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 18),
            color: Colors.blue,
            onPressed: () => widget.onView!(id),
            tooltip: 'Ver detalles',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),

        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: Colors.amber,
            onPressed: () => widget.onEdit!(id),
            tooltip: 'Editar',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),

        if (widget.onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outlined, size: 18),
            color: Colors.red,
            onPressed: () => _showDeleteDialog(id, row),
            tooltip: 'Eliminar',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  void _showDeleteDialog(String id, Map<String, dynamic> row) {
    final name =
        row['nombre'] ?? row['name'] ?? row['cliente'] ?? 'este elemento';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Estás seguro de eliminar $name?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete!(id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredRows.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredRows.length) {
          return _buildLoadMoreIndicator();
        }
        return _buildMobileCard(_filteredRows[index], index);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!widget.hasMore) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child:
            widget.isLoadingMore
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: widget.onLoadMore,
                  child: const Text('Cargar más'),
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No hay datos para mostrar'
                : 'No se encontraron resultados',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                _applySearchFilter();
              },
              child: const Text('Limpiar búsqueda'),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _applySearchFilter();
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 900;

    // **SOLUCIÓN DEFINITIVA**: Envolver todo en un Container con altura definida
    return Container(
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ¡IMPORTANTE!
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

          // Barra de búsqueda
          _buildSearchBar(),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_filteredRows.length} ${_filteredRows.length == 1 ? 'elemento' : 'elementos'} encontrados',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),

          const SizedBox(height: 8),

          // Vista principal - **SOLUCIÓN CLAVE**
          if (_filteredRows.isEmpty)
            Expanded(child: _buildEmptyState())
          else if (isMobile)
            Expanded(child: _buildMobileView())
          else if (isTablet)
            Expanded(child: _buildTabletView())
          else
            Expanded(child: _buildDesktopView()),
        ],
      ),
    );
  }
}
