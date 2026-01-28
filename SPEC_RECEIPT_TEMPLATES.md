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

## Direct SNS Sharing (v1.3.1)

### Share Destinations

| Destination | Icon | Description |
|-------------|------|-------------|
| 카카오톡 | message.fill | Save to photos + open KakaoTalk |
| 인스타그램 | camera.fill | Share to Instagram Stories |
| 메시지 | bubble.left.fill | iMessage with attachment |
| 저장 | square.and.arrow.down | Save to photo library |
| 복사 | doc.on.doc | Copy to clipboard |
| 더보기 | ellipsis | iOS native share sheet |

### Technical Implementation

#### Files
```
HoguMeter/
├── Domain/Services/
│   └── ReceiptShareService.swift    # Centralized share handling
└── Presentation/Views/Receipt/
    └── ShareButtonsView.swift       # Share buttons grid UI
```

#### Info.plist Configuration
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaolink</string>
    <string>kakaotalk</string>
    <string>instagram</string>
    <string>instagram-stories</string>
</array>
```

### Share Flow
1. Receipt image is auto-generated when view appears
2. User taps share button (KakaoTalk, Instagram, etc.)
3. ShareService checks app availability
4. Executes platform-specific share logic
5. Shows confirmation or error alert

## Testing

### Manual Test Cases

#### Template Tests
1. [ ] Open receipt with empty routePoints array
2. [ ] Open receipt with nil driverQuote
3. [ ] Open receipt with single routePoint
4. [ ] Switch between all 5 templates
5. [ ] Save receipt with each template
6. [ ] Verify template preference persists after app restart

#### SNS Sharing Tests
7. [ ] KakaoTalk installed → Opens KakaoTalk after save
8. [ ] KakaoTalk not installed → Shows alert
9. [ ] Instagram installed → Opens Instagram Stories
10. [ ] Instagram not installed → Shows alert
11. [ ] iMessage → Opens message composer with attachment
12. [ ] Save to Photos → Saves and shows confirmation
13. [ ] Copy → Copies to clipboard and shows confirmation
14. [ ] More → Opens iOS share sheet
15. [ ] No crash on rapid button taps
16. [ ] Loading indicator shows during share process

### Automated Tests
Unit tests should cover:
- Template color scheme generation
- Empty/nil data handling in generators
- Settings persistence for template preference
- ShareDestination availability checks

## Version
- Feature Version: 1.3.1
- Build: 1
