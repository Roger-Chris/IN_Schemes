/// Adaptive sizing / text-fit helpers used to keep fixed-design-width
/// widgets (pin boxes, chip containers, stat tiles, ...) from overflowing
/// when rendered with longer localized text or on narrower screens.
///
/// Prefer these over hardcoded `SizedBox(width: N)` / unguarded `Row`s
/// wherever the child is a Text (or contains one) whose length varies by
/// locale or data. See LOCALIZATION_AUDIT.md Phase 11 for the underlying
/// survey of overflow-risk sites this addresses.
library;

import 'package:flutter/material.dart';

/// Scales [base] linearly against the ratio of the current screen width to
/// [referenceWidth] (the width the design was authored at), clamped to
/// [min]/[max] so it never shrinks into unusable territory or grows past
/// the original design intent.
///
/// Uses `MediaQuery.of(context).size.width` rather than `LayoutBuilder`:
/// several existing screens nest fixed-size widgets inside an
/// `IntrinsicHeight` ancestor (for example, a scroll-sized form wrapper),
/// and `LayoutBuilder` cannot participate in intrinsic-dimension
/// computation in that position -- it throws at layout time. MediaQuery
/// has no such restriction.
double adaptiveSize(
  BuildContext context, {
  required double base,
  required double min,
  double? max,
  double referenceWidth = 375,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final scaled = base * (screenWidth / referenceWidth);
  final upperBound = max ?? base;
  return scaled.clamp(min, upperBound);
}

/// Derives an equal item width for a row of [count] fixed-size items (e.g.
/// OTP pin boxes, calculator result chips) from the width actually
/// available to that row, clamped to [min]/[max]. [availableWidth] must
/// already have any surrounding fixed padding subtracted by the caller --
/// this function does not know about ancestor padding.
///
/// [spacingFraction] reserves room for inter-item gaps; the default 0.86
/// (matching the OTP pin-box fix) leaves ~14% of the per-item share for
/// spacing when the row uses `MainAxisAlignment.spaceBetween`.
double adaptiveRowItemWidth({
  required double availableWidth,
  required int count,
  required double min,
  required double max,
  double spacingFraction = 0.86,
}) {
  final perItem = (availableWidth / count) * spacingFraction;
  return perItem.clamp(min, max);
}

/// Wraps [child] so it shrinks to fit its available space instead of
/// overflowing -- for text that should stay on one line but whose length
/// varies (timers, chip labels, button labels, currency amounts). Prefer
/// this over a bare `Text(overflow: TextOverflow.ellipsis)` when
/// truncating would hide meaningful content: FittedBox scales down
/// instead of clipping.
///
/// Must be given a bounded width by its parent (e.g. inside a `Flexible`
/// or a fixed-width `SizedBox`) -- like `FittedBox` itself, it does not
/// impose its own width constraint.
class FitOneLine extends StatelessWidget {
  const FitOneLine({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
  }
}

/// Thin `Flexible` convenience wrapper so call sites read intent
/// (`FlexText(child: Text(...))`) instead of a bare `Flexible`, for text
/// inside a `Row`/`Wrap` that should yield space and wrap to multiple
/// lines rather than overflow.
class FlexText extends StatelessWidget {
  const FlexText({super.key, required this.child, this.flex = 1});

  final Widget child;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Flexible(flex: flex, child: child);
  }
}
