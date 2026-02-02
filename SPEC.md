# ResiWash Frontend Redesign - Technical Implementation Plan

**Version:** 1.0  
**Date:** January 11, 2026  
**Target:** Mobile-first laundry monitoring interface with brutalist-utilitarian aesthetic  
**Developer Handover Document**

---

## Executive Summary

Redesign ResiWash frontend from generic Mantine UI to a scannable, information-dense dashboard optimized for quick glance and planning ahead use cases. Replace component library with Shadcn/ui + Tailwind for full styling control while maintaining accessibility.

**Key Goals:**
- Instant machine availability scanning (< 2 seconds to understand status)
- Mobile-first responsive design
- Dark/light mode with seamless switching
- Zero decorative friction - brutalist utility aesthetic

---

## Design Philosophy

### Visual Language
**Aesthetic:** Brutalist-utilitarian information board (Airport departure board meets Japanese train station signage)

**Core Principles:**
1. **Hierarchy through scale** - Important info dominates visually
2. **Status through color** - No reading required for understanding state
3. **Density without clutter** - Tight spacing with strong grid structure
4. **Motion for updates** - Subtle animations indicate live data changes

**Refinement Level:** 6/10 - Distinctive but tasteful, clearly custom-designed

---

## Technology Stack Changes

### Remove
- `@mantine/core` (component library)
- `@mantine/notifications` (notification system)
- Generic fonts (Open Sans, Poppins)

### Add
```json
{
  "dependencies": {
    "@radix-ui/react-*": "^1.x",           // Headless UI primitives
    "class-variance-authority": "^0.7.x",  // Variant management
    "clsx": "^2.x",                         // Conditional classnames
    "tailwind-merge": "^2.x",               // Tailwind class merging
    "framer-motion": "^11.x",               // Animation library
    "react-hot-toast": "^2.x",              // Lightweight toast notifications
    "vaul": "^0.9.x",                       // Mobile bottom sheet
    "lucide-react": "^0.x"                  // Icon library
  },
  "devDependencies": {
    "tailwindcss": "^3.x",
    "@tailwindcss/typography": "^0.5.x",
    "autoprefixer": "^10.x",
    "postcss": "^8.x"
  }
}
```

### Font Loading
```html
<!-- Add to index.html -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600;700&family=Work+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
```

---

## Design System

### Typography Scale
```typescript
// tailwind.config.js - fontFamily
{
  sans: ['Work Sans', 'system-ui', 'sans-serif'],
  mono: ['IBM Plex Mono', 'monospace'],
}

// Usage patterns:
// Display: font-sans font-bold text-7xl (64px) - Machine count
// Heading: font-sans font-bold text-2xl (24px) - Room names
// Body: font-sans font-medium text-base (16px) - Machine labels
// Caption: font-mono font-regular text-xs (12px) - Timestamps
```

### Color System
```typescript
// tailwind.config.js - extend.colors
{
  // Dark mode (primary)
  dark: {
    bg: '#0a0a0a',
    surface: '#1a1a1a',
    border: '#2a2a2a',
    text: {
      primary: '#ffffff',
      secondary: '#888888',
    },
  },
  // Light mode
  light: {
    bg: '#ffffff',
    surface: '#f5f5f5',
    border: '#e0e0e0',
    text: {
      primary: '#0a0a0a',
      secondary: '#666666',
    },
  },
  // Status colors
  status: {
    available: '#00ff88',
    'available-dark': '#00cc6a',
    inUse: '#ff3366',
    'inUse-dark': '#cc2952',
    finishing: '#ffaa00',
    'finishing-dark': '#cc8800',
    issues: '#666666',
    unknown: '#444444',
  },
  // Accent
  accent: {
    dark: '#00ff88',
    light: '#0066ff',
  },
}
```

### Spacing & Layout
```typescript
// Mobile-first breakpoints
{
  sm: '640px',   // Small tablets
  md: '768px',   // Tablets
  lg: '1024px',  // Desktop
  xl: '1280px',  // Large desktop
}

// Grid system for machine cells
// Mobile: 3 columns (W1, W2, W3)
// Tablet: 4 columns
// Desktop: 5-6 columns
```

---

## Component Architecture

