# flutter_streak

Daily streaks for Flutter, alone or in a team, kept wherever you choose through a `StreakDelegate`.

## Features

- A day counts once it is completed; a missed day starts the streak again from 0.
- The longest streak (`best`) and the last broken one (`last`), which `restore()` brings back however long ago it broke.
- Restored days are kept apart (`restored`, the ignore list); counted days in `history`, for a calendar.
- Two modes: `single`, and `team`, where a day counts only once every member completes it. Each team day keeps who
  was in the team, who completed it (`done`, for progress) and who was active.
- `Streak.i.value` at once from anywhere, and `Streak.i.on((latest) {})` for changes.
- `canRestore` on the delegate, to charge for a restore.
- Reads 1.x streaks (`count`, `time`, `history`).

## How it works

Every read settles the streak first: a streak whose last counted day is before yesterday has broken.

```mermaid
flowchart TD
    A[Streak read] --> B{Last counted day<br/>before yesterday?}
    B -- No --> C[As it is]
    B -- Yes --> D[count = 0<br/>last = old count<br/>lastDay = old day]
```

### Single mode

```mermaid
flowchart TD
    A["update()"] --> B[Settle]
    B --> C{Today already counted?}
    C -- Yes --> N[Nothing written]
    C -- No --> D{Yesterday counted?}
    D -- Yes --> E[count + 1]
    D -- No --> F[count = 1]
    E --> G[Today into history<br/>best = max<br/>saved]
    F --> G
```

### Team mode

```mermaid
flowchart TD
    A["Member X: update()"] --> B[Settle]
    B --> C{X done today?}
    C -- Yes --> N[Nothing written]
    C -- No --> D["days[today]: members = team<br/>done += X, active += X"]
    D --> E{Every member done?}
    E -- No --> S["Only days[today] saved<br/>count unchanged"]
    E -- Yes --> F{Yesterday counted?}
    F -- Yes --> G[count + 1]
    F -- No --> H[count = 1]
    G --> I[Today into history<br/>best = max<br/>saved]
    H --> I
    Y["Member Y: active()"] --> Z["days[today].active += Y<br/>(not done)"]
```

### Restore

```mermaid
flowchart TD
    A["restore()"] --> B{last > 0?}
    B -- No --> U[unavailable]
    B -- Yes --> C{"delegate.canRestore()<br/>(such as paid)"}
    C -- No --> D[declined]
    C -- Yes --> E[Missed days = lastDay + 1<br/>to the day before the current streak<br/>or yesterday when there is none]
    E --> F[restored += missed days<br/>count = last + count<br/>last = 0]
    F --> R[restored]
```

## Use cases

```mermaid
flowchart LR
    subgraph Single["Single: a habit app"]
        S1[Opens the app<br/>each day] --> S2["update()"] --> S3[Streak count<br/>on the home screen]
    end
    subgraph Team["Team: a couple or a group"]
        T1[Each member<br/>does their part] --> T2["update() each"] --> T3[Day counts when<br/>all are done]
        T4[Member opens<br/>but doesn't finish] --> T5["active()"]
    end
    subgraph Restore["Restore a broken streak"]
        R1[Missed days] --> R2[last kept] --> R3["canRestore()<br/>points or payment"] --> R4["restore()"]
    end
    subgraph Calendar["Calendar and history"]
        C1[history: completed days]
        C2[restored: the ignore list]
        C3["days[day]: done / members<br/>as progress"]
        C4["days[day].active<br/>in a popup"]
    end
```

Example: completed on the 1st and the 2nd, missed the 3rd, completed the 4th: `count` 1, `last` 2. A restore puts the
3rd in `restored`, and `count` is 3.

## Usage

```dart
Streak.i.init(delegate: MyDelegate(), member: uid);                      // single
Streak.i.init(delegate: MyDelegate(), member: uid, mode: StreakMode.team, members: {uid, partnerId});

await Streak.i.update();   // this member completed today
await Streak.i.active();   // team: active today without completing
await Streak.i.restore();  // the last streak back
Streak.i.refresh();        // a day may have passed (back from the background)
Streak.i.clear();          // signed out

final stop = Streak.i.on((latest) => print(latest.count));
```

A delegate keeps the streak and says what day it is:

```dart
class MyDelegate extends StreakDelegate {
  @override
  Stream<Map<String, dynamic>?> listen() => ...;

  /// Atomically, such as in a transaction; `change` may run more than once.
  @override
  Future<Map<String, dynamic>?> write(Map<String, dynamic>? Function(Map<String, dynamic>? stored) change) => ...;

  @override
  Map<String, dynamic>? cached() => ...;   // optional: shown at once

  @override
  DateTime now() => ...;                   // optional: the server's day

  @override
  Future<bool> canRestore(StreakData data) async => ...; // optional: once paid
}
```

See `example/` for an in-memory delegate.
