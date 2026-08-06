# IN Schemes - Frontend Development Guidelines & Custom Rules

This file establishes the non-negotiable coding and design guidelines for developers working on the frontend code.

## 📱 Responsive Layout & Overflow Prevention Rules
- **NEVER** use fixed heights for pages, cards, or major widgets unless absolutely necessary and justified in a code comment.
- **NEVER** assume a specific screen size. All layouts must work from 320dp width phones up to 800dp+ tablets without breaking.
- Use `SafeArea` on **EVERY** page/screen body to handle notches and status bars correctly.
- Use `LayoutBuilder` when layout changes based on available width or height.
- Use `Expanded`, `Flexible`, and `Spacer` instead of large fixed `SizedBox` heights/widths.
- Any content that may exceed screen height **MUST** be wrapped in a `SingleChildScrollView`.
- Keep primary CTA buttons fixed at the bottom when appropriate using `SafeArea` + padding. Avoid fixed pixel offsets from the screen top.
- **NEVER** produce RenderFlex overflow on any device. Test every layout mentally against:
  - 320x568 (very small phone)
  - 360x640 (budget Android)
  - 390x844 (iPhone standard)
  - 412x915 (large Android)
  - 800x1280 (tablet)
- Respect keyboard insets. Ensure `resizeToAvoidBottomInset` is `true` when text inputs are present, so the layout viewport shrinks and becomes scrollable.
- No magic numbers anywhere in the code.
- Use `EdgeInsets.symmetric` and standard theme spacing consistently instead of ad-hoc padding numbers.

## 🛠️ Code Quality & Architecture
- Use `const` constructors wherever possible to optimize render cycles.
- Keep widgets modular: if a widget exceeds 50 lines, extract it into a separate subclass.
- Separate reusable components into a `/widgets` or `/components` folder.
- Use semantic, self-explanatory naming for all variables, widgets, and functions.
- No commented-out dead code or `print()` statements in production code.
- Every function must perform **ONE** thing.

## 🎨 Material 3 & Theming
- Follow Material 3 guidelines for all components.
- **NEVER** hardcode colors — always use `Theme.of(context).colorScheme` or defined theme constants.
- **NEVER** hardcode text styles — always use `Theme.of(context).textTheme`.

## 🔄 Riverpod & go_router
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for all feature screens.
- Keep providers in dedicated provider files, not inside UI files.
- Use `AsyncValue` properly with `.when(data, loading, error)` for all async states.
- All navigation must go through `go_router`. Define all routes in a central router file.
