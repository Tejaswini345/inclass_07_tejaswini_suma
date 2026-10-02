# Digital Pet (In-Class Activity 07)

Flutter pet-care app: actions and time change visible state (mood tint, meters, speech).
Repository: https://github.com/Tejaswini345/inclass_07_tejaswini_suma

## Team

| Member | GitHub | Team | Pathway (UG/Grad) | Role |
|---|---|---|---|---|---|
| Tejaswini | Tejaswini345 | Team 2 · Pet Personality | Graduate | UI owner, release owner, quality reviewer |
| Suma | EnjamSuma | Team 1 · Care Systems | Graduate | State owner (rules, timers, tests) | 

### Issues and pull requests

| Item | Link |
|---|---|
| Issue: Care loop, rules and timers (Suma) | https://github.com/Tejaswini345/inclass_07_tejaswini_suma/issues/3 |
| Issue: Pet UI, mood tint and animations (Tejaswini) | https://github.com/Tejaswini345/inclass_07_tejaswini_suma/issues/1 |
| Issue: README and test evidence | https://github.com/Tejaswini345/inclass_07_tejaswini_suma/issues/2 |
| PR #4: PetController rules, timers, unit tests (Suma), reviewed by Tejaswini | https://github.com/Tejaswini345/inclass_07_tejaswini_suma/pull/4 |
| PR: Pet UI, mood tint, animations, widget tests (Tejaswini), reviewed by Suma | https://github.com/Tejaswini345/inclass_07_tejaswini_suma/pull/5 |
| Graduate review of a teammate's PR (Tejaswini on PR #4; changes requested, then approved) | https://github.com/Tejaswini345/inclass_07_tejaswini_suma/pull/4 |

## Setup, run, test, build

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

## Rules we chose (documented balance)

| Action | Effect |
|---|---|
| Feed | Hunger -10; if resulting hunger < 30, Happiness -20, else +10 |
| Play | Happiness +15, Hunger +5, Energy -15; refused if Energy < 10 ("Too tired") |
| Rest | Energy +25, Hunger +5 |
| Time | Hunger +5 every 30 s; a tick that would exceed 100 clamps to 100 and Happiness -20 |
| Win | Happiness strictly > 80 continuously for 3 min; timer cancelled at <= 80 |
| Loss | Hunger 100 and Happiness <= 10; actions disabled until Reset |
| Pause | Stops both timers; win progress is lost (must be > 80 for a fresh 3 min) |
| Reset | Restores meters and outcome flags, keeps the pet's name, leaves exactly one hunger timer |
| Meters | Always clamped to 0-100 |

## Advanced features → learning outcomes → evidence

| Feature | Learning outcome | Evidence |
|---|---|---|
| Energy system | Related meters updated atomically with clamping | Test "play at energy 5 is refused and explained"; [screenshot](docs/play-too-tired.png) |
| Visual polish & accessible motion (bounce, living meters, expression switch, mood tint + size, speech, reduced motion) | UI derived from one state; lifecycle-safe delayed callbacks | Mood tint and size checked at 29/30/70/71 (screenshot for 29 in `docs/`); reduced motion checked on and off (see manual test table) |
| Session controls (pause/resume) | Timer lifecycle and safe outcome handling | Test "pause stops hunger and the win timer; resume restarts"; [paused](docs/paused-before.png), [resumed](docs/resumed.png) |

## Manual test results (Pixel 7 emulator, API 35)

Fill each row with the values you actually observed.

| Scenario | Before → After | Result |
|---|---|---|
| Feed at hunger 5 (happiness started at 50) | hunger 5 → 0 (clamped at 0); happiness 50 → 30 (resulting hunger < 30, so -20) | Pass |
| Feed at hunger 95 (happiness started at 50) | hunger 95 → 85; happiness 50 → 60 (+10) | Pass |
| Play at happiness 95 | happiness 95 → 100 (clamped, not 110); hunger +5; energy -15 | Pass |
| Play at energy 5 | energy 0 → refused, message "Too tired! Let Fluffy rest first." ([screenshot](docs/play-too-tired.png)) | Pass |
| Happiness 29 / 30 / 70 / 71 | red+Unhappy / yellow+Okay / yellow+Okay / green+Happy ([29 screenshot](docs/happiness-29-unhappy.png); 30, 70 and 71 checked manually) | Pass |
| Win timer cancelled at 80 | happiness above 80, then lowered to exactly 80 before 3:00: no win, pending win timer cancelled; a fresh 3:00 starts on the next crossing above 80 | Pass |
| Win after 3:00 | Happiness stayed above 80; win banner shown, buttons disabled, hunger stopped at 65 ([screenshot](docs/win.png)) | Pass |
| Hunger 95 → 100 → overflow tick | first tick: hunger 95 → 100, happiness unchanged; next tick: hunger stays 100, happiness -20 ("Starving! Happiness -20.") | Pass |
| Game over | hunger 100 and happiness 10: game-over banner, bubble "I need a rest.", Play/Feed/Rest/Pause disabled, only Reset active | Pass |
| Pause: hunger frozen, then resumes | Paused at hunger 30 ([before](docs/paused-before.png)), still 30 about a minute later ([after](docs/paused-after.png)), 35 after Resume ([resumed](docs/resumed.png)) | Pass |
| Reset | values back to 50 / 30 / 80, buttons re-enabled ([screenshot](docs/reset.png)) | Pass |
| Reduced motion (on/off) | Remove animations ON: meters jump to new values and the cat does not bounce; labels and values stay visible. OFF: meters glide and the cat bounces | Pass |
| Leave screen (no console errors) | left the app and returned; no `setState() called after dispose()` errors in the console | Pass |
| Release APK installed on device | Pixel 7 emulator, API 35 | 

## Automated tests (graduate)

`flutter test` → `All tests passed!` (24 tests).
Covers: clamping, thresholds 29/30/70/71, hunger overflow, win timing (2:59 / 3:00),
exactly-80 rule, loss rule, pause/resume, reset (single hunger timer), dispose, plus
widget smoke and reduced-motion tests.

## Architecture note (graduate)

`PetController` (a `ChangeNotifier`) owns all game rules and both timers; `PetScreen`
only renders and owns short-lived animation state (bounce) and the name text controller.
**Trade-off:** timers in the controller make rules testable with `fake_async` without
widgets, but the screen must dispose the controller. A state-object-owned timer is
simpler but needs widget tests to cover the rules.

## Accessibility

Mood is shown as text + emoji, never color alone. Meters expose semantic labels.
`MediaQuery.disableAnimations` switches all animation durations to zero.

## Assets

`assets/pet.png`: original artwork generated for this project; no third-party license.
