## Imported Claude Cowork project instructions

## HoguMeter Loop Engineering

- 작업을 시작하기 전에 `docs/loop/README.md`를 읽고 그 상태 머신과 품질 게이트를 따릅니다.
- 제품 코드의 동시 편집자는 한 명만 둡니다. 병렬 agent는 조사, 테스트 설계, 코드 리뷰처럼 읽기 중심의 독립 작업에 사용합니다.
- 새 작업은 `docs/loop/runs/<YYYYMMDD>-<slug>/TASK.md`와 `STATUS.md`를 만든 뒤 시작합니다.
- Acceptance Criteria는 `AC-01`처럼 안정적인 ID를 사용하고 구현, 리뷰, QA 증거를 같은 ID에 연결합니다.
- 기존 변경을 보존하고 범위 밖 수정은 하지 않습니다.
- 단순 package resolve나 compile exit 0을 테스트 통과로 기록하지 않습니다. 실제 실행 명령, exit code, test summary와 미실행 항목을 남깁니다.
- P0/P1/P2 리뷰 지적이 남아 있으면 QA 또는 DONE으로 올리지 않습니다.
- 위치, MapKit, 발열, 충전처럼 자동화할 수 없는 항목은 `USER_QA_REQUIRED`로 유지하며 pending 상태를 DONE으로 간주하지 않습니다.
- 커밋과 푸시는 사용자가 요청한 경우에만 수행합니다.
- 내부 agent는 최대 `gpt-5.6-terra`까지만 사용합니다.
  `gpt-5.6-sol`을 포함한 상위 모델은 사용하지 않습니다.
