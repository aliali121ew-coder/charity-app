// ─────────────────────────────────────────────────────────────────────────────
// Payment Domain Models
// PCI-DSS aware architecture: no raw sensitive data persistence.
// Supports provider-agnostic integration: Stripe, ZainCash, PayPal, Tap, etc.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum PaymentMethodType {
  visa,
  mastercard,
  zaincash,
  superki,
  bankTransfer,
  cash,
  applePay,
  googlePay,
  paypal,
  stripe,
  tap,
  myFatoorah,
  checkout,
}

enum PaymentSessionStatus {
  pending,
  initiated,
  verificationRequired, // OTP / 3DS needed — awaiting user input
  processing,           // Submitted to provider, awaiting confirmation
  completed,
  failed,
  expired,
  cancelled,
}

enum VerificationType {
  none,
  otp,          // SMS OTP — ZainCash, SuperKi, etc.
  threeDSecure, // 3D Secure — Visa / MasterCard
  redirect,     // Full-page redirect — PayPal, Apple Pay
  biometric,    // Face ID / Touch ID
}

enum PaymentCurrency { iqd, usd, eur, gbp, sar, aed }

extension PaymentCurrencyExt on PaymentCurrency {
  String get code {
    switch (this) {
      case PaymentCurrency.iqd: return 'IQD';
      case PaymentCurrency.usd: return 'USD';
      case PaymentCurrency.eur: return 'EUR';
      case PaymentCurrency.gbp: return 'GBP';
      case PaymentCurrency.sar: return 'SAR';
      case PaymentCurrency.aed: return 'AED';
    }
  }

  String get symbol {
    switch (this) {
      case PaymentCurrency.iqd: return 'د.ع';
      case PaymentCurrency.usd: return '\$';
      case PaymentCurrency.eur: return '€';
      case PaymentCurrency.gbp: return '£';
      case PaymentCurrency.sar: return 'ر.س';
      case PaymentCurrency.aed: return 'د.إ';
    }
  }
}

extension PaymentMethodTypeExt on PaymentMethodType {
  String get nameAr {
    switch (this) {
      case PaymentMethodType.visa:         return 'Visa';
      case PaymentMethodType.mastercard:   return 'MasterCard';
      case PaymentMethodType.zaincash:     return 'زين كاش';
      case PaymentMethodType.superki:      return 'سوبر كي';
      case PaymentMethodType.bankTransfer: return 'تحويل بنكي';
      case PaymentMethodType.cash:         return 'نقداً';
      case PaymentMethodType.applePay:     return 'Apple Pay';
      case PaymentMethodType.googlePay:    return 'Google Pay';
      case PaymentMethodType.paypal:       return 'PayPal';
      case PaymentMethodType.stripe:       return 'Stripe';
      case PaymentMethodType.tap:          return 'Tap';
      case PaymentMethodType.myFatoorah:   return 'My Fatoorah';
      case PaymentMethodType.checkout:     return 'Checkout.com';
    }
  }

  String get descriptionAr {
    switch (this) {
      case PaymentMethodType.visa:         return 'بطاقة ائتمان / خصم Visa';
      case PaymentMethodType.mastercard:   return 'بطاقة ائتمان / خصم MasterCard';
      case PaymentMethodType.zaincash:     return 'محفظة زين كاش الإلكترونية';
      case PaymentMethodType.superki:      return 'محفظة سوبر كي';
      case PaymentMethodType.bankTransfer: return 'تحويل بنكي مباشر';
      case PaymentMethodType.cash:         return 'دفع نقدي مباشر';
      case PaymentMethodType.applePay:     return 'Apple Pay — لحاملي أجهزة Apple';
      case PaymentMethodType.googlePay:    return 'Google Pay — سريع وآمن';
      case PaymentMethodType.paypal:       return 'PayPal — مدفوعات دولية';
      case PaymentMethodType.stripe:       return 'Stripe — بوابة دولية';
      case PaymentMethodType.tap:          return 'Tap Payments';
      case PaymentMethodType.myFatoorah:   return 'My Fatoorah';
      case PaymentMethodType.checkout:     return 'Checkout.com';
    }
  }

  bool get requiresOtp =>
      this == PaymentMethodType.zaincash || this == PaymentMethodType.superki;

  bool get requiresCard =>
      this == PaymentMethodType.visa || this == PaymentMethodType.mastercard;

  bool get requires3DS =>
      this == PaymentMethodType.visa || this == PaymentMethodType.mastercard;

  bool get isWallet =>
      this == PaymentMethodType.zaincash ||
      this == PaymentMethodType.superki ||
      this == PaymentMethodType.applePay ||
      this == PaymentMethodType.googlePay;
}

// ── PaymentSession ─────────────────────────────────────────────────────────────
// Created server-side; represents an active payment intent.
// The client never initiates a payment — always created via backend first.

