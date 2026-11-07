# Agent Workspace Guidelines & Session Persistence

This repository uses a persistent session memory protocol to guarantee zero context loss across IDE crashes, reboots, or conversation resets.

## Mandatory Initialization Routine
Whenever starting a new turn, task, or after a system crash:
1. **Read Session Memory:** Open and read [SESSION_MEMORY.md](SESSION_MEMORY.md).
2. **Verify Repository State:** Run git status and verify branch ui. The user's explicit branch instruction overrides the previous enhanced-ui instruction.
3. **Execute Active Tasks:** Proceed from the documented "Crash Recovery Protocol" and "Next Steps" in SESSION_MEMORY.md.
4. **Persist State:** Keep SESSION_MEMORY.md updated as changes occur.

## Flutter & Dart AI Development Architecture (docs.flutter.dev/ai/tools & zakariaf/Flutter-Skills)

This workspace contains Flutter & Dart codebases (e.g. `mobile/` Android & iOS field client) and utilizes the official Flutter AI engineering skills and tools.

### 1. Active Tools & MCP Server
- **Dart and Flutter MCP Server (`dart mcp-server`):** Provides real-time static analysis diagnostics, symbol resolution, test execution, runtime introspection, and hot reload capabilities. Configured in `~/.gemini/antigravity/mcp_config.json` and `.vscode/mcp.json`.
- **UI Design Director:** Framework and style catalog for frontend aesthetics and design consistency (`.agents/skills/ui-design-director/SKILL.md`).

### 2. Flutter Skills Routing Rules & Playbooks
Before writing or reviewing Flutter/Dart code in `mobile/`:
1. Check whether a skill in `.agents/skills/` applies. Follow its non-negotiable rules, anti-patterns, and definitions of done.
2. `flutter-conventions-index` is the front door — start there when unsure.
3. Canonical stack: Flutter 3.x / Dart 3.x, Riverpod 3.x for state/DI, Material 3, and drift for local storage.

### 3. Intent → Skill Map
| When you are… | Consult |
|---|---|
| Structuring a project / deciding where code goes | `flutter-architecture`, `project-structure-and-packages` |
| Adding a feature / screen | `scaffold-feature-module`, then state/widget/nav skills |
| Managing state or dependency injection | `state-management-riverpod` |
| Building or refactoring UI | `widget-composition`, `adaptive-layout`, `ui-design-director` |
| Loading / empty / error states, snackbars, dialogs | `ui-states-and-feedback` |
| Wiring navigation / routes / deep links | `navigation-and-routing` |
| Building a form or handling input | `forms-and-input` |
| Handling errors / async | `error-handling-typed-results`, `async-safety` |
| Storing data locally | `persistence-drift`, `value-objects-money-and-units` |
| Exporting, backing up, or restoring data | `data-export-and-restore` |
| Wiring a side effect or native channel | `service-boundary-and-native` |
| Localizing / RTL | `i18n-rtl-l10n` |
| Accessibility | `accessibility-as-code` |
| Writing tests | `testing-strategy`, `widget-golden-and-a11y-testing` |
| Performance / jank | `flutter-performance` |
| Naming / Dart idioms / docs / lint | `naming-conventions`, `dart3-idioms-and-coding-standards`, `dartdoc-conventions` |
| Codegen / CI / dependencies | `codegen-and-toolchain`, `ci-pipeline-and-gates`, `dependency-hygiene` |
| Applying a schema migration | `run-migration` |
| End-of-build design/QA review | `design-review-workflow` |
| Animating, adding haptics | `motion-and-haptics` |
| Cutting a release, signing, store declarations | `release-and-store-shipping` |
