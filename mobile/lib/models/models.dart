import 'package:flutter/material.dart';

/// Active Enterprise Vertical for strict isolation
enum CompanyVertical {
  dkWaters,    // Packaged Drinking Water Distribution (DK Waters)
  tmws,        // Commercial Bulk Water Tankers (Tiruchendur Murugan Water Supply)
  aranCafe,    // Bakery & Cafe POS Operations (Aran Cafe)
}

extension CompanyVerticalExt on CompanyVertical {
  String get code {
    switch (this) {
      case CompanyVertical.dkWaters:
        return 'DKWATERS';
      case CompanyVertical.tmws:
        return 'TMWS';
      case CompanyVertical.aranCafe:
        return 'ARANCAFE';
    }
  }

  String name(bool isTamil) {
    switch (this) {
      case CompanyVertical.dkWaters:
        return isTamil ? 'டிகே வாட்டர்ஸ்' : 'DK Waters';
      case CompanyVertical.tmws:
        return isTamil ? 'திருச்செந்தூர் முருகன் வாட்டர்' : 'Tiruchendur Murugan Water Supply';
      case CompanyVertical.aranCafe:
        return isTamil ? 'அரண் கஃபே' : 'Aran Cafe';
    }
  }

  String tagline(bool isTamil) {
    switch (this) {
      case CompanyVertical.dkWaters:
        return isTamil ? 'பாக்கேஜ் செய்யப்பட்ட குடிநீர் விநியோகம்' : 'Packaged Drinking Water Distribution';
      case CompanyVertical.tmws:
        return isTamil ? 'ஹெவி கமர்ஷியல் பல்க் வாட்டர் டேங்கர்' : 'Commercial Bulk Water Tankers & Fleet Logistics';
      case CompanyVertical.aranCafe:
        return isTamil ? 'பேக்கரி & விரைவு பில்லிங் கவுண்டர்' : 'Bakery & Express Counter POS';
    }
  }

  Color get primaryColor {
    switch (this) {
      case CompanyVertical.dkWaters:
        return const Color(0xFF0284C7); // Sky Blue
      case CompanyVertical.tmws:
        return const Color(0xFF2563EB); // Royal Blue
      case CompanyVertical.aranCafe:
        return const Color(0xFFD97706); // Amber Gold
    }
  }

  IconData get icon {
    switch (this) {
      case CompanyVertical.dkWaters:
        return Icons.water_drop;
      case CompanyVertical.tmws:
        return Icons.fire_truck;
      case CompanyVertical.aranCafe:
        return Icons.local_cafe;
    }
  }
}

/// Package specification for packaged drinking water (open & dynamic, NOT hardcoded)
class WaterPackageItem {
  final String code;
  final String nameEn;
  final String nameTa;
  final double unitPrice;
  final bool isJar;

  const WaterPackageItem({
    required this.code,
    required this.nameEn,
    required this.nameTa,
    required this.unitPrice,
    required this.isJar,
  });

  String name(bool isTamil) => isTamil ? nameTa : nameEn;
}

/// Packaged water can delivery record for ticket machine
class WaterCanDeliveryRecord {
  final String deliveryNumber;
  final int routeId;
  final int customerId;
  final String customerName;
  final int cansDelivered;
  final int emptyCansCollected;
  final double canRate;
  final double totalAmount;
  final String paymentMode;
  final DateTime deliveryTime;
  final int balanceCansHeld;

  WaterCanDeliveryRecord({
    required this.deliveryNumber,
    required this.routeId,
    required this.customerId,
    required this.customerName,
    required this.cansDelivered,
    required this.emptyCansCollected,
    required this.canRate,
    required this.totalAmount,
    required this.paymentMode,
    required this.deliveryTime,
    required this.balanceCansHeld,
  });
}

/// Customer entity for routes
class CustomerItem {
  final int id;
  final String name;
  final String phone;
  final String address;
  final int emptyHeld;
  final double depositHeld;

  CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.emptyHeld = 0,
    this.depositHeld = 0.0,
  });
}

