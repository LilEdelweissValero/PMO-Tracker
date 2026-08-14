---
name: PMO Tracker
description: A kinetic project studio where accountable work feels clear, tactile, and alive.
colors:
  studio-violet: "#5b37f2"
  studio-violet-deep: "#3216a9"
  studio-violet-soft: "#8067ff"
  instrument-cream: "#fff9ec"
  instrument-warm: "#f5ecd9"
  technical-plum: "#17132f"
  technical-raised: "#24204a"
  graphite-ink: "#19152f"
  muted-ink: "#665f78"
  mist-line: "#ded5c4"
  action-candy: "#ff4eb8"
  action-candy-deep: "#d92591"
  signal-cyan: "#3ad9ee"
  relay-lime: "#c6ef55"
  hold-yellow: "#ffd15d"
  danger: "#c9345e"
  white: "#ffffff"
typography:
  display:
    fontFamily: "Bricolage Grotesque, Manrope, sans-serif"
    fontSize: "clamp(3rem, 5.4vw, 5.8rem)"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.038em"
  headline:
    fontFamily: "Bricolage Grotesque, Manrope, sans-serif"
    fontSize: "clamp(2.4rem, 4vw, 4.6rem)"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.038em"
  title:
    fontFamily: "Bricolage Grotesque, Manrope, sans-serif"
    fontSize: "20px"
    fontWeight: 800
    lineHeight: 1.05
    letterSpacing: "-0.025em"
  body:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "10px"
    fontWeight: 850
    lineHeight: 1.2
    letterSpacing: "0.08em"
  mono:
    fontFamily: "Azeret Mono, ui-monospace, monospace"
    fontSize: "11px"
    fontWeight: 750
    lineHeight: 1.4
rounded:
  sm: "10px"
  md: "14px"
  lg: "18px"
  xl: "24px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "14px"
  lg: "18px"
  xl: "24px"
  section: "42px"
components:
  button-primary:
    backgroundColor: "{colors.technical-plum}"
    textColor: "{colors.white}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "0.65rem 1rem"
    height: "42px"
  button-action:
    backgroundColor: "{colors.action-candy}"
    textColor: "{colors.graphite-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "0.65rem 1rem"
    height: "42px"
  input:
    backgroundColor: "{colors.white}"
    textColor: "{colors.graphite-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "9px 12px"
    height: "42px"
  technical-stage:
    backgroundColor: "{colors.technical-plum}"
    textColor: "{colors.white}"
    rounded: "{rounded.lg}"
    padding: "16px"
---

<!--
THESIS: PMO work becomes a kinetic project studio, refusing both generic enterprise dashboards and childish pastel toyboxes.
OWN-WORLD: A luminous violet field, creamy instrument decks, charcoal data stages, oversized friendly lettering, candy-bright labels, and original sculpted project objects.
STORY: The PMO sees who holds responsibility, what has waited longest, and where to act next; playful material makes rigorous stewardship inviting.
FIRST VIEWPORT: A typographic greeting shares the top stage with the living Ball, its current owner, and the oldest handoffs; compact portfolio evidence follows without a decorative preamble.
FORM: The Kinetic Project Studio; sixth grounded direction; model-shop control-desk staging; seed 63f13089.
-->

# Design System: PMO Tracker

## Overview

**Creative North Star: “The Kinetic Project Studio”**

PMO Tracker is a glamorous working studio for serious portfolio stewardship. It combines the confidence of beautifully art-directed software with the physical delight of a model shop: luminous color fields, creamy instrument panels, deep technical canvases, friendly oversized type, tiny categorical badges, and a small family of original three-dimensional project objects. The result is whimsical and cute without becoming juvenile, and operational without becoming anonymous.

The interface always keeps accountability ahead of spectacle. Current ownership, Stage, State, age, and next action remain readable without interpreting an illustration. Dimensional objects create recognition and reward around the product’s unique language; they never become a parallel icon system for ordinary navigation or status.

