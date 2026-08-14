---
ijfw_version: 1.3.2
ijfw_schema: 1
type: software
primary_type: software
secondary_types: []
confidence: 0.907
detected_at: 2026-08-14T01:12:46.237Z
signals:
  - kind: manifest
    weight: 0.9
    manifests: [package.json]
  - kind: file_extension_ratio
    weight: 0.7
    domain: software
    ratio: 1
    count: 43
---

# AGENTS.md

This file follows the open AGENTS.md spec (https://agents.md/) and is the
canonical agent-instructions surface for this project. Platform-specific
files (CLAUDE.md, GEMINI.md, WAYLAND.md, codex/AGENTS.md, .cursorrules,
.windsurfrules, copilot-instructions.md) are thin adapters that point here.

Five IJFW-managed regions live in this file. Content outside the markers is
yours -- IJFW will never touch it.

| Region     | Purpose                                                                           |
| ---------- | --------------------------------------------------------------------------------- |
| MEMORY     | Project memory recalled from `.ijfw/memory/`                                      |
| ROUTING    | Platform skill-routing rules                                                      |
| AGENTS     | Registered agent roster                                                           |
| BLACKBOARD | Multi-CLI orchestration scratchpad (Pillar B)                                     |
| DISCIPLINE | Per-domain discipline rules (code \| narrative \| business \| design \| research) |

<!-- IJFW-MEMORY-START -->

Project memory at .ijfw/memory/. Call `ijfw_memory_prelude` for full context.

<!-- IJFW-MEMORY-END -->

<!-- IJFW-ROUTING-START -->
<!-- IJFW-ROUTING-END -->

<!-- IJFW-AGENTS-START -->

- **ijfw-code-fixer** -- ijfw-code-fixer for software projects; owns module.
- **ijfw-integration-checker** -- ijfw-integration-checker for software projects; owns test.
<!-- IJFW-AGENTS-END -->

<!-- IJFW-BLACKBOARD-START -->
<!-- Reserved for Pillar B multi-CLI orchestration. Empty in alpha. -->
<!-- IJFW-BLACKBOARD-END -->

<!-- IJFW-DISCIPLINE-START -->
<!-- IJFW-DISCIPLINE-END -->
