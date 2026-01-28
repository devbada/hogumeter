# Receipt Templates Feature Specification

## Overview

The Receipt Templates feature allows users to customize the visual appearance of their trip receipt images when sharing or saving to photos. Users can choose from 5 distinct template styles, each with unique colors, typography, and layout.

## Templates

### 1. Classic (클래식)
- **Description**: Default receipt style
- **Theme**: White background with blue accents
- **Header**: Horse emoji with "호구미터" title
- **Features**: Full fare breakdown, route map, time info

### 2. Modern (모던)
- **Description**: Clean, minimal design
- **Theme**: Off-white background with gray tones
- **Header**: Text-only "HOGUMETER" with light font
- **Features**: Thin dividers, subtle contrast

### 3. Fun (재미)
- **Description**: Playful, emoji-rich style
- **Theme**: Warm cream background with orange accents
- **Header**: Multiple emojis "🏇💨" with fun subtitle
- **Features**: Emoji prefixes for all labels, dashed dividers

### 4. Minimal (심플)
- **Description**: Essential information only
- **Theme**: White background, black text
- **Header**: Simple "HoguMeter" text
- **Features**: Large total fare display, no route map, compact layout

### 5. Premium (프리미엄)
- **Description**: Luxury gold theme
- **Theme**: Dark background with gold text
- **Header**: Crown emoji "👑" with gold title
- **Features**: Gold accents, elegant typography

## Technical Implementation

### Files Structure
```
HoguMeter/Presentation/Views/Receipt/
├── ReceiptView.swift          # Main receipt preview view
└── Templates/
    ├── ReceiptTemplate.swift          # Template enum and color scheme
    ├── TemplateSelectionView.swift    # Template picker UI
    └── TemplateReceiptGenerator.swift # Per-template image generation
```

### Key Components

#### ReceiptTemplate Enum
```swift
enum ReceiptTemplate: String, CaseIterable, Codable {
    case classic, modern, fun, minimal, premium
}
```

#### ReceiptColorScheme
Defines per-template colors:
- backgroundColor
- primaryTextColor
- secondaryTextColor
- accentColor
- dividerColor
- highlightBackgroundColor

### Settings Integration

Template preference is stored in `SettingsRepository`:
```swift
var receiptTemplate: ReceiptTemplate {
    get { /* read from UserDefaults */ }
    set { /* save to UserDefaults */ }
}
```

### User Flow

1. User completes a trip or views trip history detail
2. Opens receipt view (영수증 공유)
3. Taps template name in toolbar to open picker
4. Selects desired template
5. Preview updates immediately
6. Captures/saves with selected template

## Crash Fix (Priority)

### Fixed Issues
All force unwraps that could cause crashes have been replaced with safe optional handling:

1. **routeMapCanvas** (line 345, 349)
   - `points.first!` → `if let firstRoutePoint = points.first`
   - `points.last!` → `if let lastRoutePoint = points.last`

2. **drawRouteOnSnapshot** (line 527-541)
   - Safe optional binding for start/end coordinates

3. **driverQuote check** (line 606)
   - `trip.driverQuote!.isEmpty` → `trip.driverQuote.map { !$0.isEmpty } ?? false`

4. **ReceiptImageGenerator.drawRouteMap** (line 758-759)
   - Safe array access for route markers

5. **captureReceipt()** (line 388-405)
   - Added duplicate call prevention guard
   - Ensured isSaving state always resets

## Testing

### Manual Test Cases
1. [ ] Open receipt with empty routePoints array
2. [ ] Open receipt with nil driverQuote
3. [ ] Open receipt with single routePoint
4. [ ] Switch between all 5 templates
5. [ ] Save receipt with each template
6. [ ] Verify template preference persists after app restart

### Automated Tests
Unit tests should cover:
- Template color scheme generation
- Empty/nil data handling in generators
- Settings persistence for template preference

## Version
- Feature Version: 1.4.0
- Build: 1
