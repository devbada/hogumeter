//
//  HoguMeterTests.swift
//  HoguMeterTests
//
//  Created by 조미남 on 12/12/25.
//

import Testing
import CoreLocation
import Combine
@testable import HoguMeter

struct HoguMeterTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func meterTimerGenerationGate_start세대만실행을허용한다() async throws {
        var gate = MeterTimerGenerationGate()
        let generation = gate.start()

        #expect(gate.accepts(capturedGeneration: generation, isRunning: true, hasTripStartTime: true))
        #expect(!gate.accepts(capturedGeneration: generation, isRunning: false, hasTripStartTime: true))
        #expect(!gate.accepts(capturedGeneration: generation, isRunning: true, hasTripStartTime: false))
    }

    @Test func meterTimerGenerationGate_stop과재시작은구callback을차단한다() async throws {
        var gate = MeterTimerGenerationGate()
        let staleGeneration = gate.start()
        gate.stop()
        let activeGeneration = gate.start()

        #expect(!gate.accepts(capturedGeneration: staleGeneration, isRunning: true, hasTripStartTime: true))
        #expect(gate.accepts(capturedGeneration: activeGeneration, isRunning: true, hasTripStartTime: true))
    }

    @Test func navigationSearchResultPolicy_정확중복은최초결과만유지한다() async throws {
        let results = [
            (title: "강남역", subtitle: "서울", marker: "first"),
            (title: "강남역", subtitle: "서울", marker: "duplicate"),
            (title: "시청역", subtitle: "서울", marker: "second")
        ]

        let visible = HoguNavigationSearchResultPolicy.visibleResults(
            results,
            title: { $0.title },
            subtitle: { $0.subtitle }
        )

        #expect(visible.map { $0.marker } == ["first", "second"])
    }

    @Test func navigationSearchResultPolicy_공백대소문자폭발음부호중복을정규화한다() async throws {
        let results = [
            (title: "  Café Ａ  ", subtitle: "  SEOUL  ", marker: "first"),
            (title: "cafe a", subtitle: "seoul", marker: "duplicate")
        ]

        let visible = HoguNavigationSearchResultPolicy.visibleResults(
            results,
            title: { $0.title },
            subtitle: { $0.subtitle }
        )

        #expect(visible.map { $0.marker } == ["first"])
    }

    @Test func navigationSearchResultPolicy_같은제목의다른부제는유지한다() async throws {
        let results = [
            (title: "중앙역", subtitle: "서울", marker: "seoul"),
            (title: "중앙역", subtitle: "부산", marker: "busan")
        ]

        let visible = HoguNavigationSearchResultPolicy.visibleResults(
            results,
            title: { $0.title },
            subtitle: { $0.subtitle }
        )

        #expect(visible.map { $0.marker } == ["seoul", "busan"])
    }

    @Test func navigationSearchResultPolicy_최초순서로최대12건만표시한다() async throws {
        let results = (0..<14).map {
            (title: "장소 \($0)", subtitle: "주소 \($0)", index: $0)
        }

        let visible = HoguNavigationSearchResultPolicy.visibleResults(
            results,
            title: { $0.title },
            subtitle: { $0.subtitle }
        )

        #expect(HoguNavigationSearchResultPolicy.visibleLimit == 12)
        #expect(visible.map { $0.index } == Array(0..<12))
    }

    @Test func navigationSearchResponseGate_A성공응답은B검색뒤거부한다() async throws {
        var gate = HoguNavigationSearchResponseGate()
        gate.advance()
        let responseA = gate.capture(query: "A", target: .destination)

        gate.advance()

        #expect(!gate.accepts(responseA, activeQuery: "B", selectedTarget: .destination))
    }

    @Test func navigationSearchResponseGate_A오류응답은B검색뒤거부한다() async throws {
        var gate = HoguNavigationSearchResponseGate()
        gate.advance()
        let errorA = gate.capture(query: "A", target: .destination)

        gate.advance()

        #expect(!gate.accepts(errorA, activeQuery: "B", selectedTarget: .destination))
    }

    @Test func navigationSearchResponseGate_같은검색어도target변경뒤거부한다() async throws {
        var gate = HoguNavigationSearchResponseGate()
        gate.advance()
        let originResponse = gate.capture(query: "시청", target: .origin)

        gate.advance()

        #expect(!gate.accepts(originResponse, activeQuery: "시청", selectedTarget: .destination))
    }

    @Test func navigationSearchResponseGate_현재token만허용한다() async throws {
        var gate = HoguNavigationSearchResponseGate()
        gate.advance()
        let activeResponse = gate.capture(query: "  시청  ", target: .destination)

        #expect(gate.accepts(activeResponse, activeQuery: "시청", selectedTarget: .destination))
    }

    @Test func navigationRouteCalculationGate_현재계산성공을허용한다() async throws {
        var gate = HoguNavigationRouteCalculationGate()
        let activeGeneration = gate.start()

        #expect(gate.accepts(activeGeneration))
    }

    @Test func navigationRouteCalculationGate_reset후이전성공을차단한다() async throws {
        var gate = HoguNavigationRouteCalculationGate()
        let staleGeneration = gate.start()
        gate.invalidate()

        #expect(!gate.accepts(staleGeneration))
    }

    @Test func navigationRouteCalculationGate_새계산은이전계산을차단한다() async throws {
        var gate = HoguNavigationRouteCalculationGate()
        let staleGeneration = gate.start()
        let activeGeneration = gate.start()

        #expect(!gate.accepts(staleGeneration))
        #expect(gate.accepts(activeGeneration))
    }

    @Test func routeProjection_긴선분중간에서진행거리와거리를계산한다() async throws {
        let route = [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.01)
        ]
        let vehicle = CLLocationCoordinate2D(latitude: 37.0, longitude: 127.005)

        let projection = try #require(HoguNavigationRouteProjector.project(coordinate: vehicle, onto: route))

        #expect(projection.distanceToRoute < 2)
        #expect(projection.progressDistance > 400)
        #expect(projection.progressDistance < 500)
        #expect(abs(projection.heading - 90) < 2)
    }

    @Test func routeProjection_이탈경계에서선분까지거리를반환한다() async throws {
        let route = [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.01)
        ]
        let vehicle = CLLocationCoordinate2D(latitude: 37.0011, longitude: 127.005)

        let projection = try #require(HoguNavigationRouteProjector.project(coordinate: vehicle, onto: route))

        #expect(projection.distanceToRoute > 120)
        #expect(projection.segmentIndex == 0)
    }

    @Test func maneuverResolver_좌우직진방향을geometry로분류한다() async throws {
        #expect(HoguNavigationManeuverResolver.maneuver(inboundHeading: 0, outboundHeading: 270) == .left)
        #expect(HoguNavigationManeuverResolver.maneuver(inboundHeading: 0, outboundHeading: 90) == .right)
        #expect(HoguNavigationManeuverResolver.maneuver(inboundHeading: 0, outboundHeading: 12) == .straight)
    }

    @Test func maneuverResolver_northWraparound과유턴을분류한다() async throws {
        #expect(HoguNavigationManeuverResolver.maneuver(inboundHeading: 350, outboundHeading: 80) == .right)
        #expect(HoguNavigationManeuverResolver.maneuver(inboundHeading: 10, outboundHeading: 280) == .left)
        #expect(HoguNavigationManeuverResolver.maneuver(inboundHeading: 0, outboundHeading: 180) == .uTurn)
    }

    @Test func maneuverResolver_geometry가원문우회전과충돌하면좌회전으로안전교정한다() async throws {
        let guidance = HoguNavigationManeuverResolver.guidance(
            instruction: "완만히 우회전하여 양화로로 진입",
            inboundHeading: 0,
            outboundHeading: 270
        )

        #expect(guidance.maneuver == .left)
        #expect(guidance.text.contains("좌회전"))
        #expect(!guidance.text.contains("우회전"))
        #expect(guidance.text.contains("양화로"))
    }

    @Test func maneuverResolver_영문원문에도geometry방향과아이콘SSOT를포함한다() async throws {
        let guidance = HoguNavigationManeuverResolver.guidance(
            instruction: "Continue onto Yanghwa-ro",
            inboundHeading: 0,
            outboundHeading: 90
        )

        #expect(guidance.maneuver == .right)
        #expect(guidance.text == "우회전")
        #expect(guidance.maneuver.iconName == "arrow.turn.up.right")
    }

    @Test func routeProjection_중복과5m미만좌표를건너뛰고선분진행거리를계산한다() async throws {
        let route = [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.00001, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.01)
        ]
        let projection = try #require(HoguNavigationRouteProjector.project(
            coordinate: CLLocationCoordinate2D(latitude: 37.0, longitude: 127.005),
            onto: route
        ))

        #expect(projection.segmentIndex == 2)
        #expect(projection.progressDistance > 400)
    }

    @Test func routeProjectionIndex_기존투영기와동일한결과를반환한다() async throws {
        let route = [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.01),
            CLLocationCoordinate2D(latitude: 37.01, longitude: 127.01)
        ]
        let location = CLLocation(latitude: 37.0008, longitude: 127.006)

        let baseline = try #require(HoguNavigationRouteProjector.project(coordinate: location.coordinate, onto: route))
        let cached = try #require(RouteProjectionIndex(coordinates: route).project(location))

        #expect(cached.segmentIndex == baseline.segmentIndex)
        #expect(abs(cached.segmentRatio - baseline.segmentRatio) < 0.000_001)
        #expect(abs(cached.progressDistance - baseline.progressDistance) < 0.01)
        #expect(abs(cached.distanceToRoute - baseline.distanceToRoute) < 0.01)
    }

    @Test func routeProjectionIndex_중복선분에서도기존투영기와동일하다() async throws {
        let route = [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.00001, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.01)
        ]
        let location = CLLocation(latitude: 37.0, longitude: 127.005)

        let baseline = try #require(HoguNavigationRouteProjector.project(coordinate: location.coordinate, onto: route))
        let cached = try #require(RouteProjectionIndex(coordinates: route).project(location))

        #expect(cached.segmentIndex == baseline.segmentIndex)
        #expect(abs(cached.progressDistance - baseline.progressDistance) < 0.01)
    }

    @Test func navigationFrame_한위치투영을지도와안내가재사용한다() async throws {
        let index = RouteProjectionIndex(coordinates: [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.01)
        ])
        let location = CLLocation(latitude: 37.0, longitude: 127.005)
        let projection = try #require(index.project(location))
        let frame = HoguNavigationFrame(location: location, projection: projection, displayHeading: projection.heading)

        #expect(index.projectionRequestCount == 1)
        #expect(frame.projection.coordinate.latitude == projection.coordinate.latitude)
        #expect(frame.projection.coordinate.longitude == projection.coordinate.longitude)
        #expect(frame.displayHeading == projection.heading)
    }

    @Test func routeProjectionIndex_재탐색은새경로인덱스로교체한다() async throws {
        let firstIndex = RouteProjectionIndex(coordinates: [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.01)
        ])
        _ = firstIndex.project(CLLocation(latitude: 37.0, longitude: 127.005))

        let reroutedIndex = RouteProjectionIndex(coordinates: [
            CLLocationCoordinate2D(latitude: 37.01, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.02, longitude: 127.0)
        ])
        let reroutedProjection = try #require(reroutedIndex.project(CLLocation(latitude: 37.015, longitude: 127.0)))

        #expect(firstIndex.projectionRequestCount == 1)
        #expect(reroutedIndex.projectionRequestCount == 1)
        #expect(reroutedProjection.segmentIndex == 0)
        #expect(reroutedProjection.distanceToRoute < 1)
    }

    @Test func speedCameraRouteIndexer_경로순서와160m필터를보장한다() async throws {
        let index = RouteProjectionIndex(coordinates: [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.02)
        ])
        let cameras = [
            testCamera(id: "later", latitude: 37.0, longitude: 127.015),
            testCamera(id: "offRoute", latitude: 37.003, longitude: 127.01),
            testCamera(id: "first", latitude: 37.0, longitude: 127.005)
        ]

        let projected = HoguNavigationSpeedCameraRouteIndexer.project(cameras: cameras, using: index)

        #expect(projected.map(\.camera.id) == ["first", "later"])
        #expect(projected.allSatisfy { $0.distanceToRoute <= 160 })
    }

    @Test func speedCameraCandidateSelector_뒤카메라제외와최대3개를보장한다() async throws {
        let cameras = (0..<5).map { offset in
            HoguNavigationProjectedSpeedCamera(
                camera: testCamera(id: "\(offset)", latitude: 37, longitude: 127),
                progressDistance: CLLocationDistance(offset * 100),
                distanceToRoute: 0
            )
        }

        let upcoming = HoguNavigationSpeedCameraCandidateSelector.upcoming(in: cameras, after: 150)

        #expect(upcoming.map(\.camera.id) == ["2", "3", "4"])
    }

    @Test func speedCameraPrecomputeGate_재탐색이전결과를차단한다() async throws {
        var gate = HoguNavigationSpeedCameraPrecomputeGate()
        let staleGeneration = gate.invalidate()
        let activeGeneration = gate.invalidate()

        #expect(!gate.accepts(staleGeneration))
        #expect(gate.accepts(activeGeneration))
    }

    @Test func thermalPolicy_단계별렌더예산을고정한다() async throws {
        #expect(HoguNavigationEnergyPolicy.policy(for: .nominal).cameraMinimumInterval == 0.5)
        #expect(HoguNavigationEnergyPolicy.policy(for: .serious).cameraMinimumInterval == 1)
        #expect(HoguNavigationEnergyPolicy.policy(for: .critical).cameraMinimumInterval == 2)
        #expect(HoguNavigationEnergyPolicy.policy(for: .critical).cameraPitch == 0)
        #expect(!HoguNavigationEnergyPolicy.policy(for: .serious).showsPointsOfInterest)
    }

    @Test func thermalStateController_저하는즉시적용하고복구는30초대기한다() async throws {
        var controller = HoguNavigationThermalStateController()
        let start = Date(timeIntervalSinceReferenceDate: 1_000)

        let degradedLevel = controller.receive(.serious, at: start)
        let pendingRecoveryLevel = controller.receive(.nominal, at: start.addingTimeInterval(1))
        let beforeDeadlineLevel = controller.advance(at: start.addingTimeInterval(30))
        let recoveredLevel = controller.advance(at: start.addingTimeInterval(31))

        #expect(degradedLevel == .serious)
        #expect(pendingRecoveryLevel == .serious)
        #expect(beforeDeadlineLevel == .serious)
        #expect(recoveredLevel == .nominal)
    }

    @Test func thermalRecoveryScheduler_동일후보반복은예약을중복하지않는다() async throws {
        var scheduler = HoguNavigationThermalRecoveryScheduler()
        let deadline = Date(timeIntervalSinceReferenceDate: 1_030)

        let scheduledGeneration = scheduler.schedule(candidate: .nominal, deadline: deadline)
        let generation = try #require(scheduledGeneration)
        let duplicateGeneration = scheduler.schedule(candidate: .nominal, deadline: deadline)

        #expect(duplicateGeneration == nil)
        #expect(scheduler.accepts(generation, candidate: .nominal, at: deadline))
    }

    @Test func thermalRecoveryScheduler_후보변경과재악화는기존예약을무효화한다() async throws {
        var scheduler = HoguNavigationThermalRecoveryScheduler()
        let deadline = Date(timeIntervalSinceReferenceDate: 1_030)
        let scheduledFairGeneration = scheduler.schedule(candidate: .fair, deadline: deadline)
        let fairGeneration = try #require(scheduledFairGeneration)
        let scheduledNominalGeneration = scheduler.schedule(
            candidate: .nominal,
            deadline: deadline.addingTimeInterval(2)
        )
        let nominalGeneration = try #require(scheduledNominalGeneration)

        #expect(!scheduler.accepts(fairGeneration, candidate: .fair, at: deadline.addingTimeInterval(3)))
        #expect(scheduler.accepts(nominalGeneration, candidate: .nominal, at: deadline.addingTimeInterval(3)))
        scheduler.cancel()
        #expect(!scheduler.accepts(nominalGeneration, candidate: .nominal, at: deadline.addingTimeInterval(3)))
    }

    @Test func renderBudget_camera와overlay경계를보장한다() async throws {
        var budget = HoguNavigationRenderBudget()
        let policy = HoguNavigationEnergyPolicy.policy(for: .nominal)
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let origin = CLLocationCoordinate2D(latitude: 37, longitude: 127)

        let initialCameraUpdate = budget.shouldUpdateCamera(
            coordinate: origin,
            heading: 0,
            policy: policy,
            now: start
        )
        let throttledCameraUpdate = budget.shouldUpdateCamera(
            coordinate: origin,
            heading: 0,
            policy: policy,
            now: start.addingTimeInterval(0.4)
        )
        let insufficientHeadingUpdate = budget.shouldUpdateCamera(
            coordinate: origin,
            heading: 2,
            policy: policy,
            now: start.addingTimeInterval(0.6)
        )
        let permittedHeadingUpdate = budget.shouldUpdateCamera(
            coordinate: origin,
            heading: 3,
            policy: policy,
            now: start.addingTimeInterval(1.2)
        )
        let initialOverlayUpdate = budget.shouldUpdateOverlay(
            progressDistance: 0,
            policy: policy,
            now: start
        )
        budget.recordOverlay(progressDistance: 0, at: start)
        let throttledOverlayUpdate = budget.shouldUpdateOverlay(
            progressDistance: 10,
            policy: policy,
            now: start.addingTimeInterval(0.5)
        )
        let permittedOverlayUpdate = budget.shouldUpdateOverlay(
            progressDistance: 10,
            policy: policy,
            now: start.addingTimeInterval(1)
        )

        #expect(initialCameraUpdate)
        #expect(!throttledCameraUpdate)
        #expect(!insufficientHeadingUpdate)
        #expect(permittedHeadingUpdate)
        #expect(initialOverlayUpdate)
        #expect(!throttledOverlayUpdate)
        #expect(permittedOverlayUpdate)
    }

    @Test func routeSampleSelector_대표좌표를3개로제한한다() async throws {
        let coordinates = (0..<9).map { CLLocationCoordinate2D(latitude: 37, longitude: 127 + Double($0) * 0.001) }
        let samples = HoguNavigationRouteSampleSelector.representativeCoordinates(from: coordinates, maximumCount: 3)

        #expect(samples.count == 3)
        #expect(samples[0].longitude == coordinates[0].longitude)
        #expect(samples[1].longitude == coordinates[4].longitude)
        #expect(samples[2].longitude == coordinates[8].longitude)
    }

    @Test func routeSampleSelector_25m이내중복좌표를제거한다() async throws {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37, longitude: 127),
            CLLocationCoordinate2D(latitude: 37, longitude: 127.00001),
            CLLocationCoordinate2D(latitude: 37, longitude: 127.00002)
        ]
        let samples = HoguNavigationRouteSampleSelector.representativeCoordinates(from: coordinates, maximumCount: 3)

        #expect(samples.count == 1)
    }

    @Test func routeSampleSelector_빈입력과0이하제한은빈결과를반환한다() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37, longitude: 127)

        let emptyInput = HoguNavigationRouteSampleSelector.representativeCoordinates(from: [], maximumCount: 3)
        let zeroLimit = HoguNavigationRouteSampleSelector.representativeCoordinates(
            from: [coordinate],
            maximumCount: 0
        )
        let negativeLimit = HoguNavigationRouteSampleSelector.representativeCoordinates(
            from: [coordinate],
            maximumCount: -1
        )

        #expect(emptyInput.isEmpty)
        #expect(zeroLimit.isEmpty)
        #expect(negativeLimit.isEmpty)
    }

    @Test func routeSampleSelector_1개제한은첫좌표를유지한다() async throws {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37, longitude: 127),
            CLLocationCoordinate2D(latitude: 38, longitude: 128)
        ]

        let samples = HoguNavigationRouteSampleSelector.representativeCoordinates(from: coordinates, maximumCount: 1)

        #expect(samples.count == 1)
        #expect(samples[0].latitude == coordinates[0].latitude)
        #expect(samples[0].longitude == coordinates[0].longitude)
    }

    @Test func optimizationFlags_저장값이없으면안전하게활성화한다() async throws {
        let defaults = UserDefaults(suiteName: "HoguNavigationOptimizationFlagsTests")!
        defaults.removePersistentDomain(forName: "HoguNavigationOptimizationFlagsTests")
        let flags = HoguNavigationOptimizationFlags(userDefaults: defaults)

        #expect(HoguNavigationOptimizationFlag.allCases.allSatisfy { flags[$0] })
    }

    @Test func speedCameraRetryPolicy_실패backoff은증가하고상한을갖는다() async throws {
        #expect(SpeedCameraRegionRetryPolicy.cooldown(forFailureCount: 1) == 10)
        #expect(SpeedCameraRegionRetryPolicy.cooldown(forFailureCount: 2) == 20)
        #expect(SpeedCameraRegionRetryPolicy.cooldown(forFailureCount: 20) == 300)
    }

    @Test func speedCameraClient_동일지역동시성공요청은한번만가져온다() async throws {
        let clock = SpeedCameraTestClock(now: Date(timeIntervalSinceReferenceDate: 1_000))
        let probe = SpeedCameraBlockingFetchProbe()
        let expected = testCamera(id: "shared", latitude: 37, longitude: 127)
        let client = SpeedCameraAPIClient(
            nowProvider: { clock.now },
            regionFetchOverride: { region in await probe.fetch(region) }
        )
        let region = SpeedCameraRegionFilter(sido: "서울", sigungu: "마포")
        let tasks = (0..<6).map { _ in
            Task { await client.fetchCameras(regions: [region]) }
        }

        await probe.waitForFirstRequest()
        await probe.resolve(.success([expected]))

        for task in tasks {
            #expect(await task.value == [expected])
        }
        #expect(await probe.calls(for: region) == 1)
    }

    @Test func speedCameraClient_동일지역동시실패는backoff소유자를하나로유지한다() async throws {
        let clock = SpeedCameraTestClock(now: Date(timeIntervalSinceReferenceDate: 1_000))
        let probe = SpeedCameraImmediateFetchProbe(result: .failure(URLError(.cannotDecodeContentData)))
        let client = SpeedCameraAPIClient(
            nowProvider: { clock.now },
            regionFetchOverride: { region in await probe.fetch(region) }
        )
        let region = SpeedCameraRegionFilter(sido: "서울", sigungu: "마포")
        let tasks = (0..<5).map { _ in
            Task { await client.fetchCameras(regions: [region]) }
        }

        for task in tasks {
            #expect(await task.value.isEmpty)
        }
        #expect(await probe.calls(for: region) == 1)
        #expect(await client.hasPendingRetry(regions: [region]))
        _ = await client.fetchCameras(regions: [region])
        #expect(await probe.calls(for: region) == 1)
        clock.advance(by: 11)
        _ = await client.fetchCameras(regions: [region])
        #expect(await probe.calls(for: region) == 2)
    }

    @Test func speedCameraClient_대기호출취소가공유요청을취소하지않는다() async throws {
        let clock = SpeedCameraTestClock(now: Date(timeIntervalSinceReferenceDate: 1_000))
        let probe = SpeedCameraBlockingFetchProbe()
        let expected = testCamera(id: "survives-cancel", latitude: 37, longitude: 127)
        let client = SpeedCameraAPIClient(
            nowProvider: { clock.now },
            regionFetchOverride: { region in await probe.fetch(region) }
        )
        let region = SpeedCameraRegionFilter(sido: "서울", sigungu: "마포")
        let cancelledWaiter = Task { await client.fetchCameras(regions: [region]) }

        await probe.waitForFirstRequest()
        cancelledWaiter.cancel()
        let activeWaiter = Task { await client.fetchCameras(regions: [region]) }
        await probe.resolve(.success([expected]))

        #expect(await activeWaiter.value == [expected])
        _ = await cancelledWaiter.value
        #expect(await probe.calls(for: region) == 1)
    }

    @Test func speedCameraClient_성공TTL과정상emptyTTL을구분한다() async throws {
        let successClock = SpeedCameraTestClock(now: Date(timeIntervalSinceReferenceDate: 1_000))
        let successProbe = SpeedCameraImmediateFetchProbe(result: .success([testCamera(id: "ttl", latitude: 37, longitude: 127)]))
        let successClient = SpeedCameraAPIClient(
            nowProvider: { successClock.now },
            regionFetchOverride: { region in await successProbe.fetch(region) }
        )
        let region = SpeedCameraRegionFilter(sido: "서울", sigungu: "마포")

        _ = await successClient.fetchCameras(regions: [region])
        _ = await successClient.fetchCameras(regions: [region])
        #expect(await successProbe.calls(for: region) == 1)
        successClock.advance(by: 601)
        _ = await successClient.fetchCameras(regions: [region])
        #expect(await successProbe.calls(for: region) == 2)

        let emptyClock = SpeedCameraTestClock(now: Date(timeIntervalSinceReferenceDate: 2_000))
        let emptyProbe = SpeedCameraImmediateFetchProbe(result: .success([]))
        let emptyClient = SpeedCameraAPIClient(
            nowProvider: { emptyClock.now },
            regionFetchOverride: { region in await emptyProbe.fetch(region) }
        )
        _ = await emptyClient.fetchCameras(regions: [region])
        emptyClock.advance(by: 59)
        _ = await emptyClient.fetchCameras(regions: [region])
        #expect(await emptyProbe.calls(for: region) == 1)
        emptyClock.advance(by: 2)
        _ = await emptyClient.fetchCameras(regions: [region])
        #expect(await emptyProbe.calls(for: region) == 2)
    }

    @Test func speedCameraClient_실패는캐시하지않고실패지역만재시도한다() async throws {
        let clock = SpeedCameraTestClock(now: Date(timeIntervalSinceReferenceDate: 3_000))
        let success = testCamera(id: "good", latitude: 37, longitude: 127)
        let probe = SpeedCameraRegionScriptProbe(successCamera: success)
        let client = SpeedCameraAPIClient(
            nowProvider: { clock.now },
            regionFetchOverride: { region in await probe.fetch(region) }
        )
        let good = SpeedCameraRegionFilter(sido: "서울", sigungu: "마포")
        let failed = SpeedCameraRegionFilter(sido: "경기", sigungu: "고양")

        #expect(await client.fetchCameras(regions: [good, failed]) == [success])
        #expect(await probe.calls(for: good) == 1)
        #expect(await probe.calls(for: failed) == 1)
        #expect(await client.hasPendingRetry(regions: [failed]))
        clock.advance(by: 11)

        #expect(await client.fetchCameras(regions: [good, failed]) == [success])
        #expect(await probe.calls(for: good) == 1)
        #expect(await probe.calls(for: failed) == 2)
    }

    @Test func speedCameraRegionTransition_다른지역진입은warning식별자후보를즉시초기화한다() async throws {
        let current = Set(["서울|마포"])
        #expect(!HoguNavigationSpeedCameraRegionTransition.requiresImmediateClear(
            currentRegionKeys: current,
            nextRegionKeys: current
        ))
        #expect(HoguNavigationSpeedCameraRegionTransition.requiresImmediateClear(
            currentRegionKeys: current,
            nextRegionKeys: Set(["경기|고양"])
        ))
    }

    private func testCamera(id: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> SpeedCamera {
        SpeedCamera(
            id: id,
            name: id,
            cameraType: "고정식",
            limitKmh: 50,
            sido: nil,
            sigungu: nil,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }

    @Test func stepBoundaryResolver_이전마지막과현재첫유효선분만사용한다() async throws {
        let previous = [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 126.999),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0)
        ]
        let current = [
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.00001, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.0, longitude: 127.001),
            CLLocationCoordinate2D(latitude: 37.001, longitude: 127.001)
        ]

        #expect(HoguNavigationStepBoundaryResolver.maneuver(
            previousStepCoordinates: previous,
            currentStepCoordinates: current
        ) == .straight)
    }

    @Test func guidanceSelector_lookAhead경계와동일step정렬을보장한다() async throws {
        let first = HoguNavigationRouteStep(
            instruction: "좌회전 양화로",
            startDistance: 100,
            distance: 40,
            maneuver: .left
        )
        let second = HoguNavigationRouteStep(
            instruction: "우회전 합정로",
            startDistance: 160,
            distance: 30,
            maneuver: .right
        )

        let beforeBoundary = HoguNavigationGuidanceSelector.nextStep(
            in: [first, second],
            progressDistance: 74
        )
        let atBoundary = HoguNavigationGuidanceSelector.nextStep(
            in: [first, second],
            progressDistance: 75
        )

        #expect(beforeBoundary?.instruction == "좌회전 양화로")
        #expect(beforeBoundary?.maneuver == .left)
        #expect(beforeBoundary.map { $0.startDistance - 74 } == 26)
        #expect(atBoundary?.instruction == "우회전 합정로")
        #expect(atBoundary?.maneuver == .right)
        #expect(atBoundary.map { $0.startDistance - 75 } == 85)
    }

    @Test func locationSessionGate_구독준비후시작세션을발급한다() async throws {
        var gate = HoguNavigationLocationSessionGate()
        let generation = gate.start()
        #expect(generation == 1)
        #expect(!gate.acceptsOneShot(capturedGeneration: generation, isNavigationStarted: true))
    }

    @Test func locationSessionGate_delayedOneShot은새주행세션에서차단한다() async throws {
        var gate = HoguNavigationLocationSessionGate()
        let staleGeneration = gate.start()
        gate.stop()
        _ = gate.start()
        #expect(!gate.acceptsOneShot(capturedGeneration: staleGeneration, isNavigationStarted: false))
    }

    @Test func locationSessionGate_stop은구독과동일세대콜백을무효화한다() async throws {
        var gate = HoguNavigationLocationSessionGate()
        let generation = gate.start()
        gate.stop()
        #expect(!gate.acceptsOneShot(capturedGeneration: generation, isNavigationStarted: false))
    }

    @Test func sharedLocationSubscription_start직후첫이벤트를전달한다() async throws {
        let subject = PassthroughSubject<CLLocation, Never>()
        let queue = DispatchQueue(label: "navigation.subscription.immediate")
        var received = 0
        let subscription = HoguNavigationSharedLocationSubscription(publisher: subject.eraseToAnyPublisher(), deliveryQueue: queue) { _ in received += 1 }
        subscription.start()
        subject.send(CLLocation(latitude: 37, longitude: 127))
        queue.sync { }
        #expect(received == 1)
    }

    @Test func sharedLocationSubscription_stop후이벤트를전달하지않는다() async throws {
        let subject = PassthroughSubject<CLLocation, Never>()
        let queue = DispatchQueue(label: "navigation.subscription.stop")
        var received = 0
        let subscription = HoguNavigationSharedLocationSubscription(publisher: subject.eraseToAnyPublisher(), deliveryQueue: queue) { _ in received += 1 }
        subscription.start(); subscription.stop()
        subject.send(CLLocation(latitude: 37, longitude: 127))
        queue.sync { }
        #expect(received == 0)
    }

    @Test func sharedLocationSubscription_restart는중복구독없이한번만전달한다() async throws {
        let subject = PassthroughSubject<CLLocation, Never>()
        let queue = DispatchQueue(label: "navigation.subscription.restart")
        var received = 0
        let subscription = HoguNavigationSharedLocationSubscription(publisher: subject.eraseToAnyPublisher(), deliveryQueue: queue) { _ in received += 1 }
        subscription.start(); subscription.stop(); subscription.start(); subscription.start()
        subject.send(CLLocation(latitude: 37, longitude: 127))
        queue.sync { }
        #expect(received == 1)
    }

    @Test func sharedLocationSubscription_대기중인구세션콜백을차단한다() async throws {
        let subject = PassthroughSubject<CLLocation, Never>()
        let queue = DispatchQueue(label: "navigation.subscription.test")
        queue.suspend()
        var received = 0
        let subscription = HoguNavigationSharedLocationSubscription(
            publisher: subject.eraseToAnyPublisher(),
            deliveryQueue: queue
        ) { _ in received += 1 }
        subscription.start()
        subject.send(CLLocation(latitude: 37, longitude: 127))
        subscription.stop(); subscription.start()
        subject.send(CLLocation(latitude: 37.1, longitude: 127.1))
        queue.resume()
        queue.sync { }
        #expect(received == 1)
    }

}

