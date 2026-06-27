import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../services/nexus_api_service.dart';
import '../state/nexus_controller.dart';
import '../theme/nexus_palette.dart';
import '../widgets/ui_kit.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NexusController>().loadAdminDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final stats = ctrl.adminDashboard;
    final muted = NexusPalette.textMuted(context);

    return Column(
      children: [
        _AdminHeader(
          title: 'ADMIN DASHBOARD',
          onBack: () => ctrl.navigate(ViewState.account),
        ),
        Expanded(
          child: ctrl.isLoadingAdmin
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 112),
                  children: [
                    if (ctrl.adminError != null) ...[
                      Text(ctrl.adminError!, style: TextStyle(color: muted)),
                      const SizedBox(height: 12),
                    ],
                    if (stats != null) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatCard(
                            label: 'PRODUCTS',
                            value: '${stats.productCount}',
                            color: NexusPalette.cyan,
                          ),
                          _StatCard(
                            label: 'ORDERS',
                            value: '${stats.orderCount}',
                            color: NexusPalette.violet,
                          ),
                          _StatCard(
                            label: 'USERS',
                            value: '${stats.userCount}',
                            color: NexusPalette.magenta,
                          ),
                          _StatCard(
                            label: 'REVENUE',
                            value: '\$${stats.totalRevenue.toStringAsFixed(0)}',
                            color: Colors.amberAccent.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Data source: ${stats.dataSource}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _AdminNavTile(
                      title: 'MANAGE PRODUCTS',
                      subtitle: 'Create, edit, delete catalog items',
                      icon: Icons.inventory_2_rounded,
                      onTap: () => ctrl.navigate(ViewState.adminProducts),
                    ),
                    _AdminNavTile(
                      title: 'MANAGE ORDERS',
                      subtitle: 'View all orders and update status',
                      icon: Icons.receipt_long_rounded,
                      onTap: () => ctrl.navigate(ViewState.adminOrders),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NexusController>().loadAdminProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);

    return Column(
      children: [
        _AdminHeader(
          title: 'PRODUCTS',
          onBack: () => ctrl.navigate(ViewState.adminDashboard),
          action: IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => ctrl.navigate(ViewState.adminProductForm),
          ),
        ),
        Expanded(
          child: ctrl.isLoadingAdmin
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: ctrl.loadAdminProducts,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 112),
                    itemCount: ctrl.adminProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final product = ctrl.adminProducts[i];
                      return _ProductAdminTile(
                        product: product,
                        onEdit: () => ctrl.navigate(
                          ViewState.adminProductForm,
                          params: {'id': product.id},
                        ),
                        onDelete: () async {
                          try {
                            await ctrl.deleteAdminProduct(product.id);
                            if (context.mounted) {
                              showNexusToast(context, 'PRODUCT DELETED');
                            }
                          } on NexusApiException catch (e) {
                            if (context.mounted) {
                              showNexusToast(context, e.message.toUpperCase());
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
        if (ctrl.adminProducts.isEmpty && !ctrl.isLoadingAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 120),
            child: Text('No products loaded', style: TextStyle(color: muted)),
          ),
      ],
    );
  }
}

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _category = TextEditingController(text: 'Laptops');
  final _price = TextEditingController();
  final _image = TextEditingController();
  bool _isNew = true;
  bool _isDeal = false;
  bool _saving = false;
  String? _editId;

  static const _categories = [
    'Laptops',
    'Desktops',
    'Components',
    'Peripherals',
    'Monitors',
    'Networking',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<NexusController>();
      final id = ctrl.viewParams?['id'] as String?;
      if (id == null || id.isEmpty) return;
      _editId = id;
      Product? product;
      for (final p in ctrl.adminProducts) {
        if (p.id == id) {
          product = p;
          break;
        }
      }
      if (product == null) {
        for (final p in ctrl.allCatalogProducts) {
          if (p.id == id) {
            product = p;
            break;
          }
        }
      }
      if (product == null) return;
      _id.text = product.id;
      _name.text = product.name;
      _category.text = product.category;
      _price.text = product.price.toStringAsFixed(2);
      _image.text = product.image;
      _isNew = product.isNew ?? false;
      _isDeal = product.isDeal ?? false;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ctrl = context.read<NexusController>();
    final price = double.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty || price == null || _image.text.trim().isEmpty) {
      showNexusToast(context, 'FILL REQUIRED FIELDS');
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        if (_editId == null) 'id': _id.text.trim(),
        'name': _name.text.trim(),
        'category': _category.text.trim(),
        'price': price,
        'image': _image.text.trim(),
        'isNew': _isNew,
        'isDeal': _isDeal,
        'specs': {'cpu': 'TBD', 'ram': 'TBD', 'storage': 'TBD'},
      };
      if (_editId != null) {
        await ctrl.updateAdminProduct(_editId!, payload);
      } else {
        if (_id.text.trim().isEmpty) {
          if (mounted) showNexusToast(context, 'PRODUCT ID REQUIRED');
          return;
        }
        await ctrl.createAdminProduct(payload);
      }
      if (!mounted) return;
      showNexusToast(context, _editId == null ? 'PRODUCT CREATED' : 'PRODUCT UPDATED');
      ctrl.navigate(ViewState.adminProducts);
    } on NexusApiException catch (e) {
      if (mounted) showNexusToast(context, e.message.toUpperCase());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final editing = _editId != null;

    return Column(
      children: [
        _AdminHeader(
          title: editing ? 'EDIT PRODUCT' : 'NEW PRODUCT',
          onBack: () => ctrl.navigate(ViewState.adminProducts),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 112),
            children: [
              if (!editing)
                _field('Product ID', _id, hint: 'e.g. lap-99'),
              _field('Name', _name),
              DropdownButtonFormField<String>(
                value: _categories.contains(_category.text)
                    ? _category.text
                    : _categories.first,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category.text = v ?? 'Laptops'),
              ),
              const SizedBox(height: 12),
              _field('Price', _price, keyboard: TextInputType.number),
              _field('Image URL', _image),
              SwitchListTile(
                title: const Text('Mark as NEW'),
                value: _isNew,
                onChanged: (v) => setState(() => _isNew = v),
              ),
              SwitchListTile(
                title: const Text('Mark as DEAL'),
                value: _isDeal,
                onChanged: (v) => setState(() => _isDeal = v),
              ),
              const SizedBox(height: 16),
              GradientRgbButton(
                onPressed: _saving ? () {} : () => _save(),
                child: Text(_saving ? 'SAVING…' : 'SAVE PRODUCT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller,
      {String? hint, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NexusController>().loadAdminOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();

    return Column(
      children: [
        _AdminHeader(
          title: 'ALL ORDERS',
          onBack: () => ctrl.navigate(ViewState.adminDashboard),
        ),
        Expanded(
          child: ctrl.isLoadingAdmin
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: ctrl.loadAdminOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 112),
                    itemCount: ctrl.adminOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final record = ctrl.adminOrders[i];
                      return _OrderAdminTile(
                        record: record,
                        onStatusChanged: (status) async {
                          try {
                            await ctrl.updateAdminOrderStatus(
                              record.summary.id,
                              status,
                            );
                            if (context.mounted) {
                              showNexusToast(context, 'STATUS UPDATED');
                            }
                          } on NexusApiException catch (e) {
                            if (context.mounted) {
                              showNexusToast(context, e.message.toUpperCase());
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.title,
    required this.onBack,
    this.action,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
                color: Colors.amberAccent.shade400,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .35)),
        color: color.withValues(alpha: .08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NexusPalette.borderSubtle(context)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.amberAccent.shade400),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: NexusPalette.iconMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductAdminTile extends StatelessWidget {
  const _ProductAdminTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = NexusPalette.textMuted(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NexusPalette.borderSubtle(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${product.category} · \$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: muted, fontSize: 12)),
                Text(product.id, style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
    );
  }
}

class _OrderAdminTile extends StatelessWidget {
  const _OrderAdminTile({
    required this.record,
    required this.onStatusChanged,
  });

  final AdminOrderRecord record;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final order = record.summary;
    final muted = NexusPalette.textMuted(context);
    const statuses = ['processing', 'shipped', 'delivered', 'cancelled'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NexusPalette.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.id, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '${order.date} · \$${order.total.toStringAsFixed(2)} · user ${record.userId}',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: statuses.firstWhere(
              (s) => s == order.status.name,
              orElse: () => 'processing',
            ),
            decoration: const InputDecoration(labelText: 'Status'),
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                .toList(),
            onChanged: (v) {
              if (v != null) onStatusChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