class PaymentSession {
  final String sessionId;
  final String providerId;
  final double amount;
  final PaymentCurrency currency;
  final PaymentMethodType method;
  final PaymentSessionStatus status;
  final VerificationType verificationRequired;

  /// OTP session reference returned by the provider (e.g. ZainCash txRef).
  /// Used when verifying the OTP with the provider's endpoint.
  final String? verificationReference;

  /// Full-page redirect URL for redirect-based flows (PayPal, 3DS, etc.).
  final String? redirectUrl;

  /// Provider-issued client token (e.g. Stripe client_secret, Checkout sessionId).
  /// Passed to the provider's client-side SDK for tokenization — never stored raw.
  final String? clientToken;

  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, dynamic>? providerData;

  const PaymentSession({
    required this.sessionId,
    required this.providerId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.verificationRequired,
    required this.createdAt,
    required this.expiresAt,
    this.verificationReference,
    this.redirectUrl,
    this.clientToken,
    this.providerData,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get requiresVerification =>
      verificationRequired != VerificationType.none;
  bool get isTerminal =>
      status == PaymentSessionStatus.completed ||
      status == PaymentSessionStatus.failed ||
      status == PaymentSessionStatus.expired ||
      status == PaymentSessionStatus.cancelled;

  PaymentSession copyWith({
    PaymentSessionStatus? status,
    String? verificationReference,
    String? redirectUrl,
    String? clientToken,
    Map<String, dynamic>? providerData,
  }) {
    return PaymentSession(
      sessionId: sessionId,
      providerId: providerId,
      amount: amount,
      currency: currency,
      method: method,
      status: status ?? this.status,
      verificationRequired: verificationRequired,
      createdAt: createdAt,
      expiresAt: expiresAt,
      verificationReference:
          verificationReference ?? this.verificationReference,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      clientToken: clientToken ?? this.clientToken,
      providerData: providerData ?? this.providerData,
    );
  }

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    return PaymentSession(
      sessionId: json['session_id'] as String,
      providerId: json['provider_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: PaymentCurrency.values.firstWhere(
        (c) => c.code == json['currency'],
        orElse: () => PaymentCurrency.iqd,
      ),
      method: PaymentMethodType.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => PaymentMethodType.cash,
      ),
      status: PaymentSessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaymentSessionStatus.pending,
      ),
      verificationRequired: VerificationType.values.firstWhere(
        (v) => v.name == (json['verification_type'] ?? 'none'),
        orElse: () => VerificationType.none,
      ),
      verificationReference: json['verification_reference'] as String?,
      redirectUrl: json['redirect_url'] as String?,
      clientToken: json['client_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      providerData: (json['provider_data'] as Map?)
          ?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'provider_id': providerId,
        'amount': amount,
        'currency': currency.code,
        'method': method.name,
        'status': status.name,
        'verification_type': verificationRequired.name,
        'verification_reference': verificationReference,
        'redirect_url': redirectUrl,
        'client_token': clientToken,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'provider_data': providerData,
      };
}

// ── PaymentResult ──────────────────────────────────────────────────────────────
// Final outcome returned after server-side confirmation.

class PaymentResult {
  final bool success;
  final String? transactionId;     // Our internal transaction ID
  final String? providerReference; // Provider's reference (e.g. ZainCash txRef)
  final String? errorCode;
  final String? errorMessage;
  final String? errorMessageAr;
  final PaymentSession? session;
  final Map<String, dynamic>? metadata;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.providerReference,
    this.errorCode,
    this.errorMessage,
    this.errorMessageAr,
    this.session,
    this.metadata,
  });

  factory PaymentResult.success({
    required String transactionId,
    required String providerReference,
    required PaymentSession session,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      providerReference: providerReference,
      session: session,
      metadata: metadata,
    );
  }

  factory PaymentResult.failure({
    required String errorCode,
    required String errorMessage,
    String? errorMessageAr,
    PaymentSession? session,
  }) {
    return PaymentResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      errorMessageAr: errorMessageAr,
      session: session,
    );
  }
}

// ── PaymentInitiationResult ────────────────────────────────────────────────────
// Returned when payment is initiated — may require further verification.

class PaymentInitiationResult {
  final bool requiresVerification;
  final VerificationType verificationType;
  final PaymentSession session;
  final String? messageAr;

  const PaymentInitiationResult({
    required this.requiresVerification,
    required this.verificationType,
    required this.session,
    this.messageAr,
  });
}

// ── Payment Inputs ─────────────────────────────────────────────────────────────
// NEVER persist these. Pass directly to provider for server-side tokenization.

sealed class PaymentInput {
  const PaymentInput();
}

/// Card payment — raw card data must reach the provider's tokenization endpoint
/// within the same request and NEVER be stored on our servers.
class CardPaymentInput extends PaymentInput {
  final String cardNumber;    // Will be tokenized; never log or persist
  final String cardholderName;
  final String expiryMonth;   // MM
  final String expiryYear;    // YY
  final String cvv;           // Discarded after tokenization
  final BillingInfo? billingInfo;