### New Component Structure
```
src/
├── components/
│   ├── ui/                          # Shadcn/ui primitives
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── sheet.tsx               # Bottom sheet (mobile)
│   │   ├── tabs.tsx
│   │   └── toggle.tsx
│   │
│   ├── layout/
│   │   ├── Header.tsx              # Logo + theme toggle
│   │   ├── Container.tsx           # Max-width wrapper
│   │   └── ThemeSwitcher.tsx       # Dark/light toggle
│   │
│   ├── room/
│   │   ├── RoomCard.tsx            # Main room display card
│   │   ├── RoomHeader.tsx          # Room name + availability count
│   │   ├── MachineGrid.tsx         # Grid of machine cells
│   │   └── MachineCell.tsx         # Individual machine status
│   │
│   ├── machine/
│   │   ├── MachineDetailSheet.tsx  # Bottom sheet with details
│   │   ├── MachineTimeline.tsx     # Status history (reuse existing)
│   │   └── StatusBadge.tsx         # Status indicator component
│   │
│   └── location/
│       ├── LocationSelector.tsx    # Chip-based room selector
│       └── QuickRoomToggle.tsx     # Saved rooms chips
│
├── hooks/
│   ├── useTheme.ts                 # Dark/light mode state
│   ├── useAutoRefresh.ts           # Polling logic
│   └── useMachineStatus.ts         # Status color mapping
│
├── lib/
│   ├── utils.ts                    # cn() helper, etc.
│   └── animations.ts               # Framer Motion variants
│
└── styles/
    ├── globals.css                 # Tailwind imports + custom CSS
    └── animations.css              # Keyframe animations
```

---

## Implementation Phases

### Phase 1: Foundation (Day 1-2)
**Goal:** Set up new tech stack and design system

#### Tasks:
1. **Install dependencies**
   ```bash
   npm install tailwindcss autoprefixer postcss
   npm install @radix-ui/react-slot @radix-ui/react-tabs @radix-ui/react-dialog
   npm install class-variance-authority clsx tailwind-merge
   npm install framer-motion react-hot-toast vaul lucide-react
   ```

2. **Configure Tailwind**
   - Create `tailwind.config.js` with design tokens
   - Set up `postcss.config.js`
   - Update `src/styles/globals.css` with base styles
   - Add CSS variables for theme switching

3. **Create utility functions**
   - `lib/utils.ts`: `cn()` helper for classname merging
   - `lib/animations.ts`: Framer Motion animation variants
   - `hooks/useTheme.ts`: Theme state management with localStorage

4. **Set up Shadcn/ui base components**
   - Button, Card, Sheet, Tabs, Toggle
   - Configure `components.json` for shadcn CLI
   - Customize components with design system colors

**Deliverables:**
- ✅ Tailwind configured and working
- ✅ Theme switcher functional
- ✅ Base UI components installed
- ✅ Typography and colors applied globally

---

### Phase 2: Core Components (Day 3-4)
**Goal:** Build new machine status display components

#### Tasks:

1. **StatusBadge Component**
   ```typescript
   // Replaces: src/components/mini/StatusIndicator.tsx
   
   interface StatusBadgeProps {
     status: MachineStatus;
     size?: 'sm' | 'md' | 'lg';
     showPulse?: boolean; // Animation on status change
   }
   
   // Features:
   // - Color-coded squares (not circles)
   // - Size variants (12px, 16px, 20px)
   // - Pulse animation on change (Framer Motion)
   // - Accessible (aria-label with status text)
   ```

2. **MachineCell Component**
   ```typescript
   // New component - replaces card-based machine display
   
   interface MachineCellProps {
     machine: MachineStatusOverview;
     onClick: () => void;
   }
   
   // Layout:
   // ┌─────────┐
   // │ W1   🟢 │  ← Label + status badge
   // │ 2m      │  ← Time since update
   // └─────────┘
   
   // Features:
   // - Monospace font for labels
   // - Tap/click to expand details
   // - Hover state (desktop)
   // - Status glow on change (keyframe animation)
   ```

3. **MachineGrid Component**
   ```typescript
   // Replaces: Current Stack in SavedLocation.tsx
   
   interface MachineGridProps {
     machines: MachineStatusOverview[];
     onMachineClick: (machineId: number) => void;
   }
   
   // Layout: CSS Grid
   // grid-cols-3 sm:grid-cols-4 lg:grid-cols-5
   // gap-2 sm:gap-3
   
   // Features:
   // - Responsive columns
   // - Stagger animation on load (Framer Motion)
   // - Auto-refresh pulse on data change
   ```

