import { ShoppingCart, User, LogOut, Home, Package, LayoutDashboard } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useCart } from '../contexts/CartContext';

interface NavbarProps {
  currentPage: string;
  onNavigate: (page: string) => void;
}

export const Navbar = ({ currentPage, onNavigate }: NavbarProps) => {
  const { user, profile, signOut, isAdmin } = useAuth();
  const { getTotalItems } = useCart();

  return (
    <nav className="bg-white shadow-md sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center space-x-8">
            <h1
              className="text-2xl font-bold text-gray-900 cursor-pointer"
              onClick={() => onNavigate('home')}
            >
              CloudStore
            </h1>
            <button
              onClick={() => onNavigate('home')}
              className={`flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium ${
                currentPage === 'home'
                  ? 'text-blue-600 bg-blue-50'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <Home size={18} />
              <span>Home</span>
            </button>
            {user && (
              <button
                onClick={() => onNavigate('orders')}
                className={`flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium ${
                  currentPage === 'orders'
                    ? 'text-blue-600 bg-blue-50'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                <Package size={18} />
                <span>Orders</span>
              </button>
            )}
            {isAdmin && (
              <button
                onClick={() => onNavigate('admin')}
                className={`flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium ${
                  currentPage === 'admin'
                    ? 'text-blue-600 bg-blue-50'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                <LayoutDashboard size={18} />
                <span>Admin</span>
              </button>
            )}
          </div>

          <div className="flex items-center space-x-4">
            {user && (
              <button
                onClick={() => onNavigate('cart')}
                className="relative p-2 text-gray-700 hover:bg-gray-100 rounded-full"
              >
                <ShoppingCart size={24} />
                {getTotalItems() > 0 && (
                  <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                    {getTotalItems()}
                  </span>
                )}
              </button>
            )}

            {user ? (
              <div className="flex items-center space-x-3">
                <div className="flex items-center space-x-2">
                  <User size={20} className="text-gray-600" />
                  <div className="text-sm">
                    <p className="font-medium text-gray-900">{profile?.full_name}</p>
                    {isAdmin && (
                      <p className="text-xs text-blue-600 font-semibold">Admin</p>
                    )}
                  </div>
                </div>
                <button
                  onClick={() => signOut()}
                  className="flex items-center space-x-1 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-md"
                >
                  <LogOut size={18} />
                  <span>Logout</span>
                </button>
              </div>
            ) : (
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => onNavigate('login')}
                  className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-md"
                >
                  Login
                </button>
                <button
                  onClick={() => onNavigate('register')}
                  className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md"
                >
                  Register
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
};
