# Design System Strategy: Luminous Editorial

## 1. Overview & Creative North Star
**Creative North Star: "Luminous Clarity"**

This design system is built to transcend the standard "SaaS-blue" aesthetic, moving instead toward a high-end editorial experience. It leverages the airy, expansive nature of pastel blues and lavender tones to create a digital environment that feels breathable yet authoritative. 

The system moves away from rigid, boxed-in layouts in favor of **Intentional Asymmetry** and **Tonal Depth**. By utilizing wide margins, varying typographic scales, and overlapping elements, we create a signature look that mimics a luxury print magazine. We are not just building an interface; we are curating a space where content is elevated by the very air it breathes.

---

## 2. Colors & Surface Philosophy
The palette is a sophisticated blend of deep technical blues and ethereal pastels. The interaction between the deep `primary` (#003B93) and the soft `tertiary_container` (#59508D) provides a rhythmic visual weight.

### The "No-Line" Rule
To maintain a premium, seamless feel, **this design system prohibits the use of 1px solid borders for sectioning.** 
*   **The Law:** Boundaries must be defined through background color shifts. Use `surface_container_low` to define a sidebar against a `surface` background.
*   **The Exception:** If a visual break is required for functional clarity, use a subtle shift in tone (e.g., `outline_variant` at 20% opacity) rather than a hard line.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine vellum.
*   **Base:** `surface` (#FBF9F8) or `surface_bright`.
*   **Secondary Layer:** `surface_container_low` (#F6F3F2) for large secondary content blocks.
*   **High-Priority Cards:** `surface_container_lowest` (#FFFFFF) to provide a crisp, white "pop" against the off-white background.

### The "Glass & Gradient" Rule
To add "soul" to the layout, avoid flat colors for primary CTAs.
*   **Signature Gradients:** Use a subtle linear gradient (Top-Left to Bottom-Right) transitioning from `primary` (#003B93) to `primary_container` (#0051C3).
*   **Glassmorphism:** For floating navigation or modals, use `surface_container_lowest` with a 70-80% opacity and a `backdrop-blur` of 20px. This allows the pastel blue (`primary_fixed`) and lavender (`tertiary_fixed`) backgrounds to bleed through softly.

---

## 3. Typography: The Editorial Voice
This design system utilizes a dual-font approach to balance personality with extreme legibility.

*   **Display & Headlines (Plus Jakarta Sans):** These are our "Voice." They should be set with tight letter-spacing (-0.02em) and generous leading. Use `display-lg` (3.5rem) for hero sections to create a sense of scale and confidence.
*   **Body & Labels (Inter):** This is our "Engine." Inter provides a neutral, high-legibility foundation. Use `body-lg` (1rem) for standard reading text.
*   **The Monospace Accent:** Use `monospace` (at 11% weight across the system) for metadata, labels, or technical values. This adds a "curated/engineered" feel to the high-end aesthetic.

---

## 4. Elevation & Depth
We eschew traditional shadows in favor of **Tonal Layering**. Depth is a result of color proximity, not artificial lighting.

*   **The Layering Principle:** Place a `surface_container_lowest` card on a `surface_container_low` section. The minute shift in brightness creates a natural "lift."
*   **Ambient Shadows:** For elements that must float (like a main CTA button or a dropdown), use a shadow tinted with the `on_surface` color at 4% opacity. 
    *   *Formula:* `0px 12px 32px rgba(27, 28, 28, 0.04)`.
*   **The "Ghost Border":** If accessibility requires a container edge, use the `outline_variant` token at 15% opacity. It should be felt, not seen.

---

## 5. Components

### Buttons
*   **Primary:** Gradient fill (`primary` to `primary_container`) with `on_primary` (#FFFFFF) text. Roundedness: `md` (0.75rem).
*   **Secondary:** `secondary_container` fill with `on_secondary_container` text. No border.
*   **Tertiary:** Text-only in `primary`, using a `full` rounded pill shape for the hover state in `primary_fixed` at 30% opacity.

### Chips
*   **Filter Chips:** Use `tertiary_fixed` (#E5DEFF) for the background with `on_tertiary_fixed` (#1B104C) for the label. This introduces the lavender "signature" tone without overwhelming the UI.

### Input Fields
*   **Styling:** No bottom line or full box. Use `surface_container_highest` as a soft background block with `md` (0.75rem) corners. 
*   **Active State:** Change background to `surface_container_lowest` and add a "Ghost Border" of `primary` at 40% opacity.

### Cards & Lists
*   **Rule:** **Zero Dividers.** Use vertical white space (32px or 48px from the spacing scale) to separate list items. 
*   **Composition:** Group related items using a `surface_container_low` background wrap rather than drawing a line between them.

### Signature Component: The "Content Veil"
For long-form editorial content, use a `surface_bright` to `transparent` gradient overlay at the bottom of the viewport to encourage scrolling, rather than a hard cut-off.

---

## 6. Do's and Don'ts

### Do:
*   **Use Asymmetry:** Place a `headline-lg` off-center to create visual interest.
*   **Embrace the Lavender:** Use `tertiary_container` for non-critical accents like progress bars or secondary icons to keep the "soft" brand personality.
*   **Letter Spacing:** Increase letter-spacing on `label-sm` (monospace) to 0.05rem for a "technical luxury" feel.

### Don't:
*   **Don't use pure black:** Never use #000000. Use `on_surface` (#1B1C1C) to maintain the softness of the pastel palette.
*   **Don't use 1px dividers:** If you feel the need to separate two items, add more whitespace first. If that fails, change the background color of one item.
*   **Don't over-shadow:** Avoid heavy, dark shadows. They muddy the pastel blue and lavender tones, making the design look "dirty."