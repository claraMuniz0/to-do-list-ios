---
name: design-to-swiftui-spec
description: Read a screen or component from the pen.dev design file to-do.pen via the mcp__pencil__* tools and produce a written SwiftUI SPEC (not code). Trigger when asked to inspect, extract, document, or "spec" a screen, frame, or component from the design before implementing it.
---

# Design to SwiftUI spec

Output is a written spec only. Write no Swift. Hand the result to `new-ds-component` or the screen's phase work.

## Reading the design
- [ ] `to-do.pen` is encrypted: NEVER use Read/Grep/cat on it. Use only `mcp__pencil__*` tools.
- [ ] If those tools are deferred, load them first with ToolSearch (`select:mcp__pencil__get_app_state,mcp__pencil__execute`, add `mcp__pencil__read_skill` / `get_style` if needed).
- [ ] Call `get_app_state` first (confirms the open file and selection).
- [ ] Then `execute` and use `Get` to fetch the target node(s) and `Print` to dump their properties/children. Walk children recursively; also fetch the variables (tokens) used.
- [ ] Do not modify the design. Read-only.

## Spec contents (one section each, in this order)
1. **Target**: frame/component name, node id, where it is used.
2. **Tokens used**: color variables (by .pen variable name), typography (family, size, weight), radii, shadows. Flag raw values that should be tokens (hex or font not bound to a variable).
3. **Layout**: width/height, padding, spacing, alignment, corner radii, strokes, shadows (color, offset, blur). Note touch-target size vs visual size (minimum 44pt).
4. **States and variants**: default, selected, done, disabled, empty, etc., with what changes in each.
5. **Component mapping**: for every element, whether it is an instance of an existing component, which one, and which overrides it applies (label, icon, width, padding, fill, stroke).
6. **Icons**: Lucide name -> SF Symbol (table in `docs/phases/phase-1-design-system.md`: check/`checkmark`, plus/`plus`, trash-2/`trash`, sliders-horizontal/`slider.horizontal.3`, sparkles/`sparkles`). Unmapped icon: propose a symbol and mark it as a proposal.
7. **Copy**: exact text strings, placeholders, accessibility labels to add.
8. **Suggested SwiftUI shape**: component name and parameter list (names/types only, no bodies).
9. **Unknowns / questions for the user**: anything ambiguous, missing, or contradicting the phase doc. Do not guess silently.

## Lesson already learned (apply every time)
Many "components" in screens are overrides of ONE base component, not separate components. Before listing a new component, check whether its structure matches an existing one:
- Save Button, Add First Task Button = Primary Button (label/icon/full width)
- Work / Personal / Shopping / New Category Option = Category Chip (`.option` style: larger padding, selection stroke)
- Today / Tomorrow / Next week pills, All / Active / Done filters = Filter Pill (selected = accent fill)
- Quick Add Input = Add Task Input (full width)
- Task Row / Task Row Done = one row, two states
Report such matches as "instance of X with overrides Y", and propose a parameter, never a new view.

## Constraints
- Light mode only; ignore dark variants if any appear.
- Status-bar signal/wifi/battery are system UI: omit.
- Keep the spec concise; tables over prose.
