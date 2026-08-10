//
//  WorkoutSession.swift
//  StableSteer
//
//  Created by Satria Adi Firmansyah on 10/08/26.
//

import Foundation
import HealthKit
import Combine

/// Wraps an HKWorkoutSession purely to gain uninterrupted background
/// execution — the app (and CoreMotion delivery) keeps running even with
/// the wrist down or the screen off.
///
/// This is Apple's sanctioned mechanism for continuous background sensor
/// access on watchOS. WKExtendedRuntimeSession looks tempting for the same
/// problem, but Apple restricts it to four specific use cases (self-care,
/// mindfulness, physical therapy, smart alarms) — using it for arbitrary
/// sensor recording risks App Store rejection. A workout session, even one
/// we never save to Health, is the correct tool for "keep tracking motion
/// while the wrist is down."

final class WorkoutSessionManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var isAuthorized = false
    @Published var authorizationError: String?

    /// Call once, early (e.g. on app launch), so the permission prompt is
    /// out of the way before the person taps Start.
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "Health data isn't available on this device."
            completion(false)
            return
        }
        let typesToShare: Set = [HKObjectType.workoutType()]
        healthStore.requestAuthorization(toShare: typesToShare, read: []) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                self?.authorizationError = error?.localizedDescription
                completion(success)
            }
        }
    }

    /// Starts a workout session. We're not interested in workout metrics —
    /// this is only to keep the process (and CoreMotion) alive in the
    /// background for the duration of a recording.
    func start() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            session.delegate = self
            builder.delegate = self

            self.session = session
            self.builder = builder

            let now = Date()
            session.startActivity(with: now)
            builder.beginCollection(withStart: now) { _, _ in }
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }

    /// Ends the session and discards it — we never write anything to Health.
    func end() {
        guard let session, let builder else { return }
        let now = Date()
        session.end()
        builder.endCollection(withEnd: now) { [weak self] _, _ in
            self?.builder?.discardWorkout()
            self?.session = nil
            self?.builder = nil
        }
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {}
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
