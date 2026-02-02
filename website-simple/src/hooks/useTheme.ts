import { useEffect, useState } from 'react';

type Theme = 'dark' | 'light';

/**
 * Hook for managing theme state with localStorage persistence
 * Default theme is 'dark' as specified in SPEC.md
 */
export function useTheme() {
  const [theme, setTheme] = useState<Theme>(() => {
    // Check localStorage for saved theme, default to 'dark'
    const saved = localStorage.getItem('theme') as Theme | null;
    return saved || 'dark';
  });

  useEffect(() => {
    const root = window.document.documentElement;
    
    // Remove both classes first
    root.classList.remove('light', 'dark');
    
    // Add the current theme class
    root.classList.add(theme);
    
    // Save to localStorage
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'));
  };

  return { theme, setTheme, toggleTheme };
}