The Dashboard is the first proving surface. It opens with the Ball, the longest-waiting work, and the action that matters now. KPI definitions, Progress, and Bumps follow as compact instruments rather than a generic grid of interchangeable cards.

**Key Characteristics:**

- Saturated, atmospheric application framing with pale working surfaces and dark technical stages.
- Exceptional typographic scale contrast: expressive headlines, compact operational copy, and precise tabular data.
- Original soft 3D objects used sparingly for product concepts, orientation, and memorable state changes.
- Tactile controls with explicit labels, small badges, and purposeful spring-like motion.
- Dense records that remain calm, aligned, and familiar even when the surrounding world is exuberant.

**The Delight Serves Duty Rule.** A playful device earns its place only when it improves orientation, recognition, feedback, or recall.

**The Original Object Rule.** The dimensional Ball and Bump artwork must be authored for PMO Tracker. Do not reuse Charm characters, emoji, stock clip art, or third-party mascots.

## Colors

Use a **Committed** color strategy: electric violet owns the application atmosphere and major framing regions rather than appearing as scattered accents. Warm cream gives working content a calm, tactile ground; near-black plum creates technical focus for queues, timelines, and dense evidence. Candy pink is the principal action color, while cyan, lime, and warm yellow appear as small categorical or feedback notes.

The normative values live in the frontmatter and in `app/globals.css`. The palette retains decisive light/dark separation and never collapses into a soft lavender monochrome.

### Primary

- **Studio Violet:** The committed identity field for navigation, major framing, and selected high-level surfaces.
- **Studio Violet Deep:** The darker shell anchor and navigation field.
- **Action Candy:** The scarce high-energy color for the principal mutation on a surface.
- **Action Candy Deep:** The contact edge beneath candy actions; it supplies physical depth rather than a second action hue.

### Secondary

- **Signal Cyan:** PMO ownership, informative emphasis, focus rings, and cool technical accents.
- **Relay Lime:** completed or healthy outcomes and System Owner context when accompanied by text.
- **Hold Yellow:** waiting, caution, and Developer context when accompanied by text.

### Neutral

- **Instrument Cream:** Primary working panels, forms, and long-reading surfaces.
- **Technical Plum:** Dense operational canvases, navigation, timelines, and high-contrast data regions.
- **Graphite Ink:** Main text on light surfaces.
- **Mist Line:** Dividers, field boundaries, and quiet structure.
- **Technical Raised:** Dense rows mounted one level above Technical Plum.
- **White:** Inputs and the cleanest record strips; use it as a local material, never as the application atmosphere.

**The Field, Not Confetti Rule.** Violet should own coherent regions; do not sprinkle every accent color across white cards.

**The Written Status Rule.** Color never communicates ownership group, warning, success, priority, or State without a visible label.

## Typography

Typography carries most of the personality. Bricolage Grotesque supplies buoyant, confident display forms; Manrope handles repeated operational reading; Azeret Mono makes Project Codes, ages, and timestamps auditable at a glance. All three are loaded through `next/font` and exposed as CSS variables, so fallbacks remain predictable.

### Hierarchy

- **Display** (800, `clamp(3rem, 5.4vw, 5.8rem)`, 0.95): Oversized Dashboard greetings and rare focal moments.
- **Headline** (800, `clamp(2.4rem, 4vw, 4.6rem)`, 0.95): Page titles that remain friendly at operational sizes.
- **Title** (800, 20px, 1.05): Panel, dialog, and Project names with compact rhythm.
- **Body** (400, 14px, 1.55): Dense UI copy optimized for repeated daily reading, with explanatory passages capped around 70–75ch.
- **Label** (850, 10px, 0.08em): Uppercase only for compact instrument metadata; ordinary field labels stay sentence case.
- **Tabular Mono** (750, 11–12px): Project Codes, timestamps, durations, KPI formulas, and auditable identifiers only.

**The Type Does the Smiling Rule.** Friendly lettering supplies everyday charm; illustrations do not need to decorate every panel.

