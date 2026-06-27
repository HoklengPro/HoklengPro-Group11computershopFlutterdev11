typedef SocketType = String;
typedef RamType = String;
typedef FormFactor = String;

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.qty,
    required this.price,
    this.configOptions,
  });

  final String id;
  final String productId;
  final int qty;
  final double price;
  final CartConfigOptions? configOptions;
}

class CartConfigOptions {
  CartConfigOptions({this.ram, this.storage});

  final String? ram;
  final String? storage;
}

class NotificationEntry {
  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.date,
  });

  final String id;
  final String title;
  final String message;
  final bool read;
  final String date;
}

class OrderSummary {
  OrderSummary({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
    required this.itemCount,
  });

  final String id;
  final String date;
  final double total;
  final OrderStatus status;
  final int itemCount;
}

enum OrderStatus {
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderLineItem {
  OrderLineItem({
    required this.title,
    required this.qty,
    required this.unitPrice,
  });

  final String title;
  final int qty;
  final double unitPrice;
}

/// Rich mock used by Orders / Order detail screens.
class DetailedOrderMock {
  DetailedOrderMock({
    required this.summary,
    required this.lines,
    this.trackingHints = const [],
    this.carrier,
    this.etaNote,
  });

  final OrderSummary summary;
  final List<OrderLineItem> lines;
  final List<String> trackingHints;
  final String? carrier;
  final String? etaNote;
}

class ProductSpecs {
  ProductSpecs({
    this.cpu,
    this.gpu,
    this.ram,
    this.storage,
    this.display,
  });

  final String? cpu;
  final String? gpu;
  final String? ram;
  final String? storage;
  final String? display;
}

class ProductBenchmarks {
  ProductBenchmarks({
    required this.gaming,
    required this.productivity,
  });

  final int gaming;
  final int productivity;
}

class ProductConfigOptions {
  const ProductConfigOptions({
    this.ram = const [],
    this.storage = const [],
  });

  final List<String> ram;
  final List<String> storage;
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.specs,
    this.benchmarks,
    this.isNew,
    this.isDeal,
    this.configOptions,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String image;
  final ProductSpecs specs;
  final ProductBenchmarks? benchmarks;
  final bool? isNew;
  final bool? isDeal;
  final ProductConfigOptions? configOptions;
}

abstract class NexusBuilderPart {
  NexusBuilderPart({
    required this.id,
    required this.partType,
    required this.name,
    required this.brand,
    required this.price,
    required this.image,
  });

  final String id;
  final String partType;
  final String name;
  final String brand;
  final double price;
  final String image;
}

class CpuPart extends NexusBuilderPart {
  CpuPart({
    required super.id,
    required super.partType,
    required super.name,
    required super.brand,
    required super.price,
    required super.image,
    required this.socket,
    required this.tdp,
    required this.cores,
    required this.threads,
    required this.speed,
  });

  final SocketType socket;
  final int tdp;
  final int cores;
  final int threads;
  final String speed;
}

class MotherboardPart extends NexusBuilderPart {
  MotherboardPart({
    required super.id,
    required super.partType,
    required super.name,
    required super.brand,
    required super.price,
    required super.image,
    required this.socket,
    required this.ramType,
    required this.formFactor,
  });

  final SocketType socket;
  final RamType ramType;
  final FormFactor formFactor;
}

class RamPart extends NexusBuilderPart {
  RamPart({
    required super.id,
    required super.partType,
    required super.name,
    required super.brand,
    required super.price,
    required super.image,
    required this.ramType,
    required this.capacity,
    required this.speed,
  });

  final RamType ramType;
  final String capacity;
  final String speed;
}

class GpuPart extends NexusBuilderPart {
  GpuPart({
    required super.id,
    required super.partType,
    required super.name,
    required super.brand,
    required super.price,
    required super.image,
    required this.tdp,
    required this.vram,
    required this.chipset,
  });

  final int tdp;
  final String vram;
  final String chipset;
}

class StoragePart extends NexusBuilderPart {
  StoragePart({
    required super.id,
    required super.partType,
    required super.name,
    required super.brand,
    required super.price,
    required super.image,
    required this.capacity,
    required this.slotInterface,
    required this.partFormFactor,
  });

  final String capacity;
  final String slotInterface;
  final String partFormFactor;
}

class PsuPart extends NexusBuilderPart {
  PsuPart({
    required super.id,
    required super.partType,
    required super.name,
    required super.brand,
    required super.price,
    required super.image,
    required this.wattage,
    required this.efficiency,
    required this.modular,
  });

  final int wattage;
  final String efficiency;
  final String modular;
}

class CasePart extends NexusBuilderPart {
  CasePart({
    required super.id,
    required super.partType,
    required super.name,
    required super.brand,
    required super.price,
    required super.image,
    required this.formFactors,
    required this.color,
  });

  final List<FormFactor> formFactors;
  final String color;
}

class BuilderState {
  BuilderState({
    this.cpu,
    this.motherboard,
    this.ram,
    this.gpu,
    this.storage,
    this.psu,
    this.casePart,
  });

  CpuPart? cpu;
  MotherboardPart? motherboard;
  RamPart? ram;
  GpuPart? gpu;
  StoragePart? storage;
  PsuPart? psu;
  CasePart? casePart;

  BuilderState copy() => BuilderState(
        cpu: cpu,
        motherboard: motherboard,
        ram: ram,
        gpu: gpu,
        storage: storage,
        psu: psu,
        casePart: casePart,
      );
}