4. **RoomCard Component**
   ```typescript
   // Replaces: SavedLocation component
   
   interface RoomCardProps {
     areaId: number;
     roomId: number;
     machines: MachineStatusOverview[];
     isPinned?: boolean; // Primary saved room
   }
   
   // Layout:
   // ╔═══════════════════════════════════╗
   // ║ FLOOR 3 LAUNDRY                   ║
   // ║ 4/7 AVAILABLE                     ║  ← 48px bold
   // ║ ━━━━━━━━━━                        ║  ← Progress bar
   // ║                                   ║
   // ║ [MachineGrid]                     ║
   // ║                                   ║
   // ║ Updated 12s ago                   ║
   // ╚═══════════════════════════════════╝
   
   // Features:
   // - Hero availability count
   // - Progress bar (available/total ratio)
   // - Collapsible (if not pinned)
   // - Timestamp in monospace
   ```

5. **MachineDetailSheet Component**
   ```typescript
   // Replaces: Collapse expand in MachineDetails.tsx
   // Uses: Vaul bottom sheet (mobile) or Radix Dialog (desktop)
   
   interface MachineDetailSheetProps {
     machine: MachineStatusOverview;
     isOpen: boolean;
     onClose: () => void;
   }
   
   // Content:
   // - Large status badge + label
   // - "Last changed: X mins ago"
   // - Timeline component (reuse existing)
   // - Close button
   
   // Features:
   // - Slide up animation (400ms ease-out)
   // - Backdrop blur
   // - Swipe to close (mobile)
   ```

**Deliverables:**
- ✅ All 5 new components built and tested
- ✅ Responsive layouts working on mobile/desktop
- ✅ Animations implemented with Framer Motion
- ✅ Accessibility attributes added

---

### Phase 3: Layout & Navigation (Day 5)
**Goal:** Replace top-level page structure and navigation

#### Tasks:

1. **Header Component**
   ```typescript
   // Replaces: Generic Mantine Container header
   
   // Layout:
   // ┌────────────────────────────────────┐
   // │ ResiWash          [☀️/🌙] [Admin] │
   // └────────────────────────────────────┘
   
   // Features:
   // - Fixed position (sticky on mobile)
   // - Logo/brand (font-sans font-bold text-xl)
   // - Theme toggle button (right)
   // - Admin link (auth-gated, far right)
   ```

2. **LocationSelector Component Redesign**
   ```typescript
   // Replaces: Accordion-based selector in LocationSelector.tsx
   
   // Layout:
   // ┌─────────────────────────────────────┐
   // │ YOUR ROOMS                          │
   // │ [Floor 3 ×] [Floor 5 ×] [+ Add]    │ ← Chips
   // └─────────────────────────────────────┘
   
   // Features:
   // - Horizontal scroll chips (mobile)
   // - Remove chip with × button
   // - "+ Add" opens bottom sheet with room picker
   // - Persist to localStorage
   ```

3. **Home Page Restructure**
   ```typescript
   // Update: src/pages/home/Home.tsx
   
   // New layout:
   // 1. Header (fixed)
   // 2. LocationSelector (sticky below header)
   // 3. Primary room (pinned, always visible)
   // 4. Other saved rooms (scrollable)
   // 5. "Add more rooms" CTA (if < 3 saved)
   
   // Remove:
   // - Alert banners (too much visual noise)
   // - Welcome title (unnecessary)
   // - Collapse for no locations (just show empty state)
   ```

**Deliverables:**
- ✅ Header with theme switcher working
- ✅ Chip-based location selector implemented
- ✅ Home page restructured with new layout
- ✅ Empty states designed (no saved rooms)

---

### Phase 4: Animations & Polish (Day 6)
**Goal:** Add motion design and micro-interactions

#### Animations to Implement:

1. **Page Load (Stagger)**
   ```typescript
   // Framer Motion: staggerChildren
   // Each RoomCard fades in with 100ms delay
   
   const containerVariants = {
     hidden: { opacity: 0 },
     visible: {
       opacity: 1,
       transition: {
         staggerChildren: 0.1
       }
     }
   };
   
   const itemVariants = {
     hidden: { opacity: 0, y: 20 },
     visible: { opacity: 1, y: 0 }
   };
   ```

