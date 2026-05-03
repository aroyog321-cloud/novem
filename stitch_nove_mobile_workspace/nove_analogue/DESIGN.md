# Design System: The Tactile Archive

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Curator"**

This design system is a bridge between the tactile heritage of physical stationery and the frictionless speed of modern software. We are not building a "utility tool"; we are crafting a sanctuary for thought. The "Digital Curator" philosophy rejects the clinical, hyper-efficient grids of standard productivity apps in favor of an **Editorial Layout**—one that prizes intentional white space, rhythmic asymmetry, and a sense of "object-hood."

To break the "template" look, we employ **Overlapping Surfaces** and **Varying Proportions**. A note isn't just a row in a list; it is a physical card resting on a cream-colored desk. By using large-scale serif typography against minimalist geometric UI, we create a high-contrast environment that feels both authoritative and personal.

---

## 2. Colors & Tonal Depth
Our palette is rooted in organic materials—paper, clay, and leather. 

### The "No-Line" Rule
**Strict Mandate:** 1px solid borders are prohibited for sectioning or containment. 
Boundaries must be defined through **Background Color Shifts**. For example, a `surface-container-low` note list should sit on a `surface` background. The contrast is felt, not seen as a line.

### Surface Hierarchy & Nesting
Treat the UI as a series of stacked, fine-paper sheets. Use the Material-inspired tokens to create a sense of physical layering:
- **Surface (Base):** The "Desk" (#FCF9F3).
- **Surface-Container-Low:** Secondary areas or side-scrolling regions.
- **Surface-Container-Highest:** The active note or focused card.
*Design Note: When nesting an element, always move one "tier" up or down to define the container. Never use the same hex code for a parent and its child.*

### The Glass & Gradient Rule
To move beyond a flat "flat design" aesthetic, use **Glassmorphism** for floating action menus or navigation bars. Use semi-transparent versions of `surface` or `surface-bright` with a 20px backdrop blur. 
**Signature Gradients:** For Primary CTAs, use a subtle linear gradient from `primary` (#9F2D14) to `primary-container` (#C0452A) at a 135-degree angle to give the "Terracotta" a soft, fired-clay glow.

---

## 3. Typography
The typographic system is a dialogue between the "Academic" (Serif) and the "Efficient" (Sans).

*   **Display & Headlines (Lora):** These are our "Editorial" voices. Use `display-lg` for empty states or journal headers. The serif nature conveys a premium, literary feel.
*   **Title & UI (Plus Jakarta Sans/DM Sans):** Used for navigation, buttons, and system labels. These are clean and geometric to ensure the app feels modern and functional.
*   **The Editor Body (Caveat):** Reserved exclusively for "Handwritten" notes and sticky-note content. It provides the human touch essential to the "Analogue" brand identity.

| Role | Token | Font | Size | Weight |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Lora | 3.5rem | 500 |
| **Headline** | `headline-md` | Lora | 1.75rem | 600 |
| **Title** | `title-md` | Plus Jakarta | 1.125rem | 500 |
| **Body (UI)** | `body-lg` | Plus Jakarta | 1rem | 400 |
| **Editor** | `body-editor` | Caveat | 1.25rem | 400 |

---

## 4. Elevation & Depth
In this system, depth is a result of light and shadow, not lines.

*   **Tonal Layering:** Achieve 90% of your hierarchy by stacking `surface-container` tiers. 
*   **Ambient Shadows:** For floating cards (like the "Folded Corner" cards), use a "Soft-Focus" shadow. 
    *   *Shadow Specs:* `0px 12px 32px rgba(49, 49, 45, 0.06)`. The color is a tinted `on-surface` (#31312D), never pure black.
*   **The Ghost Border:** If accessibility requires a border (e.g., in Dark Mode), use `outline-variant` at **15% opacity**.
*   **The Folded Corner (Signature Element):** Applied to top-left corners of specific floating cards. The "underside" of the fold should use `surface-container-highest` to suggest light hitting the back of the paper.

---

## 5. Components

### Buttons
*   **Primary:** Terracotta gradient, `full` (9999px) radius. No border.
*   **Secondary:** `surface-container-highest` background with `on-surface` text.
*   **Tertiary:** No background. `primary` text color with a `label-md` weight.

### Note Cards & Lists
*   **The Forbidden Divider:** Never use a horizontal line to separate notes. Use a 16px vertical gap (`spacing-md`) and a subtle shift from `surface` to `surface-container-low`.
*   **Note Card Radius:** 16px (`xl`).
*   **Sticky Notes:** Use the "Handwriting" font. Radius 14px (`lg`). Colors: Yellow (#F5C842), Pink (#F2C2D8), etc.

### Input Fields
*   **Styling:** No bottom line or box. Use a subtle `surface-container-lowest` fill. 
*   **Active State:** The label shifts to `primary` (Terracotta) and the background shifts to `surface-bright`.

### Signature Component: The "Journal Page"
A specialized container for long-form writing. It uses an asymmetrical margin (wider on the left, mimicking a notebook spine) and utilizes the `surface-container-lowest` color to mimic premium heavy-weight paper.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical spacing. A 32px left margin with a 16px right margin creates an editorial look.
*   **Do** lean into the Lora serif for large empty-state titles. It makes the app feel like a book.
*   **Do** use the Caveat font for any user-generated "quick thoughts."

### Don't
*   **Don't** use Material 3 "Elevation Tints" (adding primary color to surfaces). Keep surfaces neutral and warm.
*   **Don't** use pure black (#000000). Even in Dark Mode, use `Deep Warm Dark` (#1A1714) to maintain the "Leather" feel.
*   **Don't** use standard 1px dividers. If hierarchy is failing, increase white space or shift the background tone.