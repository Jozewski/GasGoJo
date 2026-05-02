import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand orange ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFF97316);       // orange-500
  static const Color primaryDark = Color(0xFFEA580C);   // orange-600
  static const Color primaryLight = Color(0xFFFED7AA);  // orange-200
  static const Color primaryContainer = Color(0xFFFFF7ED); // orange-50

  // ── Slate dark ───────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF0F172A);     // slate-900
  static const Color secondaryLight = Color(0xFF334155); // slate-700

  // ── Emerald accent ───────────────────────────────────────────────────────
  static const Color accent = Color(0xFF059669);        // emerald-600
  static const Color accentDark = Color(0xFF047857);    // emerald-700
  static const Color accentContainer = Color(0xFFECFDF5); // emerald-50

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFD97706);       // amber-600
  static const Color warningContainer = Color(0xFFFFFBEB); // amber-50
  static const Color error = Color(0xFFDC2626);         // red-600
  static const Color errorContainer = Color(0xFFFEF2F2); // red-50
  static const Color success = Color(0xFF059669);       // emerald-600

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFC);       // slate-50
  static const Color surfaceVariant = Color(0xFFF1F5F9); // slate-100
  static const Color white = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);   // slate-900
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color textDisabled = Color(0xFF94A3B8);  // slate-400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);        // slate-200
  static const Color borderFocus = Color(0xFFF97316);   // orange-500

  // ── Price tiers ──────────────────────────────────────────────────────────
  static const Color priceCheap = Color(0xFF059669);    // emerald-600
  static const Color priceMid = Color(0xFFD97706);      // amber-600
  static const Color priceHigh = Color(0xFFDC2626);     // red-600

  // ── Map ──────────────────────────────────────────────────────────────────
  static const Color mapBackground = Color(0xFFE8EDF2); // cool slate tint

  // ── Gradient ─────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
  );
}