2. **Status Change (Glow Pulse)**
   ```css
   /* globals.css */
   @keyframes statusGlow {
     0%, 100% {
       box-shadow: 0 0 0 rgba(var(--status-color), 0);
     }
     50% {
       box-shadow: 0 0 20px rgba(var(--status-color), 0.8),
                   0 0 40px rgba(var(--status-color), 0.4);
     }
   }
   
   .status-changed {
     animation: statusGlow 1s ease-in-out;
   }
   ```

3. **Sheet Transitions**
   ```typescript
   // Vaul bottom sheet config
   <Sheet>
     <SheetContent
       className="transition-transform duration-400 ease-out"
     >
       {/* Content */}
     </SheetContent>
   </Sheet>
   ```

4. **Theme Switch Transition**
   ```css
   /* Smooth color transitions on theme change */
   * {
     transition: background-color 200ms ease,
                 color 200ms ease,
                 border-color 200ms ease;
   }
   ```

5. **Auto-Refresh Indicator**
   ```typescript
   // Subtle shimmer on updated values
   // Trigger on data refetch completion
   
   const shimmerVariants = {
     initial: { opacity: 0.5 },
     animate: {
       opacity: [0.5, 1, 0.5],
       transition: { duration: 0.6 }
     }
   };
   ```

**Deliverables:**
- ✅ All animations implemented and performant
- ✅ Status change detection triggers glow
- ✅ Smooth theme switching
- ✅ No layout shift during animations

---

### Phase 5: Responsive & Accessibility (Day 7)
**Goal:** Test and polish across devices and screen readers

#### Tasks:

1. **Responsive Testing**
   - Mobile (320px - 640px): Single column, 3-col grid
   - Tablet (641px - 1024px): 2 columns, 4-col grid
   - Desktop (1025px+): 3 columns, 5-col grid
   - Test on real devices (iOS Safari, Android Chrome)

2. **Accessibility Audit**
   ```typescript
   // Add ARIA labels
   <button aria-label={`View details for ${machineName}`}>
   <div role="status" aria-live="polite">4 machines available</div>
   
   // Keyboard navigation
   // - Tab through machine cells
   // - Enter/Space to open details
   // - Esc to close sheet
   
   // Color contrast check (WCAG AA)
   // - Status colors against backgrounds
   // - Text against backgrounds
   ```

3. **Loading States**
   ```typescript
   // Skeleton loaders for:
   // - Room cards (initial load)
   // - Machine grid (refetch)
   // - Detail sheet (opening)
   
   // Use Framer Motion layout animations
   <motion.div layout />
   ```

4. **Error States**
   ```typescript
   // Network error: Toast notification
   // Empty state: "No machines found"
   // Stale data: Gray overlay with "Offline" badge
   ```

5. **Performance Optimization**
   - React.memo on MachineCell (avoid re-renders)
   - useMemo for machine sorting/filtering
   - Lazy load detail sheet component
   - Optimize Framer Motion animations (GPU acceleration)

**Deliverables:**
- ✅ Responsive layouts tested on 3+ devices
- ✅ WCAG AA accessibility compliance
- ✅ Loading and error states implemented
- ✅ Performance metrics (Lighthouse score 90+)

---

## File-by-File Migration Map

### Delete
```
src/components/mini/StatusIndicator.tsx       → Replaced by StatusBadge
src/components/machine-details/MachineDetails.tsx → Replaced by MachineDetailSheet
src/components/location-selector/LocationSelector.tsx → Redesigned version
src/components/saved-locations-wrapper/SavedLocationsWrapper.tsx → Simplified
```

### Modify
```
src/App.tsx
  - Remove Mantine imports
  - Add Header component
  - Add theme provider

src/main.tsx
  - Remove MantineProvider
  - Remove Mantine theme config
  - Add Tailwind globals import
  - Add Toaster from react-hot-toast

src/pages/home/Home.tsx
  - Remove Alert banners
  - Remove Title component
  - Restructure with new components
  - Add primary room pin logic

src/components/saved-location/SavedLocation.tsx
  - Convert to RoomCard component
  - Replace Stack/Group with Tailwind
  - Use new MachineGrid

src/components/timeline/Timeline.tsx
  - Keep logic, restyle with Tailwind
  - Update colors to match design system
```