**The Two-Second Scan Rule.** Project, owner, Stage, and age must form a stable typographic rhythm across every dense list.

## Layout

The application uses a studio-and-instrument model. A saturated shell provides identity and navigation; cream decks hold routine work; dark technical stages concentrate timelines, queues, or evidence. Surfaces may overlap or break the grid at expressive moments, but dense operational rows remain aligned to predictable columns.

The Dashboard’s first viewport pairs an oversized greeting with a living ownership module: a dimensional basketball, its current holder, and the oldest waiting handoffs. The Ball is a focal anchor, not a full-screen hero. Progress and Bump queues begin within the same viewport on common laptop sizes so daily work is never pushed below decoration.

KRA/KPI definitions read as a deliberately composed instrument cluster of clean, regular panels. They may vary in size or emphasis, but their silhouettes stay simple and well proportioned; novelty cut corners, skewed tiles, and arbitrary polygon cards are forbidden. “Not yet calculated” remains visibly honest and never appears as a fabricated chart. Latest Progress and Latest Bumps use distinct pacing and signature markers while sharing the same scan order.

Desktop uses a 220px navigation bay and a fluid cream workbench with 12px shell gaps. At 1320px, the lower Progress and Bump technical stages stack before their internal record columns can collide. At 1050px, the navigation contracts to a 76px icon rail and the Dashboard becomes one primary column. At 700px, the shell becomes a linear page with a 66px floating bottom navigation, 14px side padding, and 96px bottom clearance. Administration tables may scroll horizontally rather than hide required facts.

The spatial rhythm is intentionally compact: 6px micro-gaps, 10–18px component gaps, 24px major padding, and 42px between long-form sections. Responsive rules protect readable content before preserving a decorative arrangement.

**The Work Starts Above the Fold Rule.** On the Dashboard, at least one actionable queue or oldest-waiting record must be visible in the first viewport.

**The Plain Vessel Rule.** Containers stay geometrically quiet so typography, 3D objects, color, and motion can carry the whimsy.

## Elevation & Depth

Depth is tactile and structural. Cream panels sit above the violet field with a broad deck shadow (`0 12px 0 rgba(47, 26, 126, 0.08), 0 22px 48px rgba(37, 22, 87, 0.16)`); dark technical stages use a firmer mounted shadow (`0 8px 0 #cfc2ad, 0 20px 36px rgba(29, 20, 55, 0.18)`). Controls use a crisp contact shadow (`0 5px 0 rgba(30, 20, 75, 0.2), 0 10px 24px rgba(30, 20, 75, 0.14)`) and a small physical press response. Three-dimensional signature objects use soft studio lighting, rounded materials, and believable contact or cast shadows appropriate to their scene.

Avoid glassmorphism, translucent card stacks, neon glows around every edge, and generic floating-gradient blobs. Atmospheric light may live in the violet background, but working content must retain strong boundaries and contrast.

**The One Impossible Object Rule.** Each major surface may feature one dominant dimensional object or object group. Supporting data remains materially quieter.

## Shapes

The form language mixes soft sculpted objects with disciplined instruments. Major cream panels use generous, friendly corners; dark data stages use slightly tighter geometry. Buttons and inputs feel compact and tactile rather than pill-shaped by default. Small pills are reserved for categorical badges, State, Priority, and concise status notes.

The implemented radius scale is 10px for controls, 14px for record groups, 18px for mounted panels, and 24px for major shell surfaces. Circular geometry is reserved for group signals, avatars, and the Ball's orbit—not ordinary containers.

The 3D Ball is a recognizable basketball with accurate seam logic, a softly inflated silhouette, and an authored PMO Tracker personality expressed through pose and motion—not a pasted face. It may be accompanied by a small orbit, holder tag, or relay trail, but it must remain visually legible at compact sizes.

The Bump object is a sculpted fist-bump motif. At rest, the control shows a compact dimensional fist beside the written label “Bump.” On activation, a second fist may enter, meet it briefly, and rebound. The silhouette must remain readable without relying on skin tone; use the product palette and toy-like material rather than realistic human anatomy.

