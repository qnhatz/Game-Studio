# QA Evidence: Multi-Touch Zone Isolation

**Story**: `production/epics/screen-layout/story-005-multi-touch-zone-isolation.md`
**Story Type**: Integration (manual verification — requires multi-touch hardware or browser DevTools)
**Date**: [ ] Not yet signed off
**Sign-off**: [ ] Pending

---

## Implementation Note

All three acceptance criteria are implemented through prior stories:
- AC-1: Single-window model (InputSystem Story 002) — only one player's window open per turn
- AC-2: `_dragging` guard in `_on_pointer_down()` (InputSystem Story 002) — second touch silently discarded
- AC-3: No zone re-check in `_on_pointer_move()` (InputSystem Story 002) — owning touch continues regardless of position

---

## Test Environment

- Engine: Godot 4.6
- Export target: Web (browser)
- Test device: [ ] Desktop browser with DevTools touch simulation | [ ] Mobile device (iOS Safari / Android Chrome)

---

## AC-1: Simultaneous drags — independent tracking

**Setup**: Browser DevTools → touch simulation enabled. Open InputSystem window for P1.

**Steps**:
1. Simulate P1 touch start in P1 zone (left half, below HUD)
2. While P1 drag is active, simulate a second touch in P2 zone (right half)
3. Observe aim line and action counts

**Expected**: Only P1 aim line fires; P2 touch discarded (window not open for P2); zero P2 actions consumed.

**Result**: [ ] PASS | [ ] FAIL
**Notes**: ___

---

## AC-2: Second touch in same zone discarded

**Setup**: Browser DevTools → touch simulation. Open InputSystem window for P1.

**Steps**:
1. Simulate touch ID 0 starting drag in P1 zone
2. Before releasing, simulate touch ID 1 starting in P1's zone
3. Verify aim line comes only from touch ID 0
4. Release touch ID 0
5. Verify FlickEvent fires with correct direction

**Expected**: `_touch_id` stays 0; `_dragging` stays true; aim line unaffected; single FlickEvent on release.

**Result**: [ ] PASS | [ ] FAIL
**Notes**: ___

---

## AC-3: Cross-zone pointer stays owned

**Setup**: Browser DevTools → touch simulation. Open InputSystem window for P1.

**Steps**:
1. P1 begins drag in P1 zone (touch ID 0)
2. Move pointer across Corridor and into P2 zone
3. Continue moving and observe `aim_updated` signals
4. Release in P2 zone

**Expected**: `aim_updated` continues firing with crossed/clamped position; drag not cancelled; FlickEvent emitted on release; direction computed from P1 figure anchor.

**Result**: [ ] PASS | [ ] FAIL
**Notes**: ___

---

## Sign-off

**QA Reviewer**: ___
**Date**: ___
**Verdict**: [ ] APPROVED | [ ] APPROVED WITH CONDITIONS | [ ] REJECTED
**Conditions / Notes**: ___
