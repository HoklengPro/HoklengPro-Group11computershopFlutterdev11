import 'models.dart';

class HeroSlideSpec {
  const HeroSlideSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.isCyanAccent,
  });

  final int id;
  final String title;
  final String subtitle;
  final String image;
  final bool isCyanAccent;

  factory HeroSlideSpec.fromJson(Map<String, dynamic> json) => HeroSlideSpec(
        id: json['id'] as int,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        image: json['image'] as String,
        isCyanAccent: json['isCyanAccent'] as bool? ?? true,
      );
}

class BrandMarqueeSpec {
  const BrandMarqueeSpec({
    required this.name,
    required this.slug,
  });

  final String name;
  final String slug;

  factory BrandMarqueeSpec.fromJson(Map<String, dynamic> json) =>
      BrandMarqueeSpec(
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}

class CategorySpec {
  const CategorySpec({required this.id, required this.label});

  final String id;
  final String label;

  factory CategorySpec.fromJson(Map<String, dynamic> json) => CategorySpec(
        id: json['id'] as String,
        label: json['label'] as String,
      );
}

class AccountProfileSpec {
  const AccountProfileSpec({
    required this.displayName,
    required this.initials,
    required this.tier,
  });

  final String displayName;
  final String initials;
  final String tier;

  factory AccountProfileSpec.fromJson(Map<String, dynamic> json) =>
      AccountProfileSpec(
        displayName: json['displayName'] as String,
        initials: json['initials'] as String,
        tier: json['tier'] as String,
      );
}

class StoreLocationSpec {
  const StoreLocationSpec({
    required this.name,
    required this.subtitle,
    this.lat,
    this.lng,
  });

  final String name;
  final String subtitle;
  final double? lat;
  final double? lng;

  bool get hasCoordinates => lat != null && lng != null;

  factory StoreLocationSpec.fromJson(Map<String, dynamic> json) =>
      StoreLocationSpec(
        name: json['name'] as String,
        subtitle: json['subtitle'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );
}

class PromotionSpec {
  const PromotionSpec({required this.title, required this.body});

  final String title;
  final String body;

  factory PromotionSpec.fromJson(Map<String, dynamic> json) => PromotionSpec(
        title: json['title'] as String,
        body: json['body'] as String,
      );
}

class CommunityReviewSpec {
  const CommunityReviewSpec({
    required this.author,
    required this.stars,
    required this.productId,
    required this.body,
  });

  final String author;
  final int stars;
  final String productId;
  final String body;

  factory CommunityReviewSpec.fromJson(Map<String, dynamic> json) =>
      CommunityReviewSpec(
        author: json['author'] as String,
        stars: (json['stars'] as num).toInt(),
        productId: json['productId'] as String,
        body: json['body'] as String,
      );
}

class HelpFaqSpec {
  const HelpFaqSpec({required this.question, required this.answer});

  final String question;
  final String answer;

  factory HelpFaqSpec.fromJson(Map<String, dynamic> json) => HelpFaqSpec(
        question: json['question'] as String,
        answer: json['answer'] as String,
      );
}

class LoyaltySpec {
  const LoyaltySpec({
    required this.points,
    required this.tierLabel,
    required this.progress,
  });

  final int points;
  final String tierLabel;
  final double progress;

  factory LoyaltySpec.fromJson(Map<String, dynamic> json) => LoyaltySpec(
        points: (json['points'] as num).toInt(),
        tierLabel: json['tierLabel'] as String,
        progress: (json['progress'] as num).toDouble(),
      );
}

class RepairStepSpec {
  const RepairStepSpec({required this.label, required this.complete});

  final String label;
  final bool complete;

  factory RepairStepSpec.fromJson(Map<String, dynamic> json) => RepairStepSpec(
        label: json['label'] as String,
        complete: json['complete'] as bool? ?? false,
      );
}

class RepairTrackerSpec {
  const RepairTrackerSpec({
    required this.ticketId,
    required this.title,
    required this.lead,
    required this.steps,
  });

  final String ticketId;
  final String title;
  final String lead;
  final List<RepairStepSpec> steps;

