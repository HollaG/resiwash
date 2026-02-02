import { AdminPage } from './pages/admin/AdminPage';
import { HomeRedesign } from './pages/home/HomeRedesign';
import { Header } from './components/layout/Header';

export default function App() {
  // Simple routing based on pathname
  const isAdminPage = window.location.pathname.includes('/admin');

  return (
    <div className="min-h-screen bg-app text-primary">
      <Header />
      {isAdminPage ? <AdminPage /> : <HomeRedesign />}
    </div>
  );
}