private final class SpeedCameraTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Date

    init(now: Date) {
        value = now
    }

    var now: Date {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func advance(by interval: TimeInterval) {
        lock.lock()
        value = value.addingTimeInterval(interval)
        lock.unlock()
    }
}

private actor SpeedCameraBlockingFetchProbe {
    private var requests: [String: Int] = [:]
    private var continuations: [CheckedContinuation<Result<[SpeedCamera], Error>, Never>] = []
    private var firstRequestWaiters: [CheckedContinuation<Void, Never>] = []

    func fetch(_ region: SpeedCameraRegionFilter) async -> Result<[SpeedCamera], Error> {
        requests[region.cacheKey, default: 0] += 1
        let waiters = firstRequestWaiters
        firstRequestWaiters.removeAll()
        waiters.forEach { $0.resume() }
        return await withCheckedContinuation { continuations.append($0) }
    }

    func waitForFirstRequest() async {
        guard requests.values.reduce(0, +) == 0 else { return }
        await withCheckedContinuation { firstRequestWaiters.append($0) }
    }

    func resolve(_ result: Result<[SpeedCamera], Error>) {
        let pending = continuations
        continuations.removeAll()
        pending.forEach { $0.resume(returning: result) }
    }

    func calls(for region: SpeedCameraRegionFilter) -> Int {
        requests[region.cacheKey, default: 0]
    }
}

private actor SpeedCameraImmediateFetchProbe {
    private let result: Result<[SpeedCamera], Error>
    private var requests: [String: Int] = [:]

    init(result: Result<[SpeedCamera], Error>) {
        self.result = result
    }

    func fetch(_ region: SpeedCameraRegionFilter) -> Result<[SpeedCamera], Error> {
        requests[region.cacheKey, default: 0] += 1
        return result
    }

    func calls(for region: SpeedCameraRegionFilter) -> Int {
        requests[region.cacheKey, default: 0]
    }
}

private actor SpeedCameraRegionScriptProbe {
    private let successCamera: SpeedCamera
    private var requests: [String: Int] = [:]

    init(successCamera: SpeedCamera) {
        self.successCamera = successCamera
    }

    func fetch(_ region: SpeedCameraRegionFilter) -> Result<[SpeedCamera], Error> {
        requests[region.cacheKey, default: 0] += 1
        if region.sido == "경기" {
            return .failure(URLError(.cannotDecodeContentData))
        }
        return .success([successCamera])
    }

    func calls(for region: SpeedCameraRegionFilter) -> Int {
        requests[region.cacheKey, default: 0]
    }
}
