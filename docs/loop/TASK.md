# HOGU-NAVIGATION-THERMAL-OPTIMIZATION

## 목표

주행 중 연속 위치 세션 1개, 위치당 경로 투영 1회, 단속카메라 색인·지도 갱신 예산·thermal 적응·geocode/network cache를 적용해 발열과 전력을 낮춥니다. 기준 문서: `docs/feature/HOGU_NAVIGATION_THERMAL_OPTIMIZATION.md`.

## 범위

1. 개인정보 없는 signpost/counter/thermal 관측.
2. 검색 one-shot 및 주행 위치 stream 단일화.
3. RouteProjectionIndex/NavigationFrame 공유.
4. speed camera route index 및 binary search.
5. camera/overlay update budget, animation/POI/blur 최적화.
6. thermal hysteresis policy.
7. geocode/network cache.

## 완료 조건

- B~F 핵심 기능 구현, 기존 요금·reroute·maneuver·snap·tab/title 회귀 없음.
- 단위/성능 테스트 및 개인정보 로그 검토.
- Code Review, QA, 실기기 A/B·충전 검증 기록.