  factory RepairTrackerSpec.fromJson(Map<String, dynamic> json) =>
      RepairTrackerSpec(
        ticketId: json['ticketId'] as String,
        title: json['title'] as String,
        lead: json['lead'] as String,
        steps: (json['steps'] as List<dynamic>)
            .map((e) => RepairStepSpec.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AddressSpec {
  const AddressSpec({
    required this.tag,
    required this.line1,
    required this.line2,
  });

  final String tag;
  final String line1;
  final String line2;

  factory AddressSpec.fromJson(Map<String, dynamic> json) => AddressSpec(
        tag: json['tag'] as String,
        line1: json['line1'] as String,
        line2: json['line2'] as String,
      );
}

class PaymentMethodSpec {
  const PaymentMethodSpec({
    required this.primary,
    required this.subtitle,
    required this.icon,
  });

  final String primary;
  final String subtitle;
  final String icon;

  factory PaymentMethodSpec.fromJson(Map<String, dynamic> json) =>
      PaymentMethodSpec(
        primary: json['primary'] as String,
        subtitle: json['subtitle'] as String,
        icon: json['icon'] as String? ?? 'credit_card',
      );
}

class NearbyStockSpec {
  const NearbyStockSpec({required this.productId, required this.shelfCount});

  final String productId;
  final int shelfCount;

  factory NearbyStockSpec.fromJson(Map<String, dynamic> json) => NearbyStockSpec(
        productId: json['productId'] as String,
        shelfCount: (json['shelfCount'] as num).toInt(),
      );
}

class ShowcaseExtraSpec {
  const ShowcaseExtraSpec({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  factory ShowcaseExtraSpec.fromJson(Map<String, dynamic> json) =>
      ShowcaseExtraSpec(
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
      );
}

class NexusContentBundle {
  NexusContentBundle({
    required this.searchHints,
    required this.accountProfile,
    required this.notifications,
    required this.storeLocations,
    required this.promotions,
    required this.communityReviews,
    required this.helpFaqs,
    required this.loyalty,
    required this.repairTracker,
    required this.repairDeviceTypes,
    required this.addresses,
    required this.paymentMethods,
    required this.nearbyStock,
    this.showcaseExtra,
  });

  final List<String> searchHints;
  final AccountProfileSpec accountProfile;
  final List<NotificationEntry> notifications;
  final List<StoreLocationSpec> storeLocations;
  final List<PromotionSpec> promotions;
  final List<CommunityReviewSpec> communityReviews;
  final List<HelpFaqSpec> helpFaqs;
  final LoyaltySpec loyalty;
  final RepairTrackerSpec repairTracker;
  final List<String> repairDeviceTypes;
  final List<AddressSpec> addresses;
  final List<PaymentMethodSpec> paymentMethods;
  final List<NearbyStockSpec> nearbyStock;
  final ShowcaseExtraSpec? showcaseExtra;

  factory NexusContentBundle.empty() => NexusContentBundle(
        searchHints: const [],
        accountProfile: const AccountProfileSpec(
          displayName: 'GUEST',
          initials: 'GX',
          tier: 'Sign in to sync rewards',
        ),
        notifications: const [],
        storeLocations: const [],
        promotions: const [],
        communityReviews: const [],
        helpFaqs: const [],
        loyalty: const LoyaltySpec(
          points: 0,
          tierLabel: 'Join Nexus rewards',
          progress: 0,
        ),
        repairTracker: const RepairTrackerSpec(
          ticketId: '—',
          title: 'No active repair',
          lead: 'Book a bench slot to begin',
          steps: [],
        ),
        repairDeviceTypes: const ['Gaming Laptop'],
        addresses: const [],
        paymentMethods: const [],
        nearbyStock: const [],
      );

  factory NexusContentBundle.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return NexusContentBundle.empty();
    }

    NotificationEntry notifFromJson(Map<String, dynamic> n) => NotificationEntry(
          id: n['id'] as String,
          title: n['title'] as String,
          message: n['message'] as String,
          read: n['read'] as bool? ?? false,
          date: n['date'] as String,
        );

    return NexusContentBundle(
      searchHints: (json['searchHints'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      accountProfile: AccountProfileSpec.fromJson(
        json['accountProfile'] as Map<String, dynamic>? ??
            {
              'displayName': 'GUEST',
              'initials': 'GX',
              'tier': 'Sign in to sync rewards',
            },
      ),
      notifications: (json['notifications'] as List<dynamic>? ?? [])
          .map((e) => notifFromJson(e as Map<String, dynamic>))
          .toList(),
      storeLocations: (json['storeLocations'] as List<dynamic>? ?? [])
          .map((e) => StoreLocationSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      promotions: (json['promotions'] as List<dynamic>? ?? [])
          .map((e) => PromotionSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      communityReviews: (json['communityReviews'] as List<dynamic>? ?? [])
          .map((e) => CommunityReviewSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      helpFaqs: (json['helpFaqs'] as List<dynamic>? ?? [])
          .map((e) => HelpFaqSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      loyalty: LoyaltySpec.fromJson(
        json['loyalty'] as Map<String, dynamic>? ??
            {'points': 0, 'tierLabel': 'Join Nexus rewards', 'progress': 0},
      ),
      repairTracker: RepairTrackerSpec.fromJson(
        json['repairTracker'] as Map<String, dynamic>? ??
            {
              'ticketId': '—',
              'title': 'No active repair',
              'lead': 'Book a bench slot to begin',
              'steps': [],
            },
      ),
      repairDeviceTypes: (json['repairDeviceTypes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((e) => AddressSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentMethods: (json['paymentMethods'] as List<dynamic>? ?? [])
          .map((e) => PaymentMethodSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      nearbyStock: (json['nearbyStock'] as List<dynamic>? ?? [])
          .map((e) => NearbyStockSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      showcaseExtra: json['showcaseExtra'] == null
          ? null
          : ShowcaseExtraSpec.fromJson(
              json['showcaseExtra'] as Map<String, dynamic>,
            ),
    );
  }
}

class BuilderCatalogData {
  BuilderCatalogData({
    required this.cpus,
    required this.motherboards,
    required this.ram,
    required this.gpus,
    required this.storage,
    required this.psus,
    required this.cases,
  });

  final List<CpuPart> cpus;
  final List<MotherboardPart> motherboards;
  final List<RamPart> ram;
  final List<GpuPart> gpus;
  final List<StoragePart> storage;
  final List<PsuPart> psus;
  final List<CasePart> cases;
}
