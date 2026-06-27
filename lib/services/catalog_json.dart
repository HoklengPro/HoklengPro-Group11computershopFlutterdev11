import '../models/catalog_models.dart';
import '../models/models.dart';

class NexusSearchHit {
  const NexusSearchHit({
    required this.type,
    required this.item,
  });

  final String type;
  final Map<String, dynamic> item;

  bool get isProduct => type == 'product';
  bool get isBuilderPart => type == 'builder_part';
}

List<NexusSearchHit> searchHitsFromJson(Map<String, dynamic> json) {
  final results = json['results'] as List<dynamic>? ?? [];
  return results
      .map((entry) {
        final map = entry as Map<String, dynamic>;
        return NexusSearchHit(
          type: map['type'] as String? ?? 'product',
          item: map['item'] as Map<String, dynamic>,
        );
      })
      .toList();
}

Product productFromJson(Map<String, dynamic> json) {
  final specsJson = json['specs'] as Map<String, dynamic>? ?? {};
  final benchJson = json['benchmarks'] as Map<String, dynamic>?;
  final configJson = json['configOptions'] as Map<String, dynamic>?;
  ProductConfigOptions? configOptions;
  if (configJson != null) {
    configOptions = ProductConfigOptions(
      ram: (configJson['ram'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      storage: (configJson['storage'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
  return Product(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    image: json['image'] as String,
    specs: ProductSpecs(
      cpu: specsJson['cpu'] as String?,
      gpu: specsJson['gpu'] as String?,
      ram: specsJson['ram'] as String?,
      storage: specsJson['storage'] as String?,
      display: specsJson['display'] as String?,
    ),
    benchmarks: benchJson == null
        ? null
        : ProductBenchmarks(
            gaming: (benchJson['gaming'] as num).toInt(),
            productivity: (benchJson['productivity'] as num).toInt(),
          ),
    isNew: json['isNew'] as bool?,
    isDeal: json['isDeal'] as bool?,
    configOptions: configOptions,
  );
}

OrderStatus orderStatusFromString(String raw) => switch (raw) {
      'processing' => OrderStatus.processing,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.processing,
    };

OrderSummary orderSummaryFromJson(Map<String, dynamic> json) => OrderSummary(
      id: json['id'] as String,
      date: json['date'] as String,
      total: (json['total'] as num).toDouble(),
      status: orderStatusFromString(json['status'] as String? ?? 'processing'),
      itemCount: (json['itemCount'] as num).toInt(),
    );

DetailedOrderMock detailedOrderFromJson(Map<String, dynamic> json) {
  final linesJson = json['lines'] as List<dynamic>? ?? [];
  final hintsJson = json['trackingHints'] as List<dynamic>? ?? [];
  return DetailedOrderMock(
    summary: orderSummaryFromJson(json['summary'] as Map<String, dynamic>),
    lines: linesJson
        .map((e) => e as Map<String, dynamic>)
        .map(
          (line) => OrderLineItem(
            title: line['title'] as String,
            qty: (line['qty'] as num).toInt(),
            unitPrice: (line['unitPrice'] as num).toDouble(),
          ),
        )
        .toList(),
    trackingHints: hintsJson.map((e) => e as String).toList(),
    carrier: json['carrier'] as String?,
    etaNote: json['etaNote'] as String?,
  );
}

NexusBuilderPart builderPartFromJson(Map<String, dynamic> json) {
  final type = json['partType'] as String? ?? '';
  final base = (
    id: json['id'] as String,
    partType: type,
    name: json['name'] as String,
    brand: json['brand'] as String,
    price: (json['price'] as num).toDouble(),
    image: json['image'] as String,
  );
  return switch (type) {
    'cpu' => CpuPart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        socket: json['socket'] as String,
        tdp: (json['tdp'] as num).toInt(),
        cores: (json['cores'] as num).toInt(),
        threads: (json['threads'] as num).toInt(),
        speed: json['speed'] as String,
      ),
    'motherboard' => MotherboardPart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        socket: json['socket'] as String,
        ramType: json['ramType'] as String,
        formFactor: json['formFactor'] as String,
      ),
    'ram' => RamPart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        ramType: json['ramType'] as String,
        capacity: json['capacity'] as String,
        speed: json['speed'] as String,
      ),
    'gpu' => GpuPart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        tdp: (json['tdp'] as num).toInt(),
        vram: json['vram'] as String,
        chipset: json['chipset'] as String,
      ),
    'storage' => StoragePart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        capacity: json['capacity'] as String,
        slotInterface: json['slotInterface'] as String,
        partFormFactor: json['partFormFactor'] as String,
      ),
    'psu' => PsuPart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        wattage: (json['wattage'] as num).toInt(),
        efficiency: json['efficiency'] as String,
        modular: json['modular'] as String,
      ),
    'case' => CasePart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        formFactors: (json['formFactors'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        color: json['color'] as String,
      ),
    _ => CpuPart(
        id: base.id,
        partType: base.partType,
        name: base.name,
        brand: base.brand,
        price: base.price,
        image: base.image,
        socket: 'AM5',
        tdp: 0,
        cores: 0,
        threads: 0,
        speed: '',
      ),
  };
}

BuilderCatalogData builderCatalogFromJson(Map<String, dynamic> json) {
  List<T> mapList<T>(String key, T Function(Map<String, dynamic>) fn) =>
      (json[key] as List<dynamic>? ?? [])
          .map((e) => fn(e as Map<String, dynamic>))
          .cast<T>()
          .toList();

  return BuilderCatalogData(
    cpus: mapList('cpus', (j) => builderPartFromJson(j) as CpuPart),
    motherboards:
        mapList('motherboards', (j) => builderPartFromJson(j) as MotherboardPart),
    ram: mapList('ram', (j) => builderPartFromJson(j) as RamPart),
    gpus: mapList('gpus', (j) => builderPartFromJson(j) as GpuPart),
    storage: mapList('storage', (j) => builderPartFromJson(j) as StoragePart),
    psus: mapList('psus', (j) => builderPartFromJson(j) as PsuPart),
    cases: mapList('cases', (j) => builderPartFromJson(j) as CasePart),
  );
}

class NexusCatalogSnapshot {
  NexusCatalogSnapshot({
    required this.featuredProducts,
    required this.buildOfTheMonthProduct,
    required this.heroSlides,
    required this.marqueeBrands,
    required this.categoryTiles,
    required this.builderCatalog,
    required this.orderCatalog,
    required this.content,
  });

  final List<Product> featuredProducts;
  final Product buildOfTheMonthProduct;
  final List<HeroSlideSpec> heroSlides;
  final List<BrandMarqueeSpec> marqueeBrands;
  final List<CategorySpec> categoryTiles;
  final BuilderCatalogData builderCatalog;
  final Map<String, DetailedOrderMock> orderCatalog;
  final NexusContentBundle content;

  List<Product> get allCatalogProducts => [
        ...featuredProducts,
        buildOfTheMonthProduct,
      ];

  List<NexusBuilderPart> get allBuilderParts => [
        ...builderCatalog.cpus,
        ...builderCatalog.motherboards,
        ...builderCatalog.ram,
        ...builderCatalog.gpus,
        ...builderCatalog.storage,
        ...builderCatalog.psus,
        ...builderCatalog.cases,
      ];

  List<OrderSummary> listOrdersByDate() =>
      [...orderCatalog.values.map((d) => d.summary)]
        ..sort((a, b) => b.date.compareTo(a.date));

  DetailedOrderMock? orderDetailById(String? id) {
    if (id == null || id.isEmpty) return null;
    return orderCatalog[id];
  }

  factory NexusCatalogSnapshot.fromJson(Map<String, dynamic> json) {
    final ordersJson = json['orders'] as Map<String, dynamic>? ?? {};
    final orderCatalog = <String, DetailedOrderMock>{};
    for (final entry in ordersJson.entries) {
      orderCatalog[entry.key] =
          detailedOrderFromJson(entry.value as Map<String, dynamic>);
    }

    return NexusCatalogSnapshot(
      featuredProducts: (json['featuredProducts'] as List<dynamic>)
          .map((e) => productFromJson(e as Map<String, dynamic>))
          .toList(),
      buildOfTheMonthProduct: productFromJson(
        json['buildOfTheMonth'] as Map<String, dynamic>,
      ),
      heroSlides: (json['heroSlides'] as List<dynamic>)
          .map((e) => HeroSlideSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      marqueeBrands: (json['marqueeBrands'] as List<dynamic>)
          .map((e) => BrandMarqueeSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryTiles: (json['categories'] as List<dynamic>)
          .map((e) => CategorySpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      builderCatalog: builderCatalogFromJson(
        json['builder'] as Map<String, dynamic>,
      ),
      orderCatalog: orderCatalog,
      content: json['content'] is Map<String, dynamic>
          ? NexusContentBundle.fromJson(json['content'] as Map<String, dynamic>)
          : NexusContentBundle.empty(),
    );
  }
}
