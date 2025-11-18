# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **[ ] Principle I (Hardware Integration):** Does this feature correctly interface with Bmduino sensors or actuators?
- **[ ] Principle II (Centralized Data Hub):** Does this feature process data via the Raspberry Pi server and expose it via the API?
- **[ ] Principle III (Clear User Guidance):** If user-facing, does this feature include a clear UI on the Raspberry Pi display?
- **[ ] Principle IV (Action Verification):** Does this feature require computer vision to verify a patient's action?
- **[ ] Principle V (Remote Accessibility):** Is data from this feature accessible via the mobile app API?
- **[ ] Principle VI (Standardized Directory Structure):** Does the file layout for this feature comply with the mandated structure?
- **[ ] Principle VII (Development Environment):** If developing for Bmduino, is the work being done in the Arduino IDE?
- **[ ] Principle VIII (Inter-Component Communication):** Does the feature respect the wired, bidirectional communication protocol between Bmduino and Raspberry Pi?

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

The project is divided into two main components: `Bmduino/` and `raspberrypi/`. Both components MUST follow the standardized directory structure as defined in the constitution.

```text
[component]/ # (e.g., Bmduino/ or raspberrypi/)
├── code/      # For independent small functions or scripts
├── data/      # For databases, datasets, or data generation scripts
├── program/   # For integrated, complete feature programs
├── reference/ # For related reference documents and manuals
└── report/    # For project reports and analysis
```

**Structure Decision**: All new features must place their files within the appropriate component (`Bmduino` or `raspberrypi`) and under the correct subdirectory (`code`, `data`, `program`) as per the constitution.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
