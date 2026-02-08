import { AdminPage } from './pages/admin/AdminPage';
import { HomeRedesign } from './pages/home/HomeRedesign';
import { Header } from './components/layout/Header';
import { ManualEntry } from './pages/manual/ManualEntry';

export default function App() {
  // Simple routing based on pathname
  const isAdminPage = window.location.pathname.includes('/admin');
  const isManualEntryPage = window.location.pathname.includes('/manual');

  return (
    <div className="min-h-screen bg-app text-primary">
      <Header />
      {isAdminPage ? <AdminPage /> : isManualEntryPage ? <ManualEntry /> : <HomeRedesign />}
    </div>
  );
}