---
name: accessibility-check
description: Fix-as-you-build accessibility checklist for a SwiftUI view or component. Use right after building or changing any view (new-ds-component, new-screen), before calling it done. The read-only accessibility-auditor agent is the independent second pass.
---

# Accessibility Check

Accessible from the first commit, not a backlog item. Fix what you find; do not just report it.

## Steps
1. **Images and icons:** decorative ones get `.accessibilityHidden(true)`; meaningful ones get `.accessibilityLabel(...)`. Never rely on the SF Symbol name being read.
2. **No state by color alone.** Category chips and the done state need text/shape too, and the label states the fact ("Category: Work", "Completed"), not the color.
3. **One VoiceOver stop per compound view.** A task row (checkbox, title, description, chip) uses `.accessibilityElement(children: .combine)` or `.ignore` plus an explicit label. The checkbox is its own control with a label ("Mark done" / "Mark not done") and value.
4. **Custom tappables** that are not a real `Button`: `.accessibilityAddTraits(.isButton)` and a label describing the result ("Delete task"), not the mechanism.
5. **Dynamic Type:** tokens use scaling fonts; no fixed-height frames on text; check previews at `.accessibility3` and `.accessibility5`; layouts must wrap or scroll, not clip.
6. **Touch targets >= 44x44pt**; pad the hit area, do not shrink it to the glyph (design: checkbox 44, add button 44, options button 40 -> pad to 44).
7. **Contrast WCAG AA:** compute for `text-muted` on `bg` and each chip fg/bg pair; report ratios; fix by adjusting the token only with the user's OK.
8. **Reduce motion:** gate non-trivial animation (toast, sheets) behind `accessibilityReduceMotion`.
9. **Toast and Undo:** announce with `AccessibilityNotification.Announcement`; Undo must be reachable by VoiceOver.
10. Verify in per-state previews, with VoiceOver reasoning and a large Dynamic Type size.

## Common misses
- Image with no label and no hidden flag.
- `.onTapGesture` on a stack with no traits.
- Fixed `.frame(height:)` on text.
- Multi-element row left fragmented into several swipes.
