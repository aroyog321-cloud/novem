# NOVE Mobile — Product Requirements Document

## Product Identity
NOVE Mobile is a premium, offline-first personal workspace and note-taking app for Android and iOS. It is the mobile companion to the NOVE desktop app.
- **Personality:** Calm, focused, premium, analogue-inspired.
- **Signature Feature:** The Floating Companion (Android).
- **Core Principles:** Focus, Speed (Zero Latency), Offline-First, Privacy, Depth over Breadth.

## Core Features

### 1. Notes Data Model
- Content: Full plaintext.
- Title: First line of content.
- Metadata: Category tag, Color label, Pin state, Favorite state, Timestamps, Word/Char count, Read time.

### 2. All Notes Screen (Main Hub)
- Scrollable list of cards with 2-3 line previews.
- Top: App name "NOVE" (Lora Bold), subtitle "PREMIUM WORKSPACE", search bar with Cmd+K badge, horizontal category chips.
- Bottom: "New Note" FAB.
- Long-press: Bottom sheet with quick actions (Pin, Edit, Color, Delete).

### 3. Note Editor
- Full-screen writing environment.
- Background: Subtle horizontal ruled lines.
- Body Font: Caveat (handwriting-adjacent).
- Top Bar: Back, category chips, Publish button.
- Bottom Bar: Counts, color picker, pin toggle, share, focus mode toggle, read-time.

### 4. Sticky Board
- Visual brainstorming canvas with sticky-note cards in a 2-column grid.
- Colors: Sticky Yellow (#F5C842), Pink (#F2C2D8), Green (#B8E0B2), Blue (#B2CEFF).
- Bottom Input Row: Color selector, Title input, Add Note button.

### 5. Floating Companion (Android)
- 58dp Amber bubble with idle bobbing animation.
- Expands to a card with a folded-corner effect (top-left).
- Minimized strip state.

### 6. Settings
- Floating Companion toggles (Android permissions).
- Data Export (.txt format).
- Privacy statement & Version info.

## Design System Specifications

### Typography
- **Display:** Lora (Serif) - Regular, SemiBold, Bold.
- **Body/UI:** DM Sans (Geometric Sans) - Light, Regular, Medium, SemiBold.
- **Editor Body:** Caveat (Handwriting style).

### Color Palette
- **Primary:** Terracotta (#C0452A)
- **Accent:** Amber (#F5C842)
- **Base (Light):** Cream (#F5F2EC), Warm White Cards (#FEFCF8)
- **Base (Dark):** Deep Warm Dark (#1A1714), Card Dark (#242018)

### Shape & Elevation
- **Radii:** 16px (Note cards), 14px (Sticky cards), 20px (Chips).
- **Signature Shape:** Folded top-left corner on floating cards.
- **Shadows:** Soft, natural shadows (no elevation tints).
