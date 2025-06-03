import React, { useState, useEffect, createContext, useContext } from 'react';
import { useTranslation } from 'react-i18next';
import './i18n';
import './App.css';
import LandingPage from './LandingPage';
import LanguageSelector from './LanguageSelector';

// API URL from environment variable
const API = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8000';

// Create Auth Context
const AuthContext = createContext();

// Auth Provider Component
const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [company, setCompany] = useState(null);
  const [loading, setLoading] = useState(true);
  const { i18n } = useTranslation();

  // Check if user is logged in on component mount
  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      fetchCurrentUser();
    } else {
      setLoading(false);
    }
  }, []);

  // Fetch current user data
  const fetchCurrentUser = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('token');
      
      if (!token) {
        setLoading(false);
        return;
      }
      
      const response = await fetch(`${API}/api/users/me`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (response.ok) {
        const userData = await response.json();
        setUser(userData);
        
        // Set language from user preferences
        if (userData.language) {
          i18n.changeLanguage(userData.language);
        }
        
        // Fetch company data if user belongs to a company
        if (userData.company_id) {
          const companyResponse = await fetch(`${API}/api/companies/${userData.company_id}`, {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });
          
          if (companyResponse.ok) {
            const companyData = await companyResponse.json();
            setCompany(companyData);
          }
        }
      } else {
        // If token is invalid, clear it
        localStorage.removeItem('token');
      }
    } catch (error) {
      console.error('Error fetching user data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Login function
  const login = async (email, password) => {
    try {
      const response = await fetch(`${API}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, password })
      });
      
      if (response.ok) {
        const data = await response.json();
        localStorage.setItem('token', data.access_token);
        await fetchCurrentUser();
        return { success: true };
      } else {
        const errorData = await response.json();
        return { success: false, error: errorData.detail || 'Login failed' };
      }
    } catch (error) {
      console.error('Login error:', error);
      return { success: false, error: 'Network error' };
    }
  };

  // Register company function
  const registerCompany = async (companyData) => {
    try {
      const response = await fetch(`${API}/api/companies`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(companyData)
      });
      
      if (response.ok) {
        const data = await response.json();
        localStorage.setItem('token', data.access_token);
        await fetchCurrentUser();
        return { success: true };
      } else {
        const errorData = await response.json();
        return { success: false, error: errorData.detail || 'Registration failed' };
      }
    } catch (error) {
      console.error('Registration error:', error);
      return { success: false, error: 'Network error' };
    }
  };

  // Check if user is a manager
  const isManager = user?.role === 'manager';

  // Logout function
  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('authorization');
    setUser(null);
    setCompany(null);
  };

  // Handle language change
  const handleLanguageChange = async (langCode) => {
    try {
      if (user?.id) {
        const response = await fetch(`${API}/api/users/${user.id}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          },
          body: JSON.stringify({ language: langCode })
        });

        if (response.ok) {
          console.log('Language preference updated successfully');
        } else {
          console.error('Failed to update language preference');
        }
      }
    } catch (error) {
      console.error('Error updating language preference:', error);
    }
  };

  return (
    <AuthContext.Provider value={{ 
      user, 
      company, 
      login, 
      registerCompany, 
      logout, 
      loading, 
      isManager,
      fetchCurrentUser,
      handleLanguageChange
    }}>
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook to use Auth context
const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// Company Registration Form Component
const CompanyRegistrationForm = ({ onBack }) => {
  const { t } = useTranslation();
  const { registerCompany } = useAuth();
  const [formData, setFormData] = useState({
    company_name: '',
    company_email: '',
    company_phone: '',
    company_address: '',
    company_website: '',
    manager_name: '',
    manager_email: '',
    manager_password: '',
    manager_phone: '',
    manager_department: ''
  });
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [registrationError, setRegistrationError] = useState('');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    // Clear error when field is edited
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    // Required fields
    if (!formData.company_name) newErrors.company_name = t('validation.required');
    if (!formData.company_email) newErrors.company_email = t('validation.required');
    else if (!/\S+@\S+\.\S+/.test(formData.company_email)) newErrors.company_email = t('validation.invalidEmail');
    
    if (!formData.manager_name) newErrors.manager_name = t('validation.required');
    if (!formData.manager_email) newErrors.manager_email = t('validation.required');
    else if (!/\S+@\S+\.\S+/.test(formData.manager_email)) newErrors.manager_email = t('validation.invalidEmail');
    
    if (!formData.manager_password) newErrors.manager_password = t('validation.required');
    else if (formData.manager_password.length < 8) newErrors.manager_password = t('validation.passwordLength');
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    setIsSubmitting(true);
    setRegistrationError('');
    
    const result = await registerCompany(formData);
    
    setIsSubmitting(false);
    
    if (!result.success) {
      setRegistrationError(result.error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <button 
          onClick={onBack}
          className="mb-4 flex items-center text-gray-600 hover:text-gray-800"
        >
          ← {t('common.backToHome')}
        </button>
        <h2 className="text-center text-3xl font-extrabold text-gray-900">
          {t('registration.createAccount')}
        </h2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {registrationError && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {registrationError}
            </div>
          )}
          
          <form className="space-y-6" onSubmit={handleSubmit}>
            {/* Company Information */}
            <h3 className="text-lg font-medium text-gray-900">{t('registration.companyInfo')}</h3>
            
            <div>
              <label htmlFor="company_name" className="block text-sm font-medium text-gray-700">
                {t('registration.companyName')} *
              </label>
              <div className="mt-1">
                <input
                  id="company_name"
                  name="company_name"
                  type="text"
                  placeholder={t('registration.companyName') + ' *'}
                  value={formData.company_name}
                  onChange={handleChange}
                  className={`appearance-none block w-full px-3 py-2 border ${errors.company_name ? 'border-red-300' : 'border-gray-300'} rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm`}
                />
                {errors.company_name && <p className="mt-2 text-sm text-red-600">{errors.company_name}</p>}
              </div>
            </div>

            <div>
              <label htmlFor="company_email" className="block text-sm font-medium text-gray-700">
                {t('registration.companyEmail')} *
              </label>
              <div className="mt-1">
                <input
                  id="company_email"
                  name="company_email"
                  type="email"
                  placeholder={t('registration.companyEmail') + ' *'}
                  value={formData.company_email}
                  onChange={handleChange}
                  className={`appearance-none block w-full px-3 py-2 border ${errors.company_email ? 'border-red-300' : 'border-gray-300'} rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm`}
                />
                {errors.company_email && <p className="mt-2 text-sm text-red-600">{errors.company_email}</p>}
              </div>
            </div>

            <div>
              <label htmlFor="company_phone" className="block text-sm font-medium text-gray-700">
                {t('registration.companyPhone')}
              </label>
              <div className="mt-1">
                <input
                  id="company_phone"
                  name="company_phone"
                  type="text"
                  placeholder={t('registration.companyPhone')}
                  value={formData.company_phone}
                  onChange={handleChange}
                  className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                />
              </div>
            </div>

            <div>
              <label htmlFor="company_address" className="block text-sm font-medium text-gray-700">
                {t('registration.companyAddress')}
              </label>
              <div className="mt-1">
                <input
                  id="company_address"
                  name="company_address"
                  type="text"
                  placeholder={t('registration.companyAddress')}
                  value={formData.company_address}
                  onChange={handleChange}
                  className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                />
              </div>
            </div>

            <div>
              <label htmlFor="company_website" className="block text-sm font-medium text-gray-700">
                {t('registration.companyWebsite')}
              </label>
              <div className="mt-1">
                <input
                  id="company_website"
                  name="company_website"
                  type="text"
                  placeholder={t('registration.companyWebsite')}
                  value={formData.company_website}
                  onChange={handleChange}
                  className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                />
              </div>
            </div>

            {/* Manager Information */}
            <h3 className="text-lg font-medium text-gray-900 pt-4">{t('registration.managerInfo')}</h3>
            
            <div>
              <label htmlFor="manager_name" className="block text-sm font-medium text-gray-700">
                {t('registration.managerName')} *
              </label>
              <div className="mt-1">
                <input
                  id="manager_name"
                  name="manager_name"
                  type="text"
                  placeholder={t('registration.managerName') + ' *'}
                  value={formData.manager_name}
                  onChange={handleChange}
                  className={`appearance-none block w-full px-3 py-2 border ${errors.manager_name ? 'border-red-300' : 'border-gray-300'} rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm`}
                />
                {errors.manager_name && <p className="mt-2 text-sm text-red-600">{errors.manager_name}</p>}
              </div>
            </div>

            <div>
              <label htmlFor="manager_email" className="block text-sm font-medium text-gray-700">
                {t('registration.managerEmail')} *
              </label>
              <div className="mt-1">
                <input
                  id="manager_email"
                  name="manager_email"
                  type="email"
                  placeholder={t('registration.managerEmail') + ' *'}
                  value={formData.manager_email}
                  onChange={handleChange}
                  className={`appearance-none block w-full px-3 py-2 border ${errors.manager_email ? 'border-red-300' : 'border-gray-300'} rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm`}
                />
                {errors.manager_email && <p className="mt-2 text-sm text-red-600">{errors.manager_email}</p>}
              </div>
            </div>

            <div>
              <label htmlFor="manager_password" className="block text-sm font-medium text-gray-700">
                {t('registration.password')} *
              </label>
              <div className="mt-1">
                <input
                  id="manager_password"
                  name="manager_password"
                  type="password"
                  placeholder={t('registration.password') + ' *'}
                  value={formData.manager_password}
                  onChange={handleChange}
                  className={`appearance-none block w-full px-3 py-2 border ${errors.manager_password ? 'border-red-300' : 'border-gray-300'} rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm`}
                />
                {errors.manager_password && <p className="mt-2 text-sm text-red-600">{errors.manager_password}</p>}
              </div>
            </div>

            <div>
              <label htmlFor="manager_phone" className="block text-sm font-medium text-gray-700">
                {t('registration.managerPhone')}
              </label>
              <div className="mt-1">
                <input
                  id="manager_phone"
                  name="manager_phone"
                  type="text"
                  placeholder={t('registration.managerPhone')}
                  value={formData.manager_phone}
                  onChange={handleChange}
                  className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                />
              </div>
            </div>

            <div>
              <label htmlFor="manager_department" className="block text-sm font-medium text-gray-700">
                {t('registration.department')}
              </label>
              <div className="mt-1">
                <input
                  id="manager_department"
                  name="manager_department"
                  type="text"
                  placeholder={t('registration.department')}
                  value={formData.manager_department}
                  onChange={handleChange}
                  className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {isSubmitting ? t('common.processing') : t('registration.createAccount')}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Login Form Component
const LoginForm = ({ onBack }) => {
  const { t } = useTranslation();
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!email || !password) {
      setError(t('validation.allFieldsRequired'));
      return;
    }
    
    setIsSubmitting(true);
    setError('');
    
    const result = await login(email, password);
    
    setIsSubmitting(false);
    
    if (!result.success) {
      setError(result.error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <button 
          onClick={onBack}
          className="mb-4 flex items-center text-gray-600 hover:text-gray-800"
        >
          ← {t('common.backToHome')}
        </button>
        <h2 className="text-center text-3xl font-extrabold text-gray-900">
          {t('auth.signInTitle')}
        </h2>
        <p className="mt-2 text-center text-sm text-gray-600">
          {t('auth.signInSubtitle')}
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}
          
          <form className="space-y-6" onSubmit={handleSubmit}>
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                {t('common.email')}
              </label>
              <div className="mt-1">
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  placeholder={t('common.email')}
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                {t('common.password')}
              </label>
              <div className="mt-1">
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  placeholder={t('common.password')}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {isSubmitting ? t('common.loading') : t('common.login')}
              </button>
            </div>

            <div className="text-center">
              <p className="text-sm text-gray-600">
                {t('auth.dontHaveAccount')}{' '}
                <button
                  type="button"
                  onClick={() => window.location.href = '#register'}
                  className="font-medium text-blue-600 hover:text-blue-500"
                >
                  {t('auth.signUp')}
                </button>
              </p>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Fleet Dashboard Component
const FleetDashboard = () => {
  const { user, company, logout, isManager } = useAuth();
  const { t, i18n } = useTranslation();
  const [cars, setCars] = useState([]);
  const [downtimes, setDowntimes] = useState([]);
  const [bookings, setBookings] = useState([]);
  const [users, setUsers] = useState([]);
  const [fleetStats, setFleetStats] = useState({});
  const [categoryStats, setCategoryStats] = useState([]);
  const [activeTab, setActiveTab] = useState('dashboard');
  
  const handleLanguageChange = async (langCode) => {
    try {
      if (user?.id) {
        const response = await fetch(`${API}/api/users/${user.id}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          },
          body: JSON.stringify({ language: langCode })
        });

        if (response.ok) {
          console.log('Language preference updated successfully');
        } else {
          console.error('Failed to update language preference');
        }
      }
    } catch (error) {
      console.error('Error updating language preference:', error);
    }
  };

  // Fetch cars data
  useEffect(() => {
    const fetchCars = async () => {
      try {
        const response = await fetch(`${API}/api/cars`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          setCars(data);
        }
      } catch (error) {
        console.error('Error fetching cars:', error);
      }
    };

    if (user) {
      fetchCars();
    }
  }, [user]);

  // Fetch downtimes data
  useEffect(() => {
    const fetchDowntimes = async () => {
      try {
        const response = await fetch(`${API}/api/downtimes`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          setDowntimes(data);
        }
      } catch (error) {
        console.error('Error fetching downtimes:', error);
      }
    };

    if (user) {
      fetchDowntimes();
    }
  }, [user]);

  // Fetch bookings data
  useEffect(() => {
    const fetchBookings = async () => {
      try {
        const response = await fetch(`${API}/api/bookings`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          setBookings(data);
        }
      } catch (error) {
        console.error('Error fetching bookings:', error);
      }
    };

    if (user) {
      fetchBookings();
    }
  }, [user]);

  // Fetch users data (managers only)
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const response = await fetch(`${API}/api/users`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          setUsers(data);
        }
      } catch (error) {
        console.error('Error fetching users:', error);
      }
    };

    if (user && isManager) {
      fetchUsers();
    }
  }, [user, isManager]);

  // Calculate fleet statistics
  useEffect(() => {
    if (cars.length > 0) {
      // Total cars
      const totalCars = cars.length;
      
      // Available cars (not in downtime)
      const currentDate = new Date();
      const activeCars = cars.filter(car => {
        const carDowntimes = downtimes.filter(d => d.car_id === car.id);
        return !carDowntimes.some(d => {
          const startDate = new Date(d.start_date);
          const endDate = d.end_date ? new Date(d.end_date) : null;
          return startDate <= currentDate && (!endDate || endDate >= currentDate);
        });
      });
      const availableCars = activeCars.length;
      
      // Cars by category
      const categories = {};
      cars.forEach(car => {
        const category = car.category || 'Uncategorized';
        if (!categories[category]) {
          categories[category] = 0;
        }
        categories[category]++;
      });
      
      const categoryData = Object.entries(categories).map(([name, count]) => ({
        name,
        count,
        percentage: Math.round((count / totalCars) * 100)
      }));
      
      setFleetStats({
        totalCars,
        availableCars,
        utilizationRate: Math.round((availableCars / totalCars) * 100)
      });
      
      setCategoryStats(categoryData);
    }
  }, [cars, downtimes]);

  // Navigation tabs
  const tabs = [
    { id: 'dashboard', label: t('dashboard.overview') },
    { id: 'cars', label: t('dashboard.vehicles') },
    { id: 'bookings', label: t('dashboard.bookings') },
    ...(isManager ? [{ id: 'users', label: t('dashboard.users') }] : [])
  ];

  return (
    <div className="dashboard min-h-screen bg-gray-100">
      {/* Navigation */}
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <h1 className="text-xl font-bold text-gray-800">
                  🚗 {company?.name || 'FleetManager Pro'}
                </h1>
              </div>
              <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                {tabs.map(tab => (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                      activeTab === tab.id
                        ? 'border-blue-500 text-gray-900'
                        : 'border-transparent text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <LanguageSelector user={user} onLanguageChange={handleLanguageChange} />
              <span className="text-sm text-gray-600">
                {user.name}
              </span>
              <button
                onClick={logout}
                className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
              >
                {t('common.logout')}
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 px-4">
        {activeTab === 'dashboard' && (
          <div>
            <h2 className="text-2xl font-bold text-gray-800 mb-6">{t('dashboard.fleetOverview')}</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              {/* Total Vehicles */}
              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    {t('dashboard.totalVehicles')}
                  </dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    {fleetStats.totalCars || 0}
                  </dd>
                </div>
              </div>
              
              {/* Available Vehicles */}
              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    {t('dashboard.availableVehicles')}
                  </dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    {fleetStats.availableCars || 0}
                  </dd>
                </div>
              </div>
              
              {/* Fleet Utilization */}
              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    {t('dashboard.fleetUtilization')}
                  </dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    {fleetStats.utilizationRate || 0}%
                  </dd>
                </div>
              </div>
            </div>
            
            {/* Vehicle Categories */}
            <div className="bg-white shadow rounded-lg p-6 mb-8">
              <h3 className="text-lg font-medium text-gray-900 mb-4">{t('dashboard.vehicleCategories')}</h3>
              
              <div className="space-y-4">
                {categoryStats.map(category => (
                  <div key={category.name}>
                    <div className="flex items-center justify-between">
                      <div className="text-sm font-medium text-gray-700">{category.name}</div>
                      <div className="text-sm text-gray-500">{category.count} ({category.percentage}%)</div>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2.5 mt-1">
                      <div 
                        className="bg-blue-600 h-2.5 rounded-full" 
                        style={{ width: `${category.percentage}%` }}
                      ></div>
                    </div>
                  </div>
                ))}
                
                {categoryStats.length === 0 && (
                  <p className="text-gray-500 text-sm">{t('dashboard.noVehiclesYet')}</p>
                )}
              </div>
            </div>
            
            {/* Recent Bookings */}
            <div className="bg-white shadow rounded-lg p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">{t('dashboard.recentBookings')}</h3>
              
              {bookings.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('bookings.vehicle')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('bookings.user')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('bookings.startDate')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('bookings.endDate')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('bookings.status')}
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {bookings.slice(0, 5).map(booking => {
                        const car = cars.find(c => c.id === booking.car_id);
                        const user = users.find(u => u.id === booking.user_id);
                        
                        return (
                          <tr key={booking.id}>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {car ? `${car.make} ${car.model}` : booking.car_id}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {user ? user.name : booking.user_id}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {new Date(booking.start_date).toLocaleDateString()}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {booking.end_date ? new Date(booking.end_date).toLocaleDateString() : '-'}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                booking.status === 'approved' ? 'bg-green-100 text-green-800' :
                                booking.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                'bg-red-100 text-red-800'
                              }`}>
                                {booking.status}
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-gray-500 text-sm">{t('dashboard.noBookingsYet')}</p>
              )}
            </div>
          </div>
        )}
        
        {/* Other tabs would be implemented here */}
        {activeTab !== 'dashboard' && (
          <div className="bg-white shadow rounded-lg p-6">
            <h2 className="text-xl font-bold text-gray-800 mb-4">
              {tabs.find(tab => tab.id === activeTab)?.label}
            </h2>
            <p className="text-gray-500">
              {t('dashboard.comingSoon')}
            </p>
          </div>
        )}
      </main>
    </div>
  );
};

// Main App Component
const MainApp = () => {
  const { user, loading } = useAuth();
  const [currentView, setCurrentView] = useState('landing');
  const { t } = useTranslation();

  // If user is logged in, show dashboard
  useEffect(() => {
    if (user) {
      setCurrentView('dashboard');
    }
  }, [user]);

  // Show loading state
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <h2 className="text-xl font-semibold text-gray-700">{t('common.loading')}</h2>
          <p className="mt-2 text-gray-500">{t('common.pleaseWait')}</p>
        </div>
      </div>
    );
  }

  const handleGetStarted = (action) => {
    if (action === 'login') {
      setCurrentView('login');
    } else if (action === 'register') {
      setCurrentView('register');
    }
  };

  const handleBackToLanding = () => {
    setCurrentView('landing');
  };

  // Render appropriate view
  switch (currentView) {
    case 'dashboard':
      return <FleetDashboard />;
    case 'login':
      return <LoginForm onBack={handleBackToLanding} />;
    case 'register':
      return <CompanyRegistrationForm onBack={handleBackToLanding} />;
    case 'landing':
    default:
      return <LandingPage onGetStarted={handleGetStarted} />;
  }
};

// Main App Component
function App() {
  const { t, i18n } = useTranslation();
  return (
    <AuthProvider>
      <div className="App">
        <MainApp />
      </div>
    </AuthProvider>
  );
}

// Export the App component
export default App;