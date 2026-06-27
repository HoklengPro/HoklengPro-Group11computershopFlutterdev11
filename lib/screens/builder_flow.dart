import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../state/nexus_controller.dart';
import '../theme/nexus_palette.dart';
import '../widgets/ui_kit.dart';

const _labels = [
  BuilderStep.cpu,
  BuilderStep.motherboard,
  BuilderStep.ram,
  BuilderStep.gpu,
  BuilderStep.storage,
  BuilderStep.psu,
  BuilderStep.casePart,
];

String _labelForStep(BuilderStep step) => switch (step) {
      BuilderStep.cpu => 'CPU',
      BuilderStep.motherboard => 'MOTHERBOARD',
      BuilderStep.ram => 'MEMORY',
      BuilderStep.gpu => 'GRAPHICS',
      BuilderStep.storage => 'STORAGE',
      BuilderStep.psu => 'POWER',
      BuilderStep.casePart => 'CASE',
    };

IconData _iconForStep(BuilderStep step) => switch (step) {
      BuilderStep.cpu => Icons.memory_rounded,
      BuilderStep.motherboard => Icons.dashboard_rounded,
      BuilderStep.ram => Icons.dns_rounded,
      BuilderStep.gpu => Icons.desktop_windows_rounded,
      BuilderStep.storage => Icons.sd_storage_rounded,
      BuilderStep.psu => Icons.flash_on_rounded,
      BuilderStep.casePart => Icons.inventory_2_rounded,
    };

bool _filled(BuilderStep step, BuilderState sel) => switch (step) {
      BuilderStep.cpu => sel.cpu != null,
      BuilderStep.motherboard => sel.motherboard != null,
      BuilderStep.ram => sel.ram != null,
      BuilderStep.gpu => sel.gpu != null,
      BuilderStep.storage => sel.storage != null,
      BuilderStep.psu => sel.psu != null,
      BuilderStep.casePart => sel.casePart != null,
    };

NexusBuilderPart? _chosen(BuilderStep step, BuilderState sel) =>
    switch (step) {
      BuilderStep.cpu => sel.cpu,
      BuilderStep.motherboard => sel.motherboard,
      BuilderStep.ram => sel.ram,
      BuilderStep.gpu => sel.gpu,
      BuilderStep.storage => sel.storage,
      BuilderStep.psu => sel.psu,
      BuilderStep.casePart => sel.casePart,
    };

class BuilderLaboratory extends StatefulWidget {
  const BuilderLaboratory({super.key});

  @override
  State<BuilderLaboratory> createState() => _BuilderLaboratoryState();
}

class _BuilderLaboratoryState extends State<BuilderLaboratory> {
  BuilderState sel = BuilderState();
  int index = 0;

  BuilderStep get step => _labels[index];

  void _assign(NexusBuilderPart part) {
    switch (step) {
      case BuilderStep.cpu:
        sel.cpu = part as CpuPart;
        break;
      case BuilderStep.motherboard:
        sel.motherboard = part as MotherboardPart;
        break;
      case BuilderStep.ram:
        sel.ram = part as RamPart;
        break;
      case BuilderStep.gpu:
        sel.gpu = part as GpuPart;
        break;
      case BuilderStep.storage:
        sel.storage = part as StoragePart;
        break;
      case BuilderStep.psu:
        sel.psu = part as PsuPart;
        break;
      case BuilderStep.casePart:
        sel.casePart = part as CasePart;
        break;
    }
    if (index < _labels.length - 1) {
      final stepFrom = index;
      Future<void>.delayed(const Duration(milliseconds: 220)).then((_) {
        if (mounted) {
          setState(
            () =>
                index = (stepFrom + 1).clamp(0, _labels.length - 1),
          );
        }
      });
    }
    setState(() {});
  }

