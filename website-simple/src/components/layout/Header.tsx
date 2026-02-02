import { ThemeSwitcher } from './ThemeSwitcher';
import { useAuth } from '@/context/useAuth';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface HeaderProps {
  className?: string;
}

/**
 * Header component for the application
 * Layout:
 * ┌────────────────────────────────────┐
 * │ ResiWash          [☀️/🌙] [Admin] │
 * └────────────────────────────────────┘
 */
export function Header({ className }: HeaderProps) {
  const { currentUser } = useAuth();
  const isAdminPage = window.location.pathname.includes('/admin');

  const handleNavigate = (path: string) => {
    window.location.href = path;
  };

  return (
    <header
      className={cn(
        'sticky top-0 z-50 w-full border-b backdrop-blur',
        className
      )}
      style={{
        borderColor: 'var(--border-color)',
        backgroundColor: 'rgba(var(--bg-rgb, 23, 23, 23), 0.95)',
      }}
    >
      <div className="container mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
        {/* Logo */}
        <button
          onClick={() => handleNavigate('/')}
          className="font-brand !text-[1.7rem] sm:!text-[2.1rem] !leading-none !font-extrabold tracking-tight text-primary hover:text-accent transition-colors"
        >
          ResiWash
        </button>

        {/* Right side: Theme switcher + links */}
        <div className="flex items-center gap-2">
          <ThemeSwitcher />
          <Button asChild variant="outline" size="icon">
            <a
              href="https://github.com/HollaG/resiwash"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="ResiWash on GitHub"
              title="GitHub"
            >
              <svg
                viewBox="0 0 16 16"
                aria-hidden="true"
                className="h-5 w-5"
                fill="currentColor"
              >
                <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8Z" />
              </svg>
            </a>
          </Button>
          {currentUser && !isAdminPage && (
            <Button variant="outline" size="sm" onClick={() => handleNavigate('/admin')}>
              Admin
            </Button>
          )}
          {isAdminPage && (
            <Button variant="outline" size="sm" onClick={() => handleNavigate('/')}>
              Home
            </Button>
          )}
        </div>
      </div>
    </header>
  );
}
