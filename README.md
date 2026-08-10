# Stability Tracker (Apple Watch + iPhone)

Records wrist stability during sim racing on Apple Watch, then charts it on iPhone.

## How it works

```
┌─────────────────────┐   transferFile (JSON)   ┌──────────────────────┐
│   watchOS App        │ ───────────────────────▶ │   iOS App             │
│  CMMotionManager      │                          │  WCSessionDelegate    │
│  → MotionSample[]      │                          │  → RecordingSession[]  │
│  → RecordingSession    │                          │  → Swift Charts line   │
└─────────────────────┘                          └──────────────────────┘
```

- **Watch**: `CMMotionManager.startDeviceMotionUpdates` samples at 50 Hz and
  records wrist **attitude** (roll/pitch/yaw), **rotation rate**, and
  **user acceleration** into an array. Tap Stop and the whole session is
  packaged into a `RecordingSession` and sent to the phone via
  `WCSession.transferFile`. This works even if the phone isn't nearby —
  delivery happens in the background once it's reachable.
- **iPhone**: `WCSessionDelegate` receives the file, decodes it, and stores
  it to disk. `StabilityChartView` plots elapsed time (X) against your
  choice of roll/pitch/yaw in degrees (Y) using Swift Charts, plus a
  standard-deviation "stability score" (lower = steadier).

### Why attitude angle, not raw position

The Watch has no sensor for absolute position — no GPS-equivalent for a
wrist. Two options exist for "hand position":

1. **Attitude (roll/pitch/yaw)** — what's implemented. As your hand turns
   the wheel, the watch rotates with it, so roll tracks wheel angle nicely
   and is stable over a whole session (no drift).
2. **Double-integrated acceleration** — mathematically gives a position in
   meters, but drifts badly within seconds without an external reference,
   so it's unreliable for anything longer than a couple of seconds.

If you want a literal displacement number instead of an angle, that's
doable but would need frequent drift-correction (e.g. resetting integration
whenever acceleration is near zero) — happy to add that as an alternate mode.

## Setting this up in Xcode

1. **File → New → Project → watchOS → App.** Name it `StabilityTracker`,
   make sure **"Include Companion App"** is checked (or on newer Xcode:
   create an iOS App first, then **File → New → Target → watchOS →
   Watch App**, check "Include Companion App"). This gives you two targets
   in one project.
2. Delete the placeholder `ContentView.swift` in each target.
3. Add the files from this bundle:
   - `Shared/MotionSample.swift` → add to **both** targets (check both boxes
     in the "Target Membership" panel on the right in Xcode).
   - `WatchApp/*.swift` → Watch App target only.
   - `iOSApp/*.swift` → iOS App target only.
4. In **both** targets' Info settings, add key `NSMotionUsageDescription`
   with a string like "Used to record hand stability while sim racing."
   (Apple recommends this for any Core Motion usage even though device
   motion itself doesn't always prompt.)
5. **Watch App target only** — required for sampling to survive the wrist
   going still / screen dimming during a recording:
   - Select the Watch App target → **Signing & Capabilities** → **+ Capability** → add **HealthKit**.
   - Same tab → **+ Capability** → add **Background Modes** → check **Workout Processing**.
   - In the Watch App target's Info settings, add:
     - `NSHealthShareUsageDescription` — e.g. "Used to keep tracking hand stability while your wrist is still."
     - `NSHealthUpdateUsageDescription` — same idea; the app doesn't actually save anything to Health, but both keys are required by HealthKit's authorization API.
6. Build the Watch App target to a paired simulator or a real Watch, and the
   iOS App target to the paired phone/simulator. Record a session on the
   Watch, hit Stop, then open the iPhone app — the session should appear
   within a few seconds (instant if both are reachable, otherwise once
   they reconnect).

**Note:** CoreMotion's device-motion data only comes from the real sensors —
the Watch Simulator won't produce meaningful readings. You'll want to test
on a physical Apple Watch for real data (the UI/navigation can still be
sanity-checked in Simulator).

## Why the watch shows a workout-style indicator while recording

Once you rebuild with the background-execution fix, you'll notice a small
green indicator (and possibly a "workout in progress" style presence) on the
watch face while a session is running. That's expected — it's the same
mechanism running apps use to survive the wrist going down, and it's what
keeps CoreMotion delivering samples through the whole session instead of
stalling once the screen dims. Nothing is written to your Health app; the
workout session is discarded (not saved) when you hit Stop.

## Extending this

Good next steps, roughly in order of value for sim racing use:

- **Live threshold alert**: buzz the Watch (`WKInterfaceDevice.current().play(.notification)`)
  if rotation rate exceeds a jitter threshold, for real-time feedback.
- **CSV export** on the iPhone (`RecordingSession` → CSV string) so sessions
  can be analyzed in Excel/Python.
- **Multiple-session overlay**: chart two sessions on the same axes to
  compare before/after fatigue, or different rigs/wheels.
- **HealthKit heart rate correlation**: pull heart rate for the same time
  window to see if stress correlates with instability.
- **Watch complications**: show elapsed time or a live stability score
  on the watch face during a session.
- **Background delivery tuning**: if you want near-real-time charting
  instead of end-of-session, switch `transferFile` to periodic
  `sendMessage` batches (e.g. every 5s) — more chatty but lower latency.