## Components

### The Ball

The Ball is the product’s living responsibility marker. On the Dashboard it appears as a polished 3D basketball at focal scale, paired with the written owner, ownership group, held duration, and the oldest relevant handoffs. In dense rows it becomes a small rendered or simplified authored mark, never an emoji.

When ownership transfers, the Ball follows one short directional arc from the previous holder to the new holder, settles with a restrained spring, and stops. No perpetual bouncing in tables or forms. With reduced motion, use an immediate state change or brief cross-fade while preserving the old and new owner labels in the confirmation message.

### Bump Action

Every Bump action keeps the text label visible. The principal Bump button combines that label with the sculpted fist object and uses a compact tactile press. Hover or focus may create a small anticipation movement; successful activation may complete one fist-bump cycle. The animation confirms the conversational update but must never imply that Stage changed.

### Project Records

Project rows preserve the scan order: Project Code, name with State and Priority, Stage, Ball Owner, then held duration. Use strong type, deliberate alignment, and controlled contrast instead of wrapping every value in a badge. The Ball marker may punctuate ownership, but the written owner is always primary evidence.

### Panels and Technical Stages

Cream panels host forms, explanations, and routine summaries. Dark technical stages host concentrated queues, event history, or auditable details. Avoid an undifferentiated card grid; each panel must have a named job and a clear internal hierarchy.

### Buttons and Fields

Principal mutations use Action Candy, direct verbs, 10px corners, a minimum 42px height, and 10px × 16px internal padding. Default actions use Technical Plum; secondary actions use Instrument Cream. Hover lifts 2px, active presses 2px, and disabled controls remove motion and shadow. Every interactive element uses a 3px Signal Cyan focus ring with a 3px offset.

Fields use a white surface, 1px warm-gray border, 10px corners, 9px × 12px padding, and a 42px minimum height. Hover shifts the border to Studio Violet Soft; focus uses the global cyan ring. Labels persist above fields. Terminal State actions state irreversibility before confirmation.

### Navigation

Navigation belongs to the violet studio frame and uses simple, familiar symbols plus written labels. Desktop entries have 10px corners and 11px × 12px padding. The selected item becomes a cream plate with dark text and a violet icon, so selection is obvious without color alone. At 1050px it contracts to an icon rail; at 700px it becomes a six-item floating bottom tray. Signature 3D objects do not replace general navigation icons.

## Do's and Don'ts

### Do:

- **Do** make the Ball the clearest recurring expression of accountability across Dashboard, Ball View, Project details, and transfer feedback.
- **Do** give Bump a memorable dimensional fist motif while keeping the action’s conversational meaning explicit.
- **Do** use expressive type and authored spacing before adding more illustration.
- **Do** reserve full 3D rendering for signature concepts, onboarding, empty states, and important transitions.
- **Do** use clean rectangular or softly rounded KRA/KPI panels with strong typography and disciplined spacing.
- **Do** keep motion short, interruptible, and removable through `prefers-reduced-motion`.
- **Do** label all timestamps in PHT or Asia/Manila and preserve persistent field labels and visible focus.

### Don't:

- **Don't** recreate Charm’s characters, layouts, logos, product cards, or exact visual assets; match the craft and exuberance, not the identity.
- **Don't** return to pixel art, graph-paper stationery, blocky two-pixel outlines, or the old pastel ledger treatment.
- **Don't** turn the Dashboard into a landing page with operational work below a decorative hero.
- **Don't** animate every object, loop the Ball continuously, or let motion compete with scanning.
- **Don't** use emoji basketballs or fist emoji as shipped artwork.
- **Don't** soften every surface into rounded white cards on a pale background; maintain the violet field, cream instruments, and dark technical stages.
- **Don't** use skewed, clipped, polygonal, or novelty-shaped cards for Project Efficiency, Project Safety, Project Governance, or other routine information.