/// Packaged drinking water delivery ticket
class PackagedWaterDeliveryRecord {
  final String deliveryNumber;
  final int routeId;
  final int customerId;
  final String customerName;
  final String packageCode;
  final int quantityDelivered;
  final int emptyReturned;
  final double unitPrice;
  final double totalAmount;
  final double cashCollected;
  final String paymentMode;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  PackagedWaterDeliveryRecord({
    required this.deliveryNumber,
    required this.routeId,
    required this.customerId,
    required this.customerName,
    required this.packageCode,
    required this.quantityDelivered,
    required this.emptyReturned,
    required this.unitPrice,
    required this.totalAmount,
    required this.cashCollected,
    required this.paymentMode,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

/// Multi-plant refill intake record (Load 1, 2, 3...)
class PlantRefillRecord {
  final int loadSequence;
  final String plantName;
  final int cansLoaded;
  final double ratePerCan;
  final String slipNumber;
  final String? slipPhotoPath;
  final int odometerKm;
  final DateTime timestamp;

  PlantRefillRecord({
    required this.loadSequence,
    required this.plantName,
    required this.cansLoaded,
    required this.ratePerCan,
    required this.slipNumber,
    this.slipPhotoPath,
    required this.odometerKm,
    required this.timestamp,
  });
}

/// Commercial bulk water tanker trip sheet
class TankerTripRecord {
  final String tripNumber;
  final int tankerId;
  final String vehicleNumber;
  final double capacityKl;
  final String customerName;
  final String loadSource;
  final String destinationSite;
  final int startKm;
  final int endKm;
  final int excessKm;
  final double excessKmCharge;
  final bool motorUsed;
  final int motorMinutes;
  final double motorCharge;
  final double waitingHours;
  final double waitingCharge;
  final double tollExpense;
  final double driverBatta;
  final double dieselExpense;
  final double billedAmount;
  final String? siteReceiverName;
  final String? signatureSvg;
  final DateTime tripDate;

  TankerTripRecord({
    required this.tripNumber,
    required this.tankerId,
    required this.vehicleNumber,
    required this.capacityKl,
    required this.customerName,
    required this.loadSource,
    required this.destinationSite,
    required this.startKm,
    required this.endKm,
    required this.excessKm,
    required this.excessKmCharge,
    required this.motorUsed,
    required this.motorMinutes,
    required this.motorCharge,
    required this.waitingHours,
    required this.waitingCharge,
    required this.tollExpense,
    required this.driverBatta,
    required this.dieselExpense,
    required this.billedAmount,
    this.siteReceiverName,
    this.signatureSvg,
    required this.tripDate,
  });
}

/// Cafe Touch POS menu item
class CafeProductItem {
  final int id;
  final String name;
  final String category;
  final double price;
  final String iconEmoji;

  const CafeProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.iconEmoji,
  });
}

/// Spot Audit Inspection Record
class SpotAuditRecord {
  final String vehicleNumber;
  final String driverName;
  final int expectedUnits;
  final int physicalUnits;
  final double expectedCash;
  final double physicalCash;
  final int unitDifference;
  final double cashDifference;
  final bool isFraudSuspected;
  final String auditNotes;
  final DateTime auditTime;

  SpotAuditRecord({
    required this.vehicleNumber,
    required this.driverName,
    required this.expectedUnits,
    required this.physicalUnits,
    required this.expectedCash,
    required this.physicalCash,
    required this.unitDifference,
    required this.cashDifference,
    required this.isFraudSuspected,
    required this.auditNotes,
    required this.auditTime,
  });
}

/// Operational user roles across the enterprise
enum UserRole {
  superAdmin,     // Group Managing Director / Super Admin
  admin,          // Company Administrator
  fieldAgent,     // Field Sales & Collection Officer
  deliveryDriver, // Packaged Water Route Driver (Tata Ace)
  tankerDriver,   // Commercial Bulk Tanker Driver (Heavy Lorries)
  cashier,        // Cafe & Bakery POS Cashier
}

extension UserRoleExt on UserRole {
  String get code {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.fieldAgent:
        return 'field_agent';
      case UserRole.deliveryDriver:
        return 'delivery_driver';
      case UserRole.tankerDriver:
        return 'tanker_driver';
      case UserRole.cashier:
        return 'cashier';
    }
  }

  String title(bool isTamil) {
    switch (this) {
      case UserRole.superAdmin:
        return isTamil ? 'குரூப் சூப்பர் அட்மின்' : 'Super Admin (Group MD)';
      case UserRole.admin:
        return isTamil ? 'நிறுவன அட்மின்' : 'Company Admin';
      case UserRole.fieldAgent:
        return isTamil ? 'கள அலுவலர் (வசூல் & KYC)' : 'Field Agent (Sales & KYC)';
      case UserRole.deliveryDriver:
        return isTamil ? 'ரூட் டெலிவரி டிரைவர்' : 'Delivery Boy / Route Driver';
      case UserRole.tankerDriver:
        return isTamil ? 'பல்க் டேங்கர் டிரைவர்' : 'Heavy Tanker Driver';
      case UserRole.cashier:
        return isTamil ? 'கஃபே காசாளர்' : 'Cafe Cashier / POS';
    }
  }

