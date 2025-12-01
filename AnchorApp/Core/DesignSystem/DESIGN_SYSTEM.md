# Anchor Design System

## Overview
Unified design system for luxury purple-themed, minimalist iOS app with glassmorphism effects and light/dark mode support.

---

## 🎨 Color Palette

### Primary Colors (Luxury Purple)
- `anchorPrimary`: Deep royal purple (#3A0CA3)
- `anchorPrimaryDark`: Ultra-dark purple (#1A0A3A)
- `anchorAccent`: Electric violet (#8B5CF6)
- `anchorLavender`: Soft lavender (#C4B5FD)

### Adaptive Colors
All background and text colors adapt to light/dark mode:

**Light Mode:**
- `background`: Soft white (#FAFAFC)
- `secondaryBackground`: Light lavender tint (#F2F0F7)
- `textPrimary`: Deep charcoal (#191926)
- `textSecondary`: Muted purple-gray (#666680)

**Dark Mode:**
- `background`: Onyx black (#0A0A0F)
- `secondaryBackground`: Ultra-dark purple (#1A1A24)
- `textPrimary`: Off-white (#F5F5F7)
- `textSecondary`: Soft grey-lavender (#B8B3D1)

### Status Colors
- `success`: Muted emerald (#10B981)
- `warning`: Deep amber/gold (#ECB120)
- `error`: Rich crimson (#DC3253)

### Glassmorphism Materials
- `glassMaterial`: Ultra-thin material with purple tint
- `cardMaterial`: Thin material for cards
- `panelMaterial`: Regular material for panels

---

## 📐 Spacing Scale (8pt Grid)

```swift
Theme.spacing      // 8pt
Theme.spacing2     // 16pt (default padding)
Theme.spacing3     // 24pt
Theme.spacing4     // 32pt
Theme.spacing5     // 40pt
Theme.spacing6     // 48pt
```

**Usage:**
- Use `Theme.spacing` for tight spacing (between related elements)
- Use `Theme.spacing2` for default padding and standard spacing
- Use `Theme.spacing3` for section spacing
- Use `Theme.spacing4+` for large gaps and breathing room

---

## 🔤 Typography Scale

### Display (Large Headings)
- `display`: 48pt, bold, rounded
- `display2`: 40pt, bold, rounded

### Headings
- `largeTitle`: 34pt, bold
- `title`: 28pt, bold
- `title2`: 22pt, semibold
- `title3`: 20pt, semibold

### Body Text
- `body`: 17pt, regular
- `bodyBold`: 17pt, semibold
- `bodyMedium`: 17pt, medium

### Subheadings
- `subheadline`: 15pt, regular
- `subheadlineBold`: 15pt, semibold

### Caption
- `caption`: 13pt, regular
- `captionBold`: 13pt, semibold
- `caption2`: 12pt, regular
- `caption2Bold`: 12pt, semibold

### Labels
- `label`: 11pt, medium
- `labelBold`: 11pt, bold

---

## 🔘 Button Styles

### Primary Button
```swift
Button("Action") { }
    .buttonStyle(PrimaryButtonStyle())
```
- Purple gradient background (accent → primary)
- White text
- Shadow with purple glow
- Use for main actions

### Secondary Button
```swift
Button("Action") { }
    .buttonStyle(SecondaryButtonStyle())
```
- Outlined with purple gradient border
- Purple text
- Transparent background
- Use for secondary actions

### Tertiary Button
```swift
Button("Action") { }
    .buttonStyle(TertiaryButtonStyle())
```
- Text-only, purple color
- Minimal styling
- Use for subtle actions

### Danger Button
```swift
Button("Delete") { }
    .buttonStyle(DangerButtonStyle())
```
- Red background
- White text
- Use for destructive actions

### Ghost Button
```swift
Button("Cancel") { }
    .buttonStyle(GhostButtonStyle())
```
- Minimal text button
- Secondary text color
- Use for cancel/dismiss actions

---

## 📦 Card Components

### Glass Card (Glassmorphism)
```swift
GlassCard {
    // Content
}
```
- Ultra-thin material with purple tint
- Gradient border
- Subtle shadow
- Use for elevated content

### Solid Card
```swift
SolidCard {
    // Content
}
```
- Solid background (secondaryBackground)
- Gradient border
- Use for standard content cards

### Gradient Card
```swift
GradientCard {
    // Content
}
```
- Gradient background
- Enhanced shadow
- Use for highlighted content

---

## 📝 Text Field Styles

### Standard Text Field
```swift
TextField("Placeholder", text: $text)
    .textFieldStyle(AppTextFieldStyle())
```
- Purple-tinted border
- Secondary background
- Standard padding

### Search Field
```swift
TextField("Search", text: $searchText)
    .textFieldStyle(SearchFieldStyle())
```
- Rounded corners
- Secondary background
- Optimized for search bars

---

## 🎭 Corner Radius Scale

```swift
Theme.cornerRadiusSmall    // 8pt
Theme.cornerRadius         // 12pt (default)
Theme.cornerRadiusMedium   // 16pt (cards, buttons)
Theme.cornerRadiusLarge    // 24pt
Theme.cornerRadiusXLarge   // 32pt
```

**Usage:**
- Small: Chips, badges
- Default: General use
- Medium: Cards, buttons (most common)
- Large: Sheets, modals
- XLarge: Special cases

---

## ✨ Animation Constants

### Durations
```swift
Theme.animationFast    // 0.2s
Theme.animationMedium  // 0.3s
Theme.animationSlow    // 0.5s
```

### Spring Animations
```swift
Theme.springAnimation      // Standard (0.4s, 0.8 damping)
Theme.springAnimationFast   // Fast (0.3s, 0.7 damping)
Theme.springAnimationSlow   // Slow (0.6s, 0.85 damping)
```

**Usage:**
- Fast: Button presses, quick transitions
- Medium: Standard transitions
- Slow: Complex animations, page transitions

---

## 🎨 Shadow System

```swift
// Standard shadow
.shadow(
    color: AppColors.anchorAccent.opacity(0.3),
    radius: Theme.shadowRadius,  // 12pt
    x: 0,
    y: 4
)

// Large shadow
.shadow(
    color: AppColors.anchorPrimary.opacity(0.3),
    radius: Theme.shadowRadiusLarge,  // 24pt
    x: 0,
    y: 8
)
```

**Usage:**
- Standard: Cards, buttons
- Large: Elevated modals, sheets

---

## 🌓 Light/Dark Mode

All colors automatically adapt using the `Color(light:dark:)` initializer:

```swift
static var background: Color {
    Color(light: backgroundLight, dark: backgroundDark)
}
```

The system respects `@Environment(\.colorScheme)` automatically.

---

## 📱 Component Usage Guidelines

### Spacing Between Elements
- Related items: `Theme.spacing` (8pt)
- Standard spacing: `Theme.spacing2` (16pt)
- Section spacing: `Theme.spacing3` (24pt)
- Large gaps: `Theme.spacing4+` (32pt+)

### Card Padding
- Standard: `Theme.spacing2` (16pt)
- Compact: `Theme.spacing` (8pt)
- Spacious: `Theme.spacing3` (24pt)

### Button Padding
- Standard: `.padding(.vertical, Theme.spacing2)`
- Compact: `.padding(.vertical, Theme.spacing)`

### Screen Padding
- Standard: `Theme.spacing2` (16pt)
- Spacious: `Theme.spacing3` (24pt)

---

## 🎯 Design Principles

1. **Minimalism**: Clean, uncluttered interfaces
2. **Luxury Purple**: Consistent purple theming throughout
3. **Glassmorphism**: Subtle blur effects for depth
4. **8pt Grid**: All spacing follows 8pt grid system
5. **Consistent Typography**: Use typography scale, never arbitrary sizes
6. **Smooth Animations**: Spring animations for natural feel
7. **Adaptive**: Full light/dark mode support

---

## ✅ Checklist for New Screens

- [ ] Use Theme spacing constants (no hardcoded values)
- [ ] Use AppTypography (no arbitrary font sizes)
- [ ] Use AppColors (no hardcoded colors)
- [ ] Use button styles from AppButtonStyle
- [ ] Use card components for content containers
- [ ] Apply glassmorphism where appropriate
- [ ] Test in both light and dark mode
- [ ] Use spring animations for transitions
- [ ] Follow 8pt grid for all spacing
- [ ] Use corner radius from Theme scale

---

**Last Updated:** 2024

