You are a senior UI/UX designer. Create a complete visual design system 
and frontend layout for a mobile application.

## COLOR PALETTE (strictly follow these hex values)
- Primary Dark:     #5D5C61  (charcoal gray — headers, nav bars)
- Accent Teal:      #379683  (interactive elements, highlights)
- Mid Blue-Gray:    #7395AE  (secondary buttons, cards, dividers)
- Deep Steel Blue:  #557A95  (primary buttons, active states)
- Warm Taupe:       #B1A296  (backgrounds, subtle fills, placeholders)

## DESIGN STYLE
- Modern flat-material hybrid with tactile depth
- All interactive elements must have volumetric appearance:
  layered box-shadows (inner + outer), subtle gradients from 
  base color +10% lightness on top to base color -10% on bottom
- Elevation system: 4 levels (0dp / 2dp / 8dp / 16dp) using 
  rgba(85, 122, 149, 0.18) shadow color
- Micro-depth on cards: top-left highlight edge 1px rgba(255,255,255,0.12),
  bottom-right shadow edge 1px rgba(0,0,0,0.18)

## TYPOGRAPHY
- Sizes: Display 28px / Title 20px / Body 15px / Caption 12px
- Weight hierarchy: 700 headings / 500 subheadings / 400 body
- Letter-spacing: -0.3px for headings, +0.1px for captions
- Text colors: #5D5C61 primary, #7395AE secondary, #B1A296 disabled

## BUTTONS
- Primary: background linear-gradient(160deg, #6088A0, #557A95),
  border-radius 14px, height 52px, 
  box-shadow: 0 4px 12px rgba(85,122,149,0.45), 
              0 1px 3px rgba(0,0,0,0.2),
              inset 0 1px 0 rgba(255,255,255,0.15)
- Secondary: background #7395AE, same radius, 
  box-shadow: 0 2px 8px rgba(115,149,174,0.35)
- Accent: background linear-gradient(160deg, #3DA690, #379683),
  box-shadow: 0 4px 14px rgba(55,150,131,0.4)
- Pressed state: inset shadow, translateY(1px), brightness(0.94)
- Disabled: background #B1A296, opacity 0.55, no shadow

## CARDS & SURFACES
- Background: #FFFFFF with opacity 0.96 or rgba(177,162,150,0.08)
- Border-radius: 18px (large cards), 12px (list items), 8px (chips)
- Border: 1px solid rgba(115,149,174,0.12)
- Shadow: 0 2px 16px rgba(85,122,149,0.12), 0 1px 4px rgba(0,0,0,0.06)
- Hover/focus: shadow intensifies, subtle scale(1.01) transform

## INPUT FIELDS
- Height: 52px, border-radius: 12px
- Background: rgba(177,162,150,0.12)
- Border: 1.5px solid rgba(115,149,174,0.2)
- Focus border: #557A95, glow: 0 0 0 3px rgba(85,122,149,0.18)
- Label: floating animation, color #7395AE when active

## NAVIGATION
- Bottom tab bar: background #5D5C61, height 72px,
  frosted-glass blur(20px) with rgba(93,92,97,0.92)
- Active tab: #379683 icon + label, pill indicator background
  rgba(55,150,131,0.18), border-radius 20px
- Inactive tab: #B1A296
- Top navigation bar: background linear-gradient(180deg, #5D5C61, #4A4A4E),
  box-shadow: 0 2px 12px rgba(0,0,0,0.2)
- Status bar area: same as nav bar color

## ICONS
- Style: rounded stroke (stroke-width 1.8px), 24x24px grid
- Active: filled variant in #379683
- Inactive: outline in #B1A296
- Functional: #557A95
- No emoji anywhere in the interface — use vector icons only

## SPACING SYSTEM
- Base unit: 4px
- Section padding: 20px horizontal, 24px vertical
- Card inner padding: 16px
- Element gaps: 8px / 12px / 16px / 24px
- Safe area: respect iOS/Android notch and bottom gesture areas

## VISUAL EFFECTS
- Separator lines: 1px, rgba(115,149,174,0.15)
- Skeleton loaders: gradient shimmer from #B1A296 to #7395AE at 30% opacity
- List items: subtle press ripple in rgba(85,122,149,0.1)
- Scroll: no visible scrollbar, fade-out at list edges
- Empty states: centered illustration area using palette colors only,
  no stock icons

## DARK / LIGHT ADAPTATION
- Light mode: page background #F4F2F0 (warm off-white)
- Dark mode: page background #2C2C2F, cards #3A3A3E,
  keep all accent colors, reduce shadow opacity by 30%

## WHAT TO DESIGN (visual only — no logic, no data, no functionality)
Produce pixel-perfect mockups / component code for:
1. Splash / onboarding screen
2. Home / dashboard screen
3. List / feed screen with cards
4. Detail / content screen
5. Form screen (inputs, dropdowns, toggles)
6. Profile / settings screen
7. Full component library:
   buttons (all states), inputs, cards, badges, 
   tabs, bottom sheet, modal dialog, toast notification,
   progress bar, toggle switch, radio, checkbox

## CONSTRAINTS

- No emoji in any part of the UI
- No lorem ipsum — use realistic short placeholder text
- Do not describe functionality, user flows, or business logic
- Focus 100% on visual appearance: colors, shapes, shadows, spacing, 
  typography rendering, and component aesthetics only
