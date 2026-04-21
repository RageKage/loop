# Loop — Design Language

Target style: "Editorial Archive" — minimalist, high-contrast, editorial/zine-inspired. Stark UI that lets event posters do the visual heavy lifting. Avoids the "iOS app template" look.

## Colors

- Primary: #1A1A1B (warm off-black)
- Background: #FFFFFF (pure white)
- Accent: #E8B923 (warm Kodak yellow)
- Success / Free: #4A7C59 (muted filmic green)
- Destructive: #D9534F (faded editorial red)
- Text primary: #1A1A1B
- Text secondary: #737373
- Border (when needed): #E5E5E5

## Typography

- Title font: Manrope Bold — event titles, screen titles
- Body font: Inter Regular — descriptions, paragraphs
- Monospace: JetBrains Mono Medium — dates, times, distances, prices, category tags (metadata)

All fonts available via Google Fonts. Plan: bundle as .ttf in the app, register in Info.plist.

## Corner radius scale

- Small (buttons, tags): 2px
- Medium (cards, images): 6px
- Keep radii tight. No 12-16px rounded corners. Those are the iOS template tell.

## Spacing scale

- Tight: 4pt (between a title and its monospace metadata)
- Regular: 16pt (standard card padding)
- Loose: 40pt (between distinct sections)

## Traps to avoid

- NO drop shadows on cards or sheets
- NO glassmorphism / translucent blurs
- NO large rounded corners
- NO decorative gradients
- If elements need separation, use a 1px #E5E5E5 border OR generous whitespace. Never soft shadows.

## Hand-mixed category colors

Replace the current iOS-default SwiftUI colors on category icons with these hand-mixed pastels:

- fitness: #B5D9B5 (soft sage)
- books: #D4B59E (warm tan)
- social: #B5C7D9 (dusty blue)
- music: #D9B5D4 (soft orchid)
- food: #E5C5A8 (soft peach)
- outdoors: #A8C9B5 (muted eucalyptus)
- kids: #F0C5CF (dusty pink)
- other: #C5C5C5 (warm gray)

Each category gets its pastel as background tint with the near-black #1A1A1B as icon/text foreground. High contrast, editorial feel.

## Implementation phase

Phase 6. Full pass across all views. Estimated scope: 15-20 files touched. Will be one focused session with a clear before/after.

Do NOT implement any of this now. Just write the file.
