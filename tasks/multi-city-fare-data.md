# Feature Specification: Multi-City Taxi Fare Data

**Task ID:** FARE-DATA-001
**Created:** 2025-12-23
**Branch:** feature/multi-city-fare-data
**Status:** Completed

## Goal
Add fare policy DATA for 6 additional cities to existing structure.

## Target Cities to ADD (6 new)
1. 부산광역시 (Busan)
2. 대구광역시 (Daegu)
3. 인천광역시 (Incheon)
4. 광주광역시 (Gwangju)
5. 대전광역시 (Daejeon)
6. 경기도 (Gyeonggi-do)

## Existing
- 서울특별시 (Seoul) - already exists

## Fare Data Requirements

For each city, need:
- 기본요금 (Base fare) - won
- 기본거리 (Base distance) - meters
- 거리요금 (Distance fare) - won per X meters
- 시간요금 (Time fare) - won per X seconds
- 심야할증 (Night surcharge) - percentage and hours

## Implementation Plan

1. [x] Find existing fare data structure
2. [x] Research current fare policies for each city
3. [x] Add data entries following existing format
4. [x] Verify build succeeds
5. [ ] Test city selection works (manual testing required)

## Important Constraints

- Do NOT modify existing feature code
- Do NOT change data structure
- ONLY add new city data entries following existing pattern

## Data Sources

| City | Source | Date |
|------|--------|------|
| 서울 | [서울시 택시요금](https://news.seoul.go.kr/traffic/archives/1659) | 2024.02 |
| 부산 | [부산광역시 택시요금](https://www.busan.go.kr/depart/ahtaxi03) | 2023.06 |
| 대구 | [대구시 택시요금](https://dgmbc.com/article/EsOW21ACXDT) | 2025.02 |
| 인천 | [인천광역시 택시요금](https://www.incheon.go.kr/traffic/TR010201) | 2023.07 |
| 광주 | [광주광역시 택시요금](https://www.gjcity.go.kr/portal/bbs/view.do?bIdx=316312) | 2023.07 |
| 대전 | [대전광역시 택시요금](http://www.djtaxi.com/usage/usage.php) | 2023.07 |
| 경기 | [경기도 택시요금](https://www.kgnews.co.kr/news/article.html?no=753808) | 2023.07 |

## Fare Data Summary

| City | Base Fare | Base Distance | Distance Fare | Time Fare | Night Surcharge |
|------|-----------|---------------|---------------|-----------|-----------------|
| 서울 | 4,800원 | 1.6km | 100원/131m | 100원/30s | 20%/40% |
| 부산 | 4,800원 | 2.0km | 100원/132m | 100원/33s | 20%/30% |
| 대구 | 4,500원 | 1.7km | 100원/125m | 100원/31s | 20%/30% |
| 인천 | 4,800원 | 1.6km | 100원/135m | 100원/33s | 20%/40% |
| 광주 | 4,300원 | 2.0km | 100원/134m | 100원/32s | 20% |
| 대전 | 4,300원 | 1.8km | 100원/132m | 100원/33s | 20% |
| 경기 | 4,800원 | 1.6km | 100원/131m | 100원/30s | 30% |

## Acceptance Criteria

- [x] All 7 cities have fare data
- [x] Build succeeds
- [ ] City selection shows all cities (manual test)
- [ ] Fare calculation works for each city (manual test)

## Files Modified

- `HoguMeter/Data/DataSources/Static/DefaultFares.json`
- `HoguMeter/Data/Resources/DefaultFares.json`

## Build Status

- [x] Build Succeeded (2025-12-23)
