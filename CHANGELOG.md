## 1.0.3

* Add `Streak.clear()` to stop listening and drop the streak on sign-out
* Add `StreakDelegate.today()`: days are counted on the delegate clock (such as the server), the phone by default
* `StreakData.time` is kept as a UTC date, so days compare the same in any time zone; add `isTodayOn` and `isAliveOn`

## 1.0.2

* Fix: a contributable streak now resets after a missed day
* Fix: errors from the delegate stream no longer go unhandled
* Fix: calling init again stops the old listener

## 1.0.1

* Add reset function to reset the streak data

## 1.0.0

* Initial release of **flutter_streak**
* Added `Streak` class to track daily streaks.
* Added `StreakData` model for storing streak count, date, contributors, and history.
* Added `StreakDelegate` abstract class for custom persistence (local, database, or cloud).
* Supports single-user and multi-contributor streak tracking.
* Provides methods for initializing, listening, loading, and updating streaks.