  double totalSpend() =>
      [
        sel.cpu?.price ?? 0,
        sel.motherboard?.price ?? 0,
        sel.ram?.price ?? 0,
        sel.gpu?.price ?? 0,
        sel.storage?.price ?? 0,
        sel.psu?.price ?? 0,
        sel.casePart?.price ?? 0,
      ].fold(0.0, (p, q) => p + q);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final issues = ctrl.compatibilityIssues(sel);
    final parts = ctrl.compatibleParts(step, sel);

    Future<void> review() async {
      if (issues.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(issues.first.toUpperCase())),
        );
        return;
      }
      if (totalSpend() == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SELECT PARTS FIRST')),
        );
        return;
      }
      ctrl.saveBuild(sel.copy());
      ctrl.navigate(ViewState.buildSummary);
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          NexusPalette.cyan,
                          NexusPalette.magenta,
                          NexusPalette.violet,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'CUSTOM BUILDER',
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      sel = BuilderState();
                      index = 0;
                    }),
                    child: Text(
                      'RESET',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .75),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _labels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final meta = _labels[idx];
                    return Center(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => index = _labels
                              .indexOf(meta)
                              .clamp(0, _labels.length - 1),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: meta == step ? 3 : 1.8,
                              color: meta == step
                                  ? NexusPalette.cyan
                                  : (_filled(meta, sel)
                                      ? NexusPalette.magenta
                                      : Colors.white.withValues(alpha: .16)),
                            ),
                            color: Colors.black.withValues(alpha: .35),
                          ),
                          child: Icon(
                            _iconForStep(meta),
                            size: 18,
                            color: Colors.white.withValues(alpha: .85),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'STEP ${index + 1}: ${_labelForStep(step)}',
                  style: GoogleFonts.jetBrainsMono(
                      letterSpacing: 2.4, color: NexusPalette.cyan),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: parts.isEmpty
              ? Center(
                  child: Text(
                    'SELECT PREVIOUS PARTS FIRST',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(color: Theme.of(context).hintColor),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(14, 12, 14, 200),
                  itemCount: parts.length,
                  itemBuilder: (_, i) {
                    final part = parts[i];
                    final mark = (_chosen(step, sel)?.id == part.id);

                    Color borderTone() =>
                        mark ? NexusPalette.cyan : Theme.of(context).dividerColor;

                    return InkWell(
                      onTap: () => _assign(part),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderTone()),
                          color: NexusPalette.darkSurface.withValues(alpha: .55),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: CachedNetworkImage(imageUrl: part.image),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.brand.toUpperCase(),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: .55),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    part.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$ ${part.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: NexusPalette.cyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (mark)
                              const Icon(Icons.check_circle_outline,
                                  color: NexusPalette.cyan),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: NexusPalette.darkSurface.withOpacity(.93),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(.06))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: issues.isEmpty
                                ? Colors.greenAccent.withOpacity(.08)
                                : Colors.redAccent.withOpacity(.07),
                            border: Border.all(
                              color: issues.isEmpty
                                  ? Colors.greenAccent.withOpacity(.4)
                                  : Colors.redAccent.withOpacity(.52),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                issues.isEmpty
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_rounded,
                                color: issues.isEmpty
                                    ? Colors.lightGreenAccent
                                    : Colors.redAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                issues.isEmpty ? 'COMPATIBLE' : 'ISSUES',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TOTAL EST.',
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, letterSpacing: 2)),
                          Text('\$ ${totalSpend().toStringAsFixed(2)}',
                              style:
                                  GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => setState(
                            () =>
                                index = (index - 1).clamp(0, _labels.length - 1),
                          ),
                          child: const Icon(Icons.chevron_left),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: index == _labels.length - 1
                            ? FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor:
                                      NexusPalette.magenta.withOpacity(.85),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: review,
                                child: Text(
                                  'REVIEW BUILD',
                                  style: GoogleFonts.jetBrainsMono(
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : FilledButton(
                                style: FilledButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  backgroundColor: Colors.white,
                                  minimumSize:
                                      const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => setState(
                                  () => index =
                                      (index + 1).clamp(0, _labels.length - 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('NEXT STEP',
                                        style:
                                            GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
List<MapEntry<String, NexusBuilderPart>> visibleComponents(BuilderState st) {
  final out = <MapEntry<String, NexusBuilderPart>>[];
  if (st.cpu != null) out.add(MapEntry('CPU', st.cpu!));
  if (st.motherboard != null) {
    out.add(MapEntry('MOTHERBOARD', st.motherboard!));
  }
  if (st.ram != null) out.add(MapEntry('MEMORY', st.ram!));
  if (st.gpu != null) out.add(MapEntry('GPU', st.gpu!));
  if (st.storage != null) out.add(MapEntry('STORAGE', st.storage!));
  if (st.psu != null) out.add(MapEntry('PSU', st.psu!));
  if (st.casePart != null) out.add(MapEntry('CASE', st.casePart!));
  return out;
}

double _buildTotal(BuilderState b) =>
    [
      b.cpu?.price ?? 0,
      b.motherboard?.price ?? 0,
      b.ram?.price ?? 0,
      b.gpu?.price ?? 0,
      b.storage?.price ?? 0,
      b.psu?.price ?? 0,
      b.casePart?.price ?? 0,
    ].fold<double>(0, (p, c) => p + c);

class BuildSummarySheet extends StatefulWidget {
  const BuildSummarySheet({super.key});

  @override
  State<BuildSummarySheet> createState() => _BuildSummarySheetState();
}

class _BuildSummarySheetState extends State<BuildSummarySheet> {
  late final TextEditingController _buildNameCtrl;

  @override
  void initState() {
    super.initState();
    _buildNameCtrl = TextEditingController(text: 'My Custom Rig');
  }

  @override
  void dispose() {
    _buildNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final latest = ctrl.latestSavedBuild;

    if (latest == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NO BUILD FOUND',
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => ctrl.navigate(ViewState.builder),
              child:
                  Text('GO TO BUILDER', style: GoogleFonts.jetBrainsMono()),
            ),
          ],
        ),
      );
    }

    final total = _buildTotal(latest);
    final lines = visibleComponents(latest);
    final divider =
        Theme.of(context).dividerColor.withValues(alpha: .45);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(color: Colors.white.withValues(alpha: .12)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ctrl.navigate(ViewState.builder),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  'BUILD SUMMARY',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('LINK COPIED')),
                ),
                icon: const Icon(Icons.share_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 132),
                children: [
                  TextField(
                    controller: _buildNameCtrl,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                    decoration:
                        const InputDecoration(border: InputBorder.none),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.lightGreenAccent.withValues(alpha: .08),
                      border: Border.all(
                          color:
                              Colors.lightGreenAccent.withValues(alpha: .45)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check,
                            color: Colors.lightGreenAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'FULLY COMPATIBLE',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: Colors.lightGreenAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('COMPONENTS',
                      style:
                          GoogleFonts.jetBrainsMono(letterSpacing: 2)),
                  const SizedBox(height: 14),
                  ...lines.map(
                    (e) {
                      final p = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: divider),
                          ),
                          child: ListTile(
                            title: Text(
                              p.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(e.key.toUpperCase(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: divider,
                                  letterSpacing: 2,
                                )),
                            trailing: Text(
                              '\$ ${p.price.toStringAsFixed(2)}',
                              style: GoogleFonts.jetBrainsMono(
                                color: NexusPalette.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'GRAND TOTAL: \$ ${total.toStringAsFixed(2)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
                  child: GradientRgbButton(
                    onPressed: () {
                      ctrl.addToCart(NewCartPayload(
                        productId: 'custom-build',
                        qty: 1,
                        price: total,
                      ));
                      showNexusToast(context, 'BUILD ADDED TO CART');
                      ctrl.navigate(ViewState.cart);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_cart_outlined),
                        SizedBox(width: 8),
                        Text('ADD BUILD TO CART'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
