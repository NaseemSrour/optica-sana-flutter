# Progression Feature — AI Iteration Notes

Quick reference for future AI-assisted iterations on the **Prescription
Progression Graph** feature. Read this first before editing anything in
`lib/features/progression/`.

## Purpose

Visualize how a customer's glasses prescription drifts over time. Lives at
`lib/features/progression/` and is launched from `customer_details_screen.dart`
via the `Icons.insights` IconButton (tooltip key: `prog_tooltip_open`).

## Module layout

```
lib/features/progression/
├── models/
│   └── rx_data_point.dart        # RxDataPoint, RxMetric, Eye + +cyl→-cyl normalization
├── logic/
│   ├── progression_view_model.dart   # sorting, FlSpot mapping, bounds, intervals
│   └── dummy_data.dart               # ProgressionDummyData.generate(...) for testing
├── widgets/
│   ├── progression_chart.dart        # fl_chart LineChart + EyeColors + empty state
│   ├── progression_summary.dart      # Visits / Latest-per-eye / Delta cards
│   ├── progression_legend.dart       # OD/OS color dots
│   └── progression_delta_strip.dart  # Visit-to-visit pills
└── screens/
    └── progression_screen.dart       # Hosts everything, owns metric & invertY toggles
```

## Key design decisions

- **Cylinder convention:** All input cylinders are normalized to negative-cyl
  form in `RxDataPoint._normalize`:
  `sph' = sph + cyl`, `cyl' = -cyl`, `axis' = (axis + 90) % 180`. Always
  construct via `RxDataPoint.fromGlassesTest`; do not bypass the normalizer.
- **Eye colors** (in `progression_chart.dart`, `EyeColors`):
  - `right` (OD) = `0xFF4FC3F7` sky blue
  - `left`  (OS) = `0xFFEF5350` soft red
  Reused by legend, summary, and delta strip.
- **Y-axis invert:** Optional. When `invertY: true`, worsening myopia trends
  downward (matches printed Rx charts). Implemented by flipping spot Y and
  swapping min/max — value labels still show the real signed diopters.
- **Scroll behavior:** `ProgressionViewModel.shouldEnableScroll` is `true`
  when span > 5 years. Chart is then wrapped in a horizontal `Scrollbar` +
  `SingleChildScrollView` with `_minPixelsPerYear = 90`.
- **Adaptive intervals:** `yLabelInterval()` picks 0.25 / 0.5 / 1 / 2 D;
  `xLabelInterval()` picks 1/12 (monthly), 0.25 (quarterly), 1 (yearly),
  2 (biyearly) based on span.
- **Empty state:** `<2` data points renders a friendly card with icon +
  message keys `prog_empty_one_*` / `prog_empty_zero_*`. The view model's
  `hasEnoughData` guard is the single source of truth.
- **Dummy data flag:** `ProgressionScreen.useDummyData` swaps the data source
  to `ProgressionDummyData.generate(...)`. Default is `false`. Useful for
  screenshots / demos without touching the DB.

## fl_chart 0.69.x API gotchas

- Use `getTooltipColor: (_) => ...` (not the older `tooltipBgColor`).
- Use `Color.withValues(alpha: x)` (not deprecated `withOpacity`).
- `FlClipData.all()` keeps overflow clean when scrolling.
- `LineTouchTooltipData` requires `tooltipBorder` (not `tooltipBorderSide`).

## Localization rules — IMPORTANT

User explicitly requested: **graph axis labels stay English/LTR** and
**time-based stats stay LTR** even under RTL locales (he/ar). Implementation:

1. **Chart axis labels are forced English:**
   - `prog_axis_diopters` is `"Diopters"` in **all three** locales
     (`en.json`, `he.json`, `ar.json`). Do NOT translate this value when
     adding new locales — keep it English so the chart stays neutral.
   - X-axis date labels use `DateFormat('MMM yy', 'en')` /
     `DateFormat('yyyy', 'en')`.
   - Tooltip dates use `DateFormat('dd MMM yyyy', 'en')`.
2. **Chart canvas is wrapped in `Directionality(textDirection: ltr, ...)`**
   inside `progression_chart.dart` so the whole plot area is LTR even when
   the rest of the app is RTL.
3. **Time-based stats are wrapped in LTR `Directionality`:**
   - The "Visits" card span label (`Jan 2020 → Jan 2026`) — `_Card` has a
     `ltrSecondary: true` flag that wraps the secondary line.
   - `_EyeCard` latest-visit `dateLabel` (uses `DateFormat(..., 'en')`).
   - The chronological pill row in `progression_delta_strip.dart` (oldest →
     newest) is wrapped in LTR so direction stays consistent.
