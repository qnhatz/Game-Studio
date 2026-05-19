# QA Evidence: Orientation Gate — Portrait Block and Resume

**Story**: `production/epics/screen-layout/story-004-orientation-gate.md`
**Story Type**: Integration (manual verification — cannot run headlessly)
**Date**: [ ] Not yet signed off
**Sign-off**: [ ] Pending

---

## Test Environment

- Engine: Godot 4.6
- Export target: Web (browser)
- Test device: [ ] Desktop browser (Chrome/Firefox) | [ ] Mobile browser (iOS Safari / Android Chrome)

---

## AC-1: Portrait blocks input

**Setup**: Run in browser. Resize window to portrait (height > width). Open InputSystem window for P1.

**Steps**:
1. Open game in browser
2. Drag window to portrait orientation (or rotate device)
3. Verify orientation prompt label is visible
4. Tap the P1 gesture area
5. Check P1 action count

**Expected**: Orientation prompt visible; zero FlickEvents emitted; P1 action count unchanged.

**Result**: [ ] PASS | [ ] FAIL
**Notes**: ___

---

## AC-2: Square viewport does not block

**Setup**: Resize window to exactly square (e.g. 450×450).

**Steps**:
1. Resize browser window to equal width and height
2. Verify orientation prompt is hidden
3. Perform a P1 drag gesture

**Expected**: Orientation prompt hidden; FlickEvent emitted; CANVAS_W/CANVAS_H constants unchanged.

**Result**: [ ] PASS | [ ] FAIL
**Notes**: ___

---

## AC-3: Mid-drag portrait transition

**Setup**: Begin a P1 drag; before releasing, switch to portrait orientation.

**Steps**:
1. Start a P1 drag gesture (hold without releasing)
2. While drag is in progress, rotate device or resize window to portrait
3. Release the drag
4. Check: aim line disappeared; no shot registered

**Expected**: `aim_cancelled` signal fired; no FlickEvent; portrait prompt visible; action count unchanged.

**Result**: [ ] PASS | [ ] FAIL
**Notes**: ___

---

## AC-4: Landscape restore resumes input

**Setup**: Portrait gate active; then switch back to landscape.

**Steps**:
1. Start in portrait (prompt visible)
2. Switch back to landscape (width > height)
3. Verify prompt disappears
4. Perform a P1 drag gesture
5. Verify `ScreenLayout.CANVAS_W` still reads 800

**Expected**: Prompt dismissed; FlickEvent emitted; CANVAS_W == 800.

**Result**: [ ] PASS | [ ] FAIL
**Notes**: ___

---

## Sign-off

**QA Reviewer**: ___
**Date**: ___
**Verdict**: [ ] APPROVED | [ ] APPROVED WITH CONDITIONS | [ ] REJECTED
**Conditions / Notes**: ___
