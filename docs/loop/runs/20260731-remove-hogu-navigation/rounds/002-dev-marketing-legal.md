# 002 Marketing / Legal Developer Follow-up — REMOVE-HOGU-NAV-001

- date: `2026-07-31`
- owner: `DEVELOPER`
- outcome: `PASS — AC-06 marketing/legal follow-up complete`
- branch: `codex/remove-hogu-navigation`

## Scope and implementation

| AC | Evidence |
| --- | --- |
| AC-06 | `docs/marketing/index.html` removes the HoguNavigation screenshot, feature card, speed-camera feature card, destination-route scenario, and destination-based fare wording. The hero metadata/subtitle now describe live, in-trip fare calculation only. Existing GPS meter, trip-map, receipt, history, statistics, and on-device-storage explanations remain. |
| AC-06 | `privacy.html`, `privacy-en.html`, `terms.html`, and `terms-en.html` remove HoguNavigation, speed-camera, public-data, recent-search/route, and dedicated API descriptions. The remaining Apple Maps/map-display/address-conversion, GPS, local storage, retention/deletion, rights, and safety/disclaimer notices are retained. |
| AC-06 | Korean and English section numbering is continuous after the removed sections. Effective/update dates are `2026-07-31`; summaries and cross-language/privacy/terms links remain aligned. Each legal page now also links to `index.html` with a localized Home label. |

## Review follow-up

- Independent reviewer reported one P2 semantic residual: the homepage description and subtitle still suggested destination-based estimated fares.
- Fixed in this round by changing them to live/in-trip fare wording. No P0/P1/P2 finding remains in the reviewed marketing/legal scope.

## Verification

| Check | Command | Result |
| --- | --- | --- |
| Removal residual scan | `rg -n -i 'HoguNavigation|hoguNavigation|호구게이션|SpeedCamera|PublicSpeedCameraServiceKey|PUBLIC_SPEED_CAMERA_SERVICE_KEY|speed.?camera|과속.?카메라|data\.go\.kr|공공데이터포털|external api|전용.*api|api.?key|API.?키|목적지까지 호구비|예상 호구비|destination-based fare prediction|estimated distance/time/fare|fare prediction' docs/marketing` | exit 0; 0 matches |
| Local legal links and anchors | shell check for every relative `href` in the four legal pages plus `rg` fragment-link scan | exit 0; all four pages PASS; no fragment links exist |
| Numbering inspection | `rg -n '<h[23]>' docs/marketing/{privacy,privacy-en,terms,terms-en}.html` | exit 0; Korean/English privacy sections 1–12 and terms sections 1–10 are continuous |
| HTML structure | Node structural-tag balance check for the five marketing pages | exit 0; all five pages PASS |
| Diff hygiene | `git diff --check` | exit 0 |

## Notes

- The system `tidy` is the 2006 HTML 3.2 implementation and does not understand HTML5 semantic elements or UTF-8 Korean text, so it was not used as a pass/fail validator. The structural tag-balance check above validates the unchanged HTML5 document structure without rewriting it.
- No staging, commit, or push was performed.
