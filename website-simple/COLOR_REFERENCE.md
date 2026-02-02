# ResiWash Color Reference

## Dark Mode (Default)
When the app loads, you should see these colors:

### Backgrounds
- **Main background**: Very dark gray `#0a0a0a` (almost black)
- **Cards/Surface**: Dark gray `#1a1a1a` 
- **Borders**: Medium dark gray `#2a2a2a`

### Text
- **Primary text**: Pure white `#ffffff`
- **Secondary text**: Medium gray `#888888`

### Status Colors
- **Available**: Bright cyan-green `#00ff88` (vibrant, easy to spot)
- **In Use**: Hot pink/red `#ff3366`
- **Finishing**: Orange `#ffaa00`
- **Issues**: Gray `#666666`
- **Unknown**: Dark gray `#444444`

### Accent
- **Accent color**: Bright cyan-green `#00ff88` (same as Available)

---

## Light Mode
Toggle the theme with the sun/moon icon in the header. You should see:

### Backgrounds
- **Main background**: Pure white `#ffffff`
- **Cards/Surface**: Very light gray `#f5f5f5`
- **Borders**: Light gray `#e0e0e0`

### Text
- **Primary text**: Very dark gray `#0a0a0a` (almost black)
- **Secondary text**: Medium gray `#666666`

### Status Colors
(Same as dark mode - these don't change)
- **Available**: Bright cyan-green `#00ff88`
- **In Use**: Hot pink/red `#ff3366`
- **Finishing**: Orange `#ffaa00`
- **Issues**: Gray `#666666`
- **Unknown**: Dark gray `#444444`

### Accent
- **Accent color**: Blue `#0066ff` (different from dark mode)

---

## Troubleshooting

If you're not seeing these colors:

1. **Check the theme toggle**: Click the sun/moon icon in the top right
2. **Open browser DevTools** and inspect the `<html>` element
   - In dark mode: Should NOT have a `light` class
   - In light mode: Should have `class="light"`
3. **Check localStorage**: 
   ```js
   localStorage.getItem('theme')  // should return 'dark' or 'light'
   ```
4. **Force dark mode**:
   ```js
   localStorage.setItem('theme', 'dark')
   ```
   Then refresh the page

5. **Check CSS variables**:
   Open DevTools Console and run:
   ```js
   getComputedStyle(document.documentElement).getPropertyValue('--bg')
   ```
   - Dark mode: Should return `#0a0a0a`
   - Light mode: Should return `#ffffff`
