import { AdminPage } from './pages/admin/AdminPage';
import { AppRedirect } from './pages/app/AppRedirect';
import { HomeRedesign } from './pages/home/HomeRedesign';
import { Header } from './components/layout/Header';
import { ManualEntry } from './pages/manual/ManualEntry';

export default function App() {
  // Simple routing based on pathname
  const isAppRedirectPage = window.location.pathname === '/app';
  const isAdminPage = window.location.pathname.includes('/admin');
  const isManualEntryPage = window.location.pathname.includes('/manual');

  if (isAppRedirectPage) {
    return <AppRedirect />;
  }

  return (
    <div className="min-h-screen bg-app text-primary">
      <Header />
      {isAdminPage ? <AdminPage /> : isManualEntryPage ? <ManualEntry /> : <HomeRedesign />}
    </div>
  );
}