### Create New
```
src/components/ui/                  # Shadcn components
src/components/layout/Header.tsx
src/components/layout/ThemeSwitcher.tsx
src/components/room/RoomCard.tsx
src/components/room/MachineGrid.tsx
src/components/room/MachineCell.tsx
src/components/machine/MachineDetailSheet.tsx
src/components/machine/StatusBadge.tsx
src/components/location/QuickRoomToggle.tsx
src/hooks/useTheme.ts
src/lib/utils.ts
src/lib/animations.ts
src/styles/animations.css
tailwind.config.js
postcss.config.js
```

---

## State Management Notes

### Theme State
```typescript
// hooks/useTheme.ts
// Store in localStorage: 'theme' = 'light' | 'dark'
// Default to 'dark' mode
// Update <html> class and CSS variables on change
```

### Auto-Refresh Logic
```typescript
// Keep existing useQuery refetchInterval
// Add visual indicator when refetching
// Detect changed machines and trigger glow animation

const previousData = usePrevious(machineData);
const changedMachines = detectChanges(previousData, machineData);

useEffect(() => {
  changedMachines.forEach(id => {
    triggerGlowAnimation(id);
  });
}, [changedMachines]);
```

### Location Selection
```typescript
// Persist to localStorage: 'savedRooms'
// Format: { [areaId: number]: number[] } (same as current)
// Add "pinned room" concept: first saved room is primary
```

---

## Design System Reference

### Component Variants (CVA Pattern)
```typescript
// Example: StatusBadge variants
import { cva } from 'class-variance-authority';

const statusVariants = cva(
  'rounded-sm', // base
  {
    variants: {
      status: {
        AVAILABLE: 'bg-status-available',
        IN_USE: 'bg-status-inUse',
        FINISHING: 'bg-status-finishing',
        HAS_ISSUES: 'bg-status-issues',
        UNKNOWN: 'bg-status-unknown',
      },
      size: {
        sm: 'w-3 h-3',
        md: 'w-4 h-4',
        lg: 'w-5 h-5',
      },
    },
    defaultVariants: {
      status: 'UNKNOWN',
      size: 'md',
    },
  }
);
```

### Animation Tokens
```typescript
// lib/animations.ts
export const spring = {
  type: 'spring',
  stiffness: 300,
  damping: 30,
};

export const fadeInUp = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: 20 },
};

export const staggerContainer = {
  animate: {
    transition: {
      staggerChildren: 0.1,
    },
  },
};
```

---

## Testing Checklist

### Functional Testing
- [ ] Machine status colors display correctly
- [ ] Tap/click machine opens detail sheet
- [ ] Detail sheet shows timeline and updates
- [ ] Location selector adds/removes rooms
- [ ] Saved rooms persist after refresh
- [ ] Theme toggle switches light/dark
- [ ] Theme persists after refresh
- [ ] Auto-refresh updates machine states
- [ ] Timestamp formats correctly (date-fns)
- [ ] Empty states show when no rooms saved

### Visual Testing
- [ ] Typography hierarchy clear and readable
- [ ] Colors match design system (all 5 status states)
- [ ] Spacing consistent across components
- [ ] Grid layout responsive on mobile/tablet/desktop
- [ ] Animations smooth (60fps, no jank)
- [ ] Status glow triggers on data change
- [ ] Theme transition smooth (no flash)
- [ ] Loading skeletons match final layout

### Accessibility Testing
- [ ] Keyboard navigation works (Tab, Enter, Esc)
- [ ] Screen reader announces status changes
- [ ] Color contrast passes WCAG AA (4.5:1)
- [ ] Focus indicators visible and clear
- [ ] Touch targets ≥44px (mobile)
- [ ] No animation for prefers-reduced-motion users

### Performance Testing
- [ ] Lighthouse Performance score ≥90
- [ ] First Contentful Paint <1.5s
- [ ] Time to Interactive <3s
- [ ] Bundle size <200kb (gzipped)
- [ ] No unnecessary re-renders (React DevTools)
- [ ] Smooth scrolling with 20+ rooms

---

## Known Limitations & Future Enhancements