  const CardPaymentInput({
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    this.billingInfo,
  });

  String get maskedNumber {
    final c = cardNumber.replaceAll(' ', '');
    if (c.length < 4) return '•••• •••• •••• ••••';
    return '•••• •••• •••• ${c.substring(c.length - 4)}';
  }

  bool get isValid {
    final c = cardNumber.replaceAll(' ', '');
    return c.length >= 13 &&
        c.length <= 19 &&
        expiryMonth.isNotEmpty &&
        expiryYear.isNotEmpty &&
        cvv.length >= 3 &&
        cardholderName.trim().isNotEmpty;
  }
}

class WalletPaymentInput extends PaymentInput {
  final String phoneNumber;
  final String? walletOwnerName;

  const WalletPaymentInput({
    required this.phoneNumber,
    this.walletOwnerName,
  });

  bool get isValid {
    final c = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return c.length >= 10;
  }
}

class BankTransferPaymentInput extends PaymentInput {
  final String accountHolder;
  final String bankName;
  final String? transferReference;

  const BankTransferPaymentInput({
    required this.accountHolder,
    required this.bankName,
    this.transferReference,
  });
}

class CashPaymentInput extends PaymentInput {
  final String? notes;
  final String? receiverName;

  const CashPaymentInput({this.notes, this.receiverName});
}

class BillingInfo {
  final String? name;
  final String? email;
  final String? phone;
  final String? city;
  final String? country;

  const BillingInfo({
    this.name,
    this.email,
    this.phone,
    this.city,
    this.country,
  });
}

// ── PaymentMethodCard ─────────────────────────────────────────────────────────
// Display-only descriptor for each payment method in the card selector UI.

class PaymentMethodCard {
  final PaymentMethodType type;
  final String nameAr;
  final String descriptionAr;
  final String? feesNote;
  final LinearGradient gradient;
  final Color accentColor;
  final IconData icon;
  final bool isActive;
  final bool isRecommended;

  const PaymentMethodCard({
    required this.type,
    required this.nameAr,
    required this.descriptionAr,
    required this.gradient,
    required this.accentColor,
    required this.icon,
    this.feesNote,
    this.isActive = true,
    this.isRecommended = false,
  });
}

/// Default set of payment method cards shown in the selector.
/// Order matches PaymentMethod.values in donations_provider.dart:
/// 0=zaincash, 1=superki, 2=visa, 3=mastercard, 4=bankTransfer, 5=cash
const kDefaultPaymentCards = <PaymentMethodCard>[
  PaymentMethodCard(
    type: PaymentMethodType.zaincash,
    nameAr: 'زين كاش',
    descriptionAr: 'محفظة زين كاش الإلكترونية — تحقق برمز OTP',
    feesNote: 'بدون رسوم إضافية',
    gradient: LinearGradient(
      colors: [Color(0xFF0F52BA), Color(0xFF003D7A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFF4DA6FF),
    icon: Icons.phone_android_rounded,
    isRecommended: true,
  ),
  PaymentMethodCard(
    type: PaymentMethodType.superki,
    nameAr: 'سوبر كي',
    descriptionAr: 'محفظة سوبر كي الإلكترونية',
    gradient: LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFFA78BFA),
    icon: Icons.wallet_rounded,
  ),
  PaymentMethodCard(
    type: PaymentMethodType.visa,
    nameAr: 'Visa Card',
    descriptionAr: 'بطاقة Visa ائتمانية أو خصم مباشر',
    feesNote: '2.5% رسوم المعالجة',
    gradient: LinearGradient(
      colors: [Color(0xFF1C1C3A), Color(0xFF0D1B4B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFFFFD700),
    icon: Icons.credit_card_rounded,
  ),
  PaymentMethodCard(
    type: PaymentMethodType.mastercard,
    nameAr: 'MasterCard',
    descriptionAr: 'بطاقة MasterCard مع تحقق 3D Secure',
    feesNote: '2.5% رسوم المعالجة',
    gradient: LinearGradient(
      colors: [Color(0xFF3D1A6E), Color(0xFF0D6E5A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFFFF6B6B),
    icon: Icons.credit_score_rounded,
  ),
  PaymentMethodCard(
    type: PaymentMethodType.bankTransfer,
    nameAr: 'تحويل بنكي',
    descriptionAr: 'تحويل مباشر عبر IBAN',
    gradient: LinearGradient(
      colors: [Color(0xFF134E5E), Color(0xFF1B6B4A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFF71B280),
    icon: Icons.account_balance_rounded,
  ),
  PaymentMethodCard(
    type: PaymentMethodType.cash,
    nameAr: 'نقداً',
    descriptionAr: 'دفع نقدي مباشر عند التسليم',
    gradient: LinearGradient(
      colors: [Color(0xFF2C3E6B), Color(0xFF1A2A5E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFF7EB6FF),
    icon: Icons.payments_rounded,
  ),
];
