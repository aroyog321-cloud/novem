# Design System Document: The Kinetic Luminescence

## 1. Overview & Creative North Star: "The Neon Nocturne"
The Creative North Star for this design system is **The Neon Nocturne**. This concept moves away from the sterile "SaaS Blue" aesthetic into a high-energy, editorial realm that mimics the depth and vibrancy of a high-end digital gallery. 

We are moving beyond "clean" into "electric." By leveraging deep, cavernous primaries (`#0c0069`) and piercing secondary accents (`#a7238b`), we create an environment that feels premium and immersive. The system breaks the traditional grid by using intentional asymmetry, overlapping layers, and high-contrast typography scales that command attention rather than just providing information.

## 2. Colors: Tonal Depth & Vibrancy
This palette is built on high-contrast tension. The deep blues provide a stable, "infinite" background, while the magentas and pinks act as kinetic energy.

### Core Palette Roles
*   **Primary (`#0c0069` / `#1a05a2`):** Used for foundational depth. The `primary_container` is your canvas for hero sections and high-impact messaging.
*   **Secondary (`#a7238b`):** This is your functional energy. Use it for critical interactive elements and to draw the eye across the horizontal axis.
*   **Tertiary (`#3f0012` / `#ff6081`):** The "Pulse." Use these sparingly for status indicators, high-end accents, and moments of delight.
*   **Neutrals (`#fdf8fd` / `#1c1b1f`):** Our whites are not "pure" white; they are tinted with the brand’s warmth (`surface`) to ensure the high-contrast palette doesn't feel clinical.

### The "No-Line" Rule
**Explicit Instruction:** Prohibit the use of 1px solid borders for sectioning. 
Boundaries must be defined solely through background color shifts. For example, a `surface_container_low` section sitting on a `surface` background provides a sophisticated, "borderless" containment. If you feel the need for a line, use a gap in the layout instead.

### Surface Hierarchy & Nesting
Treat the UI as physical layers. Instead of a flat grid, use the surface-container tiers to create depth:
*   **Background:** `surface`
*   **Sectioning:** `surface_container_low`
*   **Interactive Cards:** `surface_container_highest`
*   **Floating Elements:** `surface_container_lowest` (creates a "lifted" paper effect).

### The "Glass & Gradient" Rule
To elevate the experience, use **Glassmorphism** for floating headers or navigation rails. Apply a semi-transparent `surface` color with a `backdrop-blur` of 20px-30px. 
**Signature Texture:** Apply a subtle linear gradient from `primary` to `primary_container` on large surfaces to give the UI a "soul" and a sense of three-dimensional illumination.

## 3. Typography: The Editorial Edge
We utilize **Plus Jakarta Sans** to provide a modern, geometric feel that remains legible at high speeds. 

*   **Display (Large/Med/Small):** These are your "statement" sizes. Use tight letter-spacing (-2%) and bold weights to create an authoritative, editorial feel.
*   **Headlines & Titles:** Used to break up content. Ensure ample vertical rhythm above and below headlines to allow the "boldness" of the color palette to breathe.
*   **Body (Large/Med/Small):** Set primarily in `on_surface` or `on_surface_variant`. Avoid pure black; use the deep navy-tinted `on_surface` to maintain the nocturnal aesthetic.
*   **Labels:** For metadata and micro-copy. Use `label-md` in uppercase with slight tracking (+5%) for a sophisticated, technical feel.

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are often a crutch for poor layout. In this system, depth is achieved through "stacking."

*   **The Layering Principle:** Place a `surface_container_lowest` card on a `surface_container_low` section. This creates a soft, natural lift without the "dirty" look of heavy drop shadows.
*   **Ambient Shadows:** When a floating effect is mandatory (e.g., Modals), shadows must be extra-diffused. Use a blur of 32px-64px with a 4%-6% opacity. The shadow color should be a tinted version of `primary` (a deep navy shadow), never neutral grey.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, it must be a **Ghost Border**: use `outline_variant` at 15% opacity. 100% opaque borders are strictly forbidden.

## 5. Components: Refined Interaction

### Buttons
*   **Primary:** Solid `primary` or a gradient of `primary` to `primary_container`. Text is `on_primary`. Shape: `md` (0.75rem) roundedness.
*   **Secondary:** `secondary_container` background with `on_secondary_container` text.
*   **Tertiary/Ghost:** No background. Use `on_surface` text. On hover, apply a subtle `surface_variant` fill.

### Chips
*   **Action Chips:** High-contrast `secondary_fixed_dim` with `on_secondary_fixed`. 
*   **Selection:** Use `primary_fixed` to indicate an active state.

### Input Fields
*   **Style:** Minimalist. No border. Use a `surface_container_high` background.
*   **Focus State:** A 2px bottom-only border using the `secondary` color. This keeps the layout "clean" while providing high-visibility feedback.

### Cards & Lists
*   **No Dividers:** Forbid the use of divider lines. Separate list items using `0.5rem` of vertical whitespace or alternating subtle background shifts between `surface` and `surface_container_low`.
*   **Interaction:** On hover, a card should transition from `surface_container` to `surface_container_highest` with a subtle scale-up (1.02x).

### Signature Component: The "Luminescent Glow"
For featured content, use a "Glow Card." This card uses a `secondary` gradient border (using the Ghost Border rule) and a very faint `secondary` ambient shadow to make the content appear as if it is emitting light.

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical layouts where one column is significantly wider than the other to create an editorial feel.
*   **Do** use the `secondary` magenta (`#a7238b`) for "Micro-Moments"—icons, underlines, and small buttons.
*   **Do** embrace negative space. If a layout feels "crowded," remove a container background rather than shrinking the text.

### Don't
*   **Don't** use 1px grey lines. They break the "Neon Nocturne" immersion.
*   **Don't** use standard "Drop Shadows." Use tonal layering or high-diffusion ambient glows.
*   **Don't** mix the `primary` blue with "true black." Always use the `on_background` navy-tinted black for text.
*   **Don't** use the `error` red for anything other than critical system failures; it clashes with the brand magentas. For warnings, use the `tertiary` palette.