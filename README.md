# Digital Pet (In-Class Activity 07)

Flutter pet-care app: actions and time change visible state (mood tint, meters, speech).

## Team

| Member | Team | Pathway (UG/Grad) | Role | Features claimed |
|---|---|---|---|---|
| TODO | Team 1 · Care Systems | TODO | TODO | TODO |
| TODO | Team 2 · Pet Personality | TODO | TODO | TODO |
| TODO | | | | |

Issues / PRs: TODO links (one PR per team + the cross-team review links).

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
| Pause | Stops both timers; win progress is lost (must be >80 for a fresh 3 min) |
| Meters | Always clamped to 0-100 |

## Advanced features → learning outcomes → evidence

| Feature | Learning outcome | Evidence |
|---|---|---|
| Energy system | Related meters updated atomically with clamping | TODO screenshot, test "play at energy 5 is refused" |
| Visual polish & accessible motion (bounce, living meters, expression switch, mood tint+size, speech, reduced motion) | UI derived from one state; lifecycle-safe delayed callbacks | TODO screenshots at 29/30/70/71; reduced-motion on/off |
| Session controls (pause/resume) | Timer lifecycle and safe outcome handling | Test "pause stops hunger and the win timer" |

## Manual test results

| Scenario | Before → After | Result |
|---|---|---|
| Feed at hunger 5 | TODO | TODO |
| Feed at hunger 95 | TODO | TODO |
| Play at happiness 95 | TODO | TODO |
| Play at energy 5 | TODO | TODO |
| Happiness 29 / 30 / 70 / 71 | TODO screenshots | TODO |
| Win timer cancelled at 80 | TODO | TODO |
| Win after 3:00 | TODO | TODO |
| Hunger 95 → 100 → overflow tick | TODO | TODO |
| Game over | TODO | TODO |
| Leave screen (no console errors) | TODO | TODO |
| Release APK installed on device | TODO device/model | TODO |

## Automated tests (graduate)

`flutter test` → TODO paste summary (e.g. "All tests passed!").
Covers: clamping, thresholds 29/30/70/71, hunger overflow, win timing (2:59 / 3:00),
exactly-80 rule, loss rule, pause/resume, reset (single hunger timer), dispose.

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
TODO: replace this line if you swap in your own asset and credit its license.