  String description(bool isTamil) {
    switch (this) {
      case UserRole.superAdmin:
        return isTamil
            ? 'அனைத்து நிறுவனங்கள், ஒருங்கிணைந்த வருவாய், மோசடி தணிக்கை'
            : 'Multi-company group overview, consolidated financials & anti-fraud audit';
      case UserRole.admin:
        return isTamil
            ? 'நிறுவன செயல்பாடுகள், வாகனங்கள், ரூட் & ட்ரிப் ஒப்புதல்கள்'
            : 'Enterprise operations, fleet status, route & trip settlements';
      case UserRole.fieldAgent:
        return isTamil
            ? 'புதிய வாடிக்கையாளர் பதிவு, நிலுவை வசூல், கேன் இருப்பு ஆய்வு'
            : 'Customer KYC onboarding, credit collection & container audits';
      case UserRole.deliveryDriver:
        return isTamil
            ? 'டாடா ஏஸ் டெலிவரி சீட்டு (<15 விநாடி), ஆலை லோடிங், காசோலை'
            : '15-sec delivery ticketing, multi-plant refills & empty returns';
      case UserRole.tankerDriver:
        return isTamil
            ? 'ஹெவி டேங்கர் ட்ரிப், மோட்டார் பம்பிங், சேம்பர் டெலிவரி, டீசல்'
            : 'Heavy tanker trip sheet, pumping timer, decanting & diesel vouchers';
      case UserRole.cashier:
        return isTamil
            ? 'அரண் கஃபே தொடுதிரை பில்லிங், டிராயர் ரொக்க சமரசம்'
            : 'Touch POS order billing, KOT printing & cash drawer balancing';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings;
      case UserRole.admin:
        return Icons.business_center;
      case UserRole.fieldAgent:
        return Icons.assignment_ind;
      case UserRole.deliveryDriver:
        return Icons.local_shipping;
      case UserRole.tankerDriver:
        return Icons.fire_truck;
      case UserRole.cashier:
        return Icons.point_of_sale;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.superAdmin:
        return const Color(0xFF8B5CF6); // Purple
      case UserRole.admin:
        return const Color(0xFF3B82F6); // Blue
      case UserRole.fieldAgent:
        return const Color(0xFF10B981); // Emerald Green
      case UserRole.deliveryDriver:
        return const Color(0xFF0284C7); // Sky Blue
      case UserRole.tankerDriver:
        return const Color(0xFF1D4ED8); // Deep Blue
      case UserRole.cashier:
        return const Color(0xFFD97706); // Amber Gold
    }
  }
}

/// Customer Onboarding & KYC Record
class CustomerOnboardRecord {
  final String name;
  final String phone;
  final String address;
  final String city;
  final int companyId;
  final String customerType; // Commercial, Residential, Bulk Corporate
  final int initialCansHeld;
  final double depositPerCan;
  final double totalDeposit;
  final double? latitude;
  final double? longitude;

  CustomerOnboardRecord({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.companyId,
    required this.customerType,
    this.initialCansHeld = 0,
    this.depositPerCan = 150.0,
    this.totalDeposit = 0.0,
    this.latitude,
    this.longitude,
  });
}

/// Credit Aging Collection Record
class PaymentCollectionRecord {
  final String receiptNumber;
  final int customerId;
  final String customerName;
  final double outstandingAmount;
  final double amountCollected;
  final String paymentMode; // Cash, UPI, Cheque
  final String? transactionRef;
  final DateTime collectionDate;
  final String? collectedBy;

  PaymentCollectionRecord({
    required this.receiptNumber,
    required this.customerId,
    required this.customerName,
    required this.outstandingAmount,
    required this.amountCollected,
    required this.paymentMode,
    this.transactionRef,
    required this.collectionDate,
    this.collectedBy,
  });
}

/// End of Day Driver Cash & Can Surrender
class DriverSurrenderRecord {
  final String surrenderCode;
  final int routeId;
  final String routeName;
  final String driverName;
  final int totalLoaded;
  final int totalDelivered;
  final int emptyReturned;
  final double totalCashCollected;
  final double cashSurrendered;
  final double variance;
  final DateTime surrenderTime;

  DriverSurrenderRecord({
    required this.surrenderCode,
    required this.routeId,
    required this.routeName,
    required this.driverName,
    required this.totalLoaded,
    required this.totalDelivered,
    required this.emptyReturned,
    required this.totalCashCollected,
    required this.cashSurrendered,
    required this.variance,
    required this.surrenderTime,
  });
}

/// System Fraud / Discrepancy Alert Item
class FraudAlertItem {
  final String id;
  final String title;
  final String companyName;
  final String severity; // High, Medium, Low
  final String description;
  final DateTime timestamp;
  final bool isResolved;

  FraudAlertItem({
    required this.id,
    required this.title,
    required this.companyName,
    required this.severity,
    required this.description,
    required this.timestamp,
    this.isResolved = false,
  });
}

