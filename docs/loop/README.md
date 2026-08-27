# HoguMeter Loop Engineering

이 문서는 HoguMeter의 반복 개발 프로토콜입니다. 완료·취소된 run은 새 작업으로
덮어쓰지 않고 해당 run의 상태와 이유를 보존합니다.

## 목표

하나의 작은 사용자 가치를 구현하고, 독립 리뷰와 실행 검증을 통과할 때까지 반복합니다.
한 번의 run은 독립적으로 검토하고 되돌릴 수 있는 vertical slice 하나만 포함합니다.

## 상태 머신

```text
INTAKE
  -> READY
  -> BASELINE
  -> IMPLEMENTING
  -> READY_FOR_REVIEW
  -> REVIEWING
  -> READY_FOR_QA
  -> QA_AUTOMATED
  -> USER_QA_REQUIRED
  -> DONE

REVIEW_NEEDS_FIX -> IMPLEMENTING
QA_FAILED        -> IMPLEMENTING
```

- `BLOCKED`는 어느 단계에서든 사용할 수 있지만 owner, 원인, 해제 조건을 기록합니다.
- `CANCELLED`는 PM 또는 사용자 결정으로 중단된 terminal 상태이며 `DONE`을 의미하지 않습니다.
- 수동 QA가 필요하지 않으면 `QA_AUTOMATED`에서 바로 `DONE`으로 갈 수 있습니다.
- 수동 QA가 pending이면 `DONE`이 아닙니다. 면제는 사용자와 PM의 명시적 합의, 이유,
  날짜, 잔여 리스크를 기록해야 합니다.

## 역할

| 역할 | 책임 | 금지 |
|---|---|---|
| PM / Orchestrator | 문제 정의, 우선순위, AC, non-goals, slice, 상태 전이 | Review/QA 판정 대리 승인 |
| Explorer | 코드·문서·baseline·영향 범위 조사 | 제품 코드 편집 |
| Developer | 단일 writer로 구현, focused test, self-check, handoff | 승인 없는 scope 확대 |
| Reviewer | AC와 diff 추적, 회귀·동시성·보안·target membership 검토 | 직접 품질 판정 없이 수정만 수행 |
| QA | 실제 build/test 실행, 환경·exit·duration·결과 기록 | compile 성공을 test 성공으로 대체 |
| User QA | 실기기 UI·GPS·MapKit·thermal·충전 확인 | 증거 없는 완료 처리 |

## Run 구조

```text
docs/loop/runs/<YYYYMMDD>-<slug>/
├── TASK.md
├── STATUS.md
└── rounds/
    ├── 001-dev.md
    ├── 001-review.md
    └── 001-qa.md
```

- `TASK.md`: 구현 중 바꾸지 않는 입력 계약. 변경이 필요하면 PM decision을 기록합니다.
- `STATUS.md`: 현재 상태 하나만 기록하는 단일 진실원천입니다.
- `rounds/`: 매 라운드의 증거를 별도 파일에 남깁니다. 거대한 로그에 계속 append하지 않습니다.

## Ready 조건

- 사용자 문제와 사용자 가치
- `AC-01..n` 형식의 관찰 가능한 완료 조건
- non-goals와 범위
- 위험도, 의존성, 예상 변경 영역
- AC별 자동/수동 검증 방법
- rollback 또는 feature flag 필요 여부
- commit/push 권한

## Baseline

구현 전 아래를 기록합니다.

1. `git status --short`
2. 기준 branch와 commit
3. 관련 focused test
4. 가능한 경우 generic Simulator build
5. 기존 실패와 환경 blocker

같은 파일을 수정하는 run은 직렬화합니다. 병렬 agent는 read-only 조사, 테스트 설계,
독립 리뷰처럼 파일 ownership이 겹치지 않을 때만 사용합니다.

## Developer gate

- AC와 코드·테스트가 연결되어야 합니다.
- focused test와 `git diff --check`를 실행합니다.
- `project.pbxproj` 변경 시 target membership과 `plutil -lint`를 확인합니다.
- handoff에는 변경 경로, AC별 증거, 정확한 명령/exit, 미실행 항목, known risk를 적습니다.

## Review gate

- P0: 데이터 손실, 보안, crash, 핵심 기능 불능
- P1: 출시 차단, 잘못된 핵심 결과, compile/test 차단
- P2: 의미 있는 회귀·경계조건·유지보수 위험
- P3: 비차단 개선

P0/P1/P2가 있으면 `REVIEW_NEEDS_FIX`로 돌아갑니다. P3는 PM이 현재 수정 또는 backlog를
결정합니다. finding이 0개여도 검토 범위와 근거를 기록합니다.

## QA gate

권장 순서는 다음과 같습니다.

1. generic Simulator build
2. build-for-testing
3. booted Simulator에서 실제 test 실행
4. UI, 위치, thermal 항목의 User QA 이관

결과에는 환경, 명령, exit code, elapsed time, test summary, result bundle 또는 log 위치를
기록합니다. Simulator UUID를 문서나 스크립트에 고정하지 않습니다.

## Done 조건

- 모든 AC가 PASS이고 증거가 연결됨
- P0/P1/P2 0건
- focused/full automated gate 통과
- 필수 User QA 통과 또는 명시적 면제
- 범위 밖 diff 없음
- 문서, rollback, backlog 업데이트
- blocker 0건

커밋과 푸시는 이 조건과 별개이며 사용자 요청 범위에서만 수행합니다.

## Agent 모델 상한

내부 agent는 최대 `gpt-5.6-terra`를 사용합니다. 새 agent 생성 시 해당 모델을 명시하고
그보다 상위 모델은 사용하지 않습니다.