### Out of Scope (Current Implementation)
- ❌ Historical data / usage patterns (no backend support yet)
- ❌ Push notifications (needs service worker + backend)
- ❌ Estimated time remaining (needs ML or cycle tracking)
- ❌ Room images (not using imageUrl fields)
- ❌ Multi-language support (English only)

### Future Considerations
1. **Planning Ahead Mode:** Add when historical event data is sufficient
2. **Telegram Bot Integration:** Coordinate with notification system
3. **PWA Features:** Offline support, install prompt, app icons
4. **Admin Panel Redesign:** Apply same design language to admin views
5. **Machine Icons:** Consider washer/dryer emoji differentiation (💧/🔥)

---

## Rollout Strategy

### Development Environment
```bash
# Create feature branch
git checkout -b redesign/frontend-v2

# Install dependencies
npm install [packages from tech stack section]

# Set up Tailwind
npx tailwindcss init -p

# Run dev server
npm run dev
```

### Staging Deployment
1. Deploy to separate subdomain (e.g., `beta.resiwash.app`)
2. Test with 5-10 beta users
3. Collect feedback on information density and usability
4. Iterate on spacing/sizing if needed

### Production Rollout
- **Option A (Flag):** Feature flag to toggle old/new UI
- **Option B (Hard Switch):** Deploy directly to replace current UI
- **Option C (Gradual):** Show new UI to 10% → 50% → 100% of users

**Recommendation:** Option B (Hard Switch) - Small user base, low risk

---

## Success Metrics

### Quantitative
- **Bounce rate** should decrease (users finding info faster)
- **Average session duration** should decrease (faster task completion)
- **Mobile usage** should increase (better mobile UX)
- **Theme toggle usage** (track light vs dark mode adoption)

### Qualitative
- User feedback: "Easier to scan at a glance"
- Net Promoter Score (NPS) improvement
- Reduced support requests about finding machine status

---

## Developer Handoff Notes

### Code Style
- Use functional components + hooks (no classes)
- TypeScript strict mode enabled
- Prettier for formatting (2 spaces, single quotes)
- ESLint rules for React best practices

### Git Workflow
```bash
# Branch naming
redesign/component-name

# Commit messages
feat: add MachineGrid component with stagger animation
fix: correct status color for FINISHING state
style: update RoomCard spacing for mobile

# PR checklist
- [ ] Tests pass
- [ ] Lighthouse score ≥90
- [ ] Accessibility audit complete
- [ ] Responsive on 3+ devices
- [ ] Code reviewed by 1+ developer
```

### Documentation
- Add JSDoc comments to all components
- Document props interfaces with descriptions
- Include usage examples in Storybook (if available)
- Update README with new component structure

---

## Questions for Product Review

1. **Primary Room Logic:** Should the first saved room always be "pinned" or allow manual selection?

2. **Refresh Rate:** Current polling interval? Should we make it configurable? (Currently managed by React Query)

3. **Empty State CTA:** When no rooms saved, should we show popular rooms or require manual selection?

4. **Machine Ordering:** Should we sort by status (available first) or by machine ID (W1, W2, D1)?

5. **Offline Behavior:** Show last known state with "outdated" indicator or hide entirely?

6. **Desktop Layout:** 3-column or 2-column for rooms on large screens?

---

## Timeline Estimate

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| 1. Foundation | 2 days | Tech stack + design system setup |
| 2. Core Components | 2 days | 5 new components built |
| 3. Layout & Nav | 1 day | Page restructure complete |
| 4. Animations | 1 day | Motion design implemented |
| 5. Polish & A11y | 1 day | Testing and refinement |
| **Total** | **7 days** | Production-ready redesign |

**Assumptions:**
- Single developer, full-time work
- No major API changes required
- Designs approved without iteration

**Buffer:** Add 2-3 days for QA, bug fixes, and stakeholder feedback

---

## Contact & Support

**Design Questions:** Review Figma mockups (if created) or refer to this document  
**Technical Blockers:** Check existing codebase patterns in `src/hooks/query/` for API integration  
**Accessibility:** Use axe DevTools browser extension for automated checks  

**Key Files to Reference:**
- Current data types: `src/types/datatypes.ts`
- API hooks: `src/hooks/query/`
- Existing animations: Look for Mantine transition props to understand current user expectations

---

**Document Version:** 1.0  
**Last Updated:** January 11, 2026  
**Next Review:** After Phase 1 completion
