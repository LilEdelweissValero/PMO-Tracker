# PMO Tracker design system

The interface is a whimsical portfolio control ledger: compact flight-progress strips meet pastel pixel-art stationery. It preserves operational scanability while giving the small internal tool an unmistakably cheerful voice.

## Visual language

- Cool lilac paper canvas with a faint 32 px pixel grid; white working surfaces and dark aubergine ink.
- Accent roles: pink for primary action, purple for identity/focus, blue for PMO, amber for Developers, and mint/teal for System Owners.
- Controls use crisp two-pixel outlines, small radii, and a short offset shadow. Data surfaces remain rectangular and dense.
- Original pixel SVG sprites carry product language: the Ball is a basketball and Bump is two meeting fists. Do not substitute emoji or reuse third-party pixel artwork.
- Typography uses a friendly workhorse sans stack for prose and tabular monospace only for Project Codes, timestamps, and durations.

## Components

Project strips always preserve the scan rhythm: Code, name/State/Priority, Stage, Ball Owner, held duration. At narrow widths, Stage and owner detail collapse while Code, name, and duration remain.

Ball View keeps PMO → Developers → System Owners order and always includes the written group label. Color never communicates group, warning, success, or danger alone.

Buttons name actions directly. Pink is reserved for the principal mutation on a surface. Terminal State actions must state their irreversibility before confirmation.

## Motion and accessibility

Strip transfers use a brief directional translation. `prefers-reduced-motion` removes all transitions. Focus receives a visible purple ring. Dates always include PHT or Asia/Manila. Form controls keep persistent labels; errors identify both problem and recovery.

## Responsive behavior

The sidebar becomes an icon rail below 900 px and a bottom navigation below 560 px. Ball bays stack in canonical order. Administration tables may scroll horizontally rather than hide required history.