4. **Tooltip strings in delta strip** also use `DateFormat('MMM yyyy', 'en')`.

When adding any new feature that shows dates or chronological direction,
**preserve this LTR/English contract** unless the user says otherwise.

## Translation keys (prefix `prog_`)

Lives in `assets/translations/{en,he,ar}.json`. Current keys:

```
prog_title (named: {name})
prog_tooltip_open
prog_metric_sphere / prog_metric_cylinder
prog_chart_title_sphere / prog_chart_title_cylinder
prog_invert_y / prog_invert_y_tooltip
prog_flip_y / prog_flip_y_inverted
prog_scroll_tip
prog_load_error (named: {error})
prog_axis_diopters                     ← keep "Diopters" in all locales
prog_legend_right / prog_legend_left
prog_empty_one_title / prog_empty_zero_title
prog_empty_one_body / prog_empty_zero_body
prog_summary_visits
prog_summary_latest_right / prog_summary_latest_left
prog_summary_change_right / prog_summary_change_left  (named: {metric})
prog_kv_sph / prog_kv_cyl / prog_kv_axis
prog_trend_stable / prog_trend_more_minus / prog_trend_less_minus
prog_strip_title / prog_strip_no_data
prog_eye_short_right / prog_eye_short_left
prog_notes_edit / prog_notes_save / prog_notes_cancel
prog_notes_hint / prog_notes_empty
prog_notes_saved / prog_notes_save_error  (named: {error})
```

The notes panel at the bottom of `progression_screen.dart` re-uses the
existing `field_notes` label key. It edits `Customer.notes` in place and
persists via `CustomerService.updateCustomer`, mirroring the read/edit
toggle pattern in `customer_details_screen.dart`.

## How data flows

```
GlassesTest (DB row, +cyl convention)
  │
  ▼  RxDataPoint.fromGlassesTest → _normalize → -cyl convention
  ▼
List<RxDataPoint>
  │
  ▼  ProgressionViewModel(points, metric)
  │     - sorts by date asc
  │     - spotsFor(eye) → List<FlSpot>
  │     - xBounds / yBounds / intervals
  │     - totalDelta, latest, hasEnoughData
  ▼
Widgets:
  - ProgressionChart        (LineChart + axes + tooltips)
  - ProgressionSummary      (Visits / Latest / Delta cards)
  - ProgressionDeltaStrip   (visit-to-visit pills)
  - ProgressionLegend       (OD/OS dots)
```

## Sources of customer data

- Real: `CustomerService.getGlassesHistory(customerId)` returns
  `List<GlassesTest>`.
- Dummy: `ProgressionDummyData.generate(customerId, years: 8, testsPerYear: 1, seed: 42)`.

Toggle via `ProgressionScreen(useDummyData: true)`.

## Common iteration tasks — quick playbook

- **Add a new summary metric:** add card to `progression_summary.dart`, add
  any new translation keys to all 3 locale files (preserving LTR rules for
  date-based content).
- **Change color theme:** update `EyeColors` in `progression_chart.dart`;
  legend, summary, and delta strip all read from there.
- **Add a third eye/series (e.g., "binocular avg"):** extend `Eye` enum in
  `rx_data_point.dart`, add accessor in `value()`, add a new
  `_seriesFor(...)` line in `_buildChart`.
- **Tweak adaptive intervals / scroll threshold:** all in
  `progression_view_model.dart` — single source of truth.
- **Add another metric (e.g., axis trend):** extend `RxMetric` enum and the
  `value()` switch in `RxDataPoint`. Update SegmentedButton in
  `progression_screen.dart`.

## Things to NOT break

- `prog_axis_diopters` MUST stay `"Diopters"` in all locales.
- `DateFormat` calls inside this feature MUST pass `'en'` as the locale
  for chart/stat labels (tooltips, axis, span).
- Chart canvas wrapped in `Directionality(ltr)`. Don't remove.
- Cylinder normalization in `RxDataPoint._normalize` — never bypass.
- `ProgressionViewModel` sorts ascending; downstream widgets assume it.

## Dependency

- `fl_chart: ^0.69.0` (resolved 0.69.2) in `pubspec.yaml`.
- `easy_localization`, `intl`, `shared_preferences` already in app.

## Entry point

`customer_details_screen.dart` → IconButton with `Icons.insights`,
tooltip `'prog_tooltip_open'.tr()` → pushes `ProgressionScreen(customer, customerService)`.
