import Foundation

/// A running timer that gems can skip. Incubation today; breeding adds a case later.
enum TimerRef: Equatable {
    case egg(Int)
}

/// Generic timer queries and the gem speed-up. Cost = ceil(seconds left / secondsPerGem),
/// at least `minimumSkipCost` (economy.json `gems`).
extension GameState {
    enum SpeedUpResult {
        case ok
        case notEnoughGems
        case finished
    }

    func timerEnd(_ t: TimerRef) -> Date? {
        switch t {
        case .egg(let id):
            return egg(id)?.readyAt
        }
    }

    func remaining(_ t: TimerRef, now: Date) -> TimeInterval {
        guard let end = timerEnd(t) else { return 0 }
        return max(0, end.timeIntervalSince(now))
    }

    func skipCost(seconds: TimeInterval) -> Int {
        guard seconds > 0 else { return 0 }
        let gems = Int((seconds / catalog.secondsPerGem).rounded(.up))
        return max(catalog.minimumSkipCost, gems)
    }

    func skipCost(_ t: TimerRef, now: Date) -> Int {
        skipCost(seconds: remaining(t, now: now))
    }

    /// Spends gems and completes the timer now.
    func speedUp(_ t: TimerRef, now: Date) -> SpeedUpResult {
        let left = remaining(t, now: now)
        guard left > 0 else { return .finished }
        guard spendGems(skipCost(seconds: left)) else { return .notEnoughGems }
        switch t {
        case .egg(let id):
            if let i = data.eggs.firstIndex(where: { $0.id == id }) { data.eggs[i].readyAt = now }
        }
        return .ok
    }

    /// Soonest unfinished incubation, for the nursery's speed-up button.
    func nextIncubatingEgg(now: Date) -> TimerRef? {
        data.eggs.filter { $0.readyAt > now }.min(by: { $0.readyAt < $1.readyAt }).map { TimerRef.egg($0.id) }
    }
}
