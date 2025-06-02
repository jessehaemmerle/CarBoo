import React, { useState, useEffect, createContext, useContext } from "react";
import "./App.css";
import axios from "axios";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

// Authentication Context
const AuthContext = createContext();

const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      fetchCurrentUser();
    } else {
      setLoading(false);
    }
  }, []);

  const fetchCurrentUser = async () => {
    try {
      const response = await axios.get(`${API}/auth/me`);
      setUser(response.data);
    } catch (error) {
      localStorage.removeItem('token');
      delete axios.defaults.headers.common['Authorization'];
    }
    setLoading(false);
  };

  const login = async (email, password) => {
    try {
      const response = await axios.post(`${API}/auth/login`, { email, password });
      const { access_token, user: userData } = response.data;
      localStorage.setItem('token', access_token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${access_token}`;
      setUser(userData);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.response?.data?.detail || 'Login failed' };
    }
  };

  const register = async (userData) => {
    try {
      const response = await axios.post(`${API}/auth/register`, userData);
      const { access_token, user: newUser } = response.data;
      localStorage.setItem('token', access_token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${access_token}`;
      setUser(newUser);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.response?.data?.detail || 'Registration failed' };
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    delete axios.defaults.headers.common['Authorization'];
    setUser(null);
  };

  const isManager = () => user?.role === 'fleet_manager';

  return (
    <AuthContext.Provider value={{ user, login, register, logout, loading, isManager }}>
      {children}
    </AuthContext.Provider>
  );
};

const LoginForm = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    name: '', email: '', password: '', role: 'fleet_manager', department: '', phone: ''
  });
  const { login, register } = useAuth();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    const result = await login(email, password);
    if (!result.success) {
      setError(result.error);
    }
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setError('');
    const result = await register(formData);
    if (!result.success) {
      setError(result.error);
    }
  };

  if (isLogin) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md w-full space-y-8">
          <div>
            <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
              🚗 Fleet Manager Login
            </h2>
          </div>
          <form className="mt-8 space-y-6 bg-white p-8 rounded-lg shadow-md" onSubmit={handleLogin}>
            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                {error}
              </div>
            )}
            <div>
              <input
                type="email"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>
            <div>
              <input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>
            <div>
              <button
                type="submit"
                className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
              >
                Sign In
              </button>
            </div>
            <div className="text-center">
              <button
                type="button"
                onClick={() => setIsLogin(false)}
                className="text-blue-600 hover:text-blue-800"
              >
                Need to register? Sign up here
              </button>
            </div>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            🚗 Create Account
          </h2>
        </div>
        <form className="mt-8 space-y-6 bg-white p-8 rounded-lg shadow-md" onSubmit={handleRegister}>
          {error && (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              placeholder="Full Name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
            <input
              type="email"
              placeholder="Email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <input
            type="password"
            placeholder="Password"
            value={formData.password}
            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          />
          <div className="grid grid-cols-2 gap-4">
            <select
              value={formData.role}
              onChange={(e) => setFormData({ ...formData, role: e.target.value })}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="fleet_manager">Fleet Manager</option>
              <option value="regular_user">Regular User</option>
            </select>
            <input
              type="text"
              placeholder="Department"
              value={formData.department}
              onChange={(e) => setFormData({ ...formData, department: e.target.value })}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <input
            type="tel"
            placeholder="Phone Number"
            value={formData.phone}
            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
          >
            Create Account
          </button>
          <div className="text-center">
            <button
              type="button"
              onClick={() => setIsLogin(true)}
              className="text-blue-600 hover:text-blue-800"
            >
              Already have an account? Sign in
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const FleetDashboard = () => {
  const { user, logout, isManager } = useAuth();
  const [cars, setCars] = useState([]);
  const [downtimes, setDowntimes] = useState([]);
  const [bookings, setBookings] = useState([]);
  const [users, setUsers] = useState([]);
  const [fleetStats, setFleetStats] = useState({});
  const [categoryStats, setCategoryStats] = useState([]);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [showAddCarModal, setShowAddCarModal] = useState(false);
  const [showEditCarModal, setShowEditCarModal] = useState(false);
  const [showAddDowntimeModal, setShowAddDowntimeModal] = useState(false);
  const [showAddUserModal, setShowAddUserModal] = useState(false);
  const [showBookingModal, setShowBookingModal] = useState(false);
  const [selectedCar, setSelectedCar] = useState(null);
  const [editingCar, setEditingCar] = useState(null);

  // Form states
  const [carForm, setCarForm] = useState({
    make: '', model: '', year: '', license_plate: '', vin: '', mileage: '', category: 'sedan'
  });
  const [downtimeForm, setDowntimeForm] = useState({
    car_id: '', reason: 'maintenance', description: '', start_date: '', end_date: '', cost: ''
  });
  const [userForm, setUserForm] = useState({
    name: '', email: '', password: '', role: 'regular_user', department: '', phone: ''
  });
  const [bookingForm, setBookingForm] = useState({
    car_id: '', start_date: '', end_date: '', purpose: ''
  });

  const carCategories = ['sedan', 'suv', 'truck', 'van', 'hatchback', 'coupe'];
  const downtimeReasons = ['maintenance', 'repair', 'accident', 'cleaning', 'inspection', 'other'];

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const requests = [
        axios.get(`${API}/cars`),
        axios.get(`${API}/downtimes`),
        axios.get(`${API}/bookings`),
        axios.get(`${API}/fleet/stats`),
        axios.get(`${API}/fleet/categories`)
      ];

      if (isManager()) {
        requests.push(axios.get(`${API}/users`));
      }

      const responses = await Promise.all(requests);
      
      setCars(responses[0].data);
      setDowntimes(responses[1].data);
      setBookings(responses[2].data);
      setFleetStats(responses[3].data);
      setCategoryStats(responses[4].data);

      if (isManager() && responses[5]) {
        setUsers(responses[5].data);
      }
    } catch (error) {
      console.error('Error fetching data:', error);
    }
  };

  const handleAddCar = async (e) => {
    e.preventDefault();
    try {
      await axios.post(`${API}/cars`, {
        ...carForm,
        year: parseInt(carForm.year),
        mileage: parseInt(carForm.mileage)
      });
      setCarForm({ make: '', model: '', year: '', license_plate: '', vin: '', mileage: '', category: 'sedan' });
      setShowAddCarModal(false);
      fetchData();
    } catch (error) {
      console.error('Error adding car:', error);
      alert(error.response?.data?.detail || 'Error adding car');
    }
  };

  const handleEditCar = async (e) => {
    e.preventDefault();
    try {
      await axios.put(`${API}/cars/${editingCar.id}`, {
        ...carForm,
        year: parseInt(carForm.year),
        mileage: parseInt(carForm.mileage)
      });
      setCarForm({ make: '', model: '', year: '', license_plate: '', vin: '', mileage: '', category: 'sedan' });
      setShowEditCarModal(false);
      setEditingCar(null);
      fetchData();
    } catch (error) {
      console.error('Error updating car:', error);
      alert(error.response?.data?.detail || 'Error updating car');
    }
  };

  const handleDeleteCar = async (carId, carName) => {
    if (window.confirm(`Are you sure you want to delete ${carName}? This will also delete all associated downtimes.`)) {
      try {
        await axios.delete(`${API}/cars/${carId}`);
        fetchData();
      } catch (error) {
        console.error('Error deleting car:', error);
        alert(error.response?.data?.detail || 'Error deleting car');
      }
    }
  };

  const openEditCarModal = (car) => {
    setEditingCar(car);
    setCarForm({
      make: car.make,
      model: car.model,
      year: car.year.toString(),
      license_plate: car.license_plate,
      vin: car.vin,
      mileage: car.mileage.toString(),
      category: car.category
    });
    setShowEditCarModal(true);
  };

  const handleAddDowntime = async (e) => {
    e.preventDefault();
    try {
      const downtimeData = {
        ...downtimeForm,
        start_date: new Date(downtimeForm.start_date).toISOString(),
        end_date: downtimeForm.end_date ? new Date(downtimeForm.end_date).toISOString() : null,
        cost: downtimeForm.cost ? parseFloat(downtimeForm.cost) : null
      };
      await axios.post(`${API}/downtimes`, downtimeData);
      setDowntimeForm({ car_id: '', reason: 'maintenance', description: '', start_date: '', end_date: '', cost: '' });
      setShowAddDowntimeModal(false);
      fetchData();
    } catch (error) {
      console.error('Error adding downtime:', error);
    }
  };

  const handleAddUser = async (e) => {
    e.preventDefault();
    try {
      await axios.post(`${API}/users`, userForm);
      setUserForm({ name: '', email: '', password: '', role: 'regular_user', department: '', phone: '' });
      setShowAddUserModal(false);
      fetchData();
    } catch (error) {
      console.error('Error adding user:', error);
    }
  };

  const handleCreateBooking = async (e) => {
    e.preventDefault();
    try {
      const bookingData = {
        ...bookingForm,
        start_date: new Date(bookingForm.start_date).toISOString(),
        end_date: new Date(bookingForm.end_date).toISOString()
      };
      await axios.post(`${API}/bookings`, bookingData);
      setBookingForm({ car_id: '', start_date: '', end_date: '', purpose: '' });
      setShowBookingModal(false);
      fetchData();
    } catch (error) {
      console.error('Error creating booking:', error);
      alert(error.response?.data?.detail || 'Error creating booking');
    }
  };

  const handleApproveRejectBooking = async (bookingId, status, rejectionReason = '') => {
    try {
      await axios.put(`${API}/bookings/${bookingId}/approve`, {
        status,
        rejection_reason: rejectionReason || undefined
      });
      fetchData();
    } catch (error) {
      console.error('Error updating booking:', error);
      alert(error.response?.data?.detail || 'Error updating booking');
    }
  };

  const handleCancelBooking = async (bookingId) => {
    try {
      await axios.delete(`${API}/bookings/${bookingId}`);
      fetchData();
    } catch (error) {
      console.error('Error cancelling booking:', error);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      available: 'bg-green-100 text-green-800',
      in_use: 'bg-blue-100 text-blue-800',
      downtime: 'bg-red-100 text-red-800',
      maintenance: 'bg-yellow-100 text-yellow-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const getCategoryIcon = (category) => {
    const icons = {
      sedan: '🚗', suv: '🚙', truck: '🚚', van: '🚐', hatchback: '🚗', coupe: '🏎️'
    };
    return icons[category] || '🚗';
  };

  const Dashboard = () => (
    <div className="space-y-6">
      {/* Hero Section */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 rounded-lg text-white p-8 relative overflow-hidden">
        <div className="relative z-10">
          <h1 className="text-4xl font-bold mb-4">Fleet Management System</h1>
          <p className="text-xl opacity-90">Welcome back, {user.name}! Manage your company vehicles efficiently.</p>
          <p className="text-sm opacity-75 mt-2">Role: {user.role === 'fleet_manager' ? 'Fleet Manager' : 'Regular User'}</p>
        </div>
        <div className="absolute top-0 right-0 w-1/3 h-full opacity-20">
          <img src="https://images.unsplash.com/photo-1574777225753-8c02c830b525" alt="Fleet" className="w-full h-full object-cover" />
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-blue-500">
          <h3 className="text-2xl font-bold text-blue-600">{fleetStats.total_cars || 0}</h3>
          <p className="text-gray-600">Total Cars</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-green-500">
          <h3 className="text-2xl font-bold text-green-600">{fleetStats.available_cars || 0}</h3>
          <p className="text-gray-600">Available</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-yellow-500">
          <h3 className="text-2xl font-bold text-yellow-600">{fleetStats.in_use || 0}</h3>
          <p className="text-gray-600">In Use</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-red-500">
          <h3 className="text-2xl font-bold text-red-600">{fleetStats.in_downtime || 0}</h3>
          <p className="text-gray-600">Downtime</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-orange-500">
          <h3 className="text-2xl font-bold text-orange-600">{fleetStats.maintenance || 0}</h3>
          <p className="text-gray-600">Maintenance</p>
        </div>
      </div>

      {/* Category Breakdown */}
      <div className="bg-white p-6 rounded-lg shadow-md">
        <h2 className="text-xl font-semibold mb-4">Fleet by Category</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {categoryStats.map((cat, idx) => (
            <div key={idx} className="text-center p-4 bg-gray-50 rounded-lg">
              <div className="text-3xl mb-2">{getCategoryIcon(cat.category)}</div>
              <div className="font-semibold text-lg">{cat.count}</div>
              <div className="text-sm text-gray-600 capitalize">{cat.category}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const CarsView = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Fleet Vehicles</h2>
        {isManager() && (
          <button
            onClick={() => setShowAddCarModal(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Add New Car
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {cars.map((car) => (
          <div key={car.id} className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="text-3xl">{getCategoryIcon(car.category)}</div>
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(car.status)}`}>
                {car.status.replace('_', ' ').toUpperCase()}
              </span>
            </div>
            <h3 className="text-lg font-semibold mb-2">{car.year} {car.make} {car.model}</h3>
            <div className="space-y-1 text-sm text-gray-600">
              <p><span className="font-medium">License:</span> {car.license_plate}</p>
              <p><span className="font-medium">VIN:</span> {car.vin}</p>
              <p><span className="font-medium">Mileage:</span> {car.mileage.toLocaleString()} miles</p>
              <p><span className="font-medium">Category:</span> {car.category}</p>
            </div>
            {isManager() ? (
              <button
                onClick={() => {
                  setSelectedCar(car.id);
                  setDowntimeForm({ ...downtimeForm, car_id: car.id });
                  setShowAddDowntimeModal(true);
                }}
                className="mt-4 w-full bg-gray-100 text-gray-700 py-2 rounded hover:bg-gray-200 transition-colors"
              >
                Add Downtime
              </button>
            ) : (
              <button
                onClick={() => {
                  setBookingForm({ ...bookingForm, car_id: car.id });
                  setShowBookingModal(true);
                }}
                disabled={car.status !== 'available'}
                className={`mt-4 w-full py-2 rounded transition-colors ${
                  car.status === 'available' 
                    ? 'bg-purple-100 text-purple-700 hover:bg-purple-200' 
                    : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                }`}
              >
                {car.status === 'available' ? 'Book Car' : 'Not Available'}
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );

  const DowntimesView = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Downtime Records</h2>
        {isManager() && (
          <button
            onClick={() => setShowAddDowntimeModal(true)}
            className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
          >
            Add Downtime
          </button>
        )}
      </div>

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Car</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reason</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Start Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">End Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Cost</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Description</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {downtimes.map((downtime) => {
                const car = cars.find(c => c.id === downtime.car_id);
                return (
                  <tr key={downtime.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      {car ? `${car.year} ${car.make} ${car.model}` : 'Unknown Car'}
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 bg-gray-100 text-gray-800 rounded capitalize">
                        {downtime.reason}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {new Date(downtime.start_date).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {downtime.end_date ? new Date(downtime.end_date).toLocaleDateString() : 'Ongoing'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {downtime.cost ? `$${downtime.cost.toFixed(2)}` : '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {downtime.description}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );

  const UsersView = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">User Management</h2>
        <button
          onClick={() => setShowAddUserModal(true)}
          className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors"
        >
          Add New User
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Role</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Department</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Phone</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {users.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 font-medium">{user.name}</td>
                  <td className="px-6 py-4">{user.email}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded capitalize ${user.role === 'fleet_manager' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'}`}>
                      {user.role.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4">{user.department || '-'}</td>
                  <td className="px-6 py-4">{user.phone || '-'}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );

  const getBookingStatusColor = (status) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      completed: 'bg-blue-100 text-blue-800',
      cancelled: 'bg-gray-100 text-gray-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const BookingsView = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">
          {isManager() ? 'All Bookings' : 'My Bookings'}
        </h2>
        <button
          onClick={() => setShowBookingModal(true)}
          className="bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 transition-colors"
        >
          Request Booking
        </button>
      </div>

      {/* Pending Approvals for Managers */}
      {isManager() && (
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold mb-4">Pending Approvals</h3>
          <div className="space-y-4">
            {bookings.filter(b => b.status === 'pending').map((booking) => (
              <div key={booking.id} className="border rounded-lg p-4 bg-yellow-50">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      <span className="font-medium">{booking.user_info?.name}</span>
                      <span className="text-gray-600">requested</span>
                      <span className="font-medium">
                        {booking.car_info ? `${booking.car_info.year} ${booking.car_info.make} ${booking.car_info.model}` : 'Unknown Car'}
                      </span>
                    </div>
                    <div className="text-sm text-gray-600 space-y-1">
                      <p><span className="font-medium">Period:</span> {new Date(booking.start_date).toLocaleDateString()} - {new Date(booking.end_date).toLocaleDateString()}</p>
                      <p><span className="font-medium">Purpose:</span> {booking.purpose}</p>
                      <p><span className="font-medium">Department:</span> {booking.user_info?.department || 'N/A'}</p>
                    </div>
                  </div>
                  <div className="flex space-x-2 ml-4">
                    <button
                      onClick={() => handleApproveRejectBooking(booking.id, 'approved')}
                      className="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700"
                    >
                      Approve
                    </button>
                    <button
                      onClick={() => {
                        const reason = prompt('Rejection reason (optional):');
                        handleApproveRejectBooking(booking.id, 'rejected', reason);
                      }}
                      className="bg-red-600 text-white px-3 py-1 rounded text-sm hover:bg-red-700"
                    >
                      Reject
                    </button>
                  </div>
                </div>
              </div>
            ))}
            {bookings.filter(b => b.status === 'pending').length === 0 && (
              <p className="text-gray-500 text-center py-4">No pending approvals</p>
            )}
          </div>
        </div>
      )}

      {/* All Bookings */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Car</th>
                {isManager() && <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>}
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Period</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Purpose</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {bookings.map((booking) => (
                <tr key={booking.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div>
                      <div className="font-medium">
                        {booking.car_info ? `${booking.car_info.year} ${booking.car_info.make} ${booking.car_info.model}` : 'Unknown Car'}
                      </div>
                      <div className="text-sm text-gray-600">
                        {booking.car_info?.license_plate}
                      </div>
                    </div>
                  </td>
                  {isManager() && (
                    <td className="px-6 py-4">
                      <div>
                        <div className="font-medium">{booking.user_info?.name}</div>
                        <div className="text-sm text-gray-600">{booking.user_info?.department}</div>
                      </div>
                    </td>
                  )}
                  <td className="px-6 py-4 text-sm">
                    <div>{new Date(booking.start_date).toLocaleDateString()}</div>
                    <div className="text-gray-600">to {new Date(booking.end_date).toLocaleDateString()}</div>
                  </td>
                  <td className="px-6 py-4 text-sm">{booking.purpose}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getBookingStatusColor(booking.status)}`}>
                      {booking.status.toUpperCase()}
                    </span>
                    {booking.status === 'rejected' && booking.rejection_reason && (
                      <div className="text-xs text-red-600 mt-1">{booking.rejection_reason}</div>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    {booking.status === 'pending' && (
                      <button
                        onClick={() => handleCancelBooking(booking.id)}
                        className="text-red-600 hover:text-red-800 text-sm"
                      >
                        Cancel
                      </button>
                    )}
                    {isManager() && booking.status === 'pending' && (
                      <div className="space-x-2">
                        <button
                          onClick={() => handleApproveRejectBooking(booking.id, 'approved')}
                          className="text-green-600 hover:text-green-800 text-sm"
                        >
                          Approve
                        </button>
                        <button
                          onClick={() => {
                            const reason = prompt('Rejection reason (optional):');
                            handleApproveRejectBooking(booking.id, 'rejected', reason);
                          }}
                          className="text-red-600 hover:text-red-800 text-sm"
                        >
                          Reject
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );

  const tabs = [
    { id: 'dashboard', name: 'Dashboard', visible: true },
    { id: 'cars', name: 'Cars', visible: true },
    { id: 'bookings', name: 'Bookings', visible: true },
    { id: 'downtimes', name: 'Downtimes', visible: true },
    { id: 'users', name: 'Users', visible: isManager() }
  ].filter(tab => tab.visible);

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Navigation */}
      <nav className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-8">
              <h1 className="text-xl font-bold text-gray-800">🚗 FleetManager</h1>
              <div className="flex space-x-4">
                {tabs.map((tab) => (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                      activeTab === tab.id
                        ? 'bg-blue-100 text-blue-700'
                        : 'text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    {tab.name}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-600">Welcome, {user.name}</span>
              <button
                onClick={logout}
                className="bg-red-600 text-white px-3 py-2 rounded-md text-sm hover:bg-red-700 transition-colors"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 px-4">
        {activeTab === 'dashboard' && <Dashboard />}
        {activeTab === 'cars' && <CarsView />}
        {activeTab === 'bookings' && <BookingsView />}
        {activeTab === 'downtimes' && <DowntimesView />}
        {activeTab === 'users' && isManager() && <UsersView />}
      </main>

      {/* Add Car Modal */}
      {showAddCarModal && isManager() && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md">
            <h2 className="text-xl font-bold mb-4">Add New Car</h2>
            <form onSubmit={handleAddCar} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <input
                  type="text"
                  placeholder="Make"
                  value={carForm.make}
                  onChange={(e) => setCarForm({ ...carForm, make: e.target.value })}
                  className="border rounded px-3 py-2"
                  required
                />
                <input
                  type="text"
                  placeholder="Model"
                  value={carForm.model}
                  onChange={(e) => setCarForm({ ...carForm, model: e.target.value })}
                  className="border rounded px-3 py-2"
                  required
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <input
                  type="number"
                  placeholder="Year"
                  value={carForm.year}
                  onChange={(e) => setCarForm({ ...carForm, year: e.target.value })}
                  className="border rounded px-3 py-2"
                  required
                />
                <select
                  value={carForm.category}
                  onChange={(e) => setCarForm({ ...carForm, category: e.target.value })}
                  className="border rounded px-3 py-2"
                >
                  {carCategories.map(cat => (
                    <option key={cat} value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</option>
                  ))}
                </select>
              </div>
              <input
                type="text"
                placeholder="License Plate"
                value={carForm.license_plate}
                onChange={(e) => setCarForm({ ...carForm, license_plate: e.target.value })}
                className="w-full border rounded px-3 py-2"
                required
              />
              <input
                type="text"
                placeholder="VIN"
                value={carForm.vin}
                onChange={(e) => setCarForm({ ...carForm, vin: e.target.value })}
                className="w-full border rounded px-3 py-2"
                required
              />
              <input
                type="number"
                placeholder="Mileage"
                value={carForm.mileage}
                onChange={(e) => setCarForm({ ...carForm, mileage: e.target.value })}
                className="w-full border rounded px-3 py-2"
                required
              />
              <div className="flex space-x-4">
                <button type="submit" className="flex-1 bg-blue-600 text-white py-2 rounded hover:bg-blue-700">
                  Add Car
                </button>
                <button
                  type="button"
                  onClick={() => setShowAddCarModal(false)}
                  className="flex-1 bg-gray-300 text-gray-700 py-2 rounded hover:bg-gray-400"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Downtime Modal */}
      {showAddDowntimeModal && isManager() && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md">
            <h2 className="text-xl font-bold mb-4">Add Downtime</h2>
            <form onSubmit={handleAddDowntime} className="space-y-4">
              <select
                value={downtimeForm.car_id}
                onChange={(e) => setDowntimeForm({ ...downtimeForm, car_id: e.target.value })}
                className="w-full border rounded px-3 py-2"
                required
              >
                <option value="">Select Car</option>
                {cars.map(car => (
                  <option key={car.id} value={car.id}>
                    {car.year} {car.make} {car.model} - {car.license_plate}
                  </option>
                ))}
              </select>
              <select
                value={downtimeForm.reason}
                onChange={(e) => setDowntimeForm({ ...downtimeForm, reason: e.target.value })}
                className="w-full border rounded px-3 py-2"
              >
                {downtimeReasons.map(reason => (
                  <option key={reason} value={reason}>{reason.charAt(0).toUpperCase() + reason.slice(1)}</option>
                ))}
              </select>
              <textarea
                placeholder="Description"
                value={downtimeForm.description}
                onChange={(e) => setDowntimeForm({ ...downtimeForm, description: e.target.value })}
                className="w-full border rounded px-3 py-2 h-20"
                required
              />
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                  <input
                    type="datetime-local"
                    value={downtimeForm.start_date}
                    onChange={(e) => setDowntimeForm({ ...downtimeForm, start_date: e.target.value })}
                    className="w-full border rounded px-3 py-2"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">End Date (Optional)</label>
                  <input
                    type="datetime-local"
                    value={downtimeForm.end_date}
                    onChange={(e) => setDowntimeForm({ ...downtimeForm, end_date: e.target.value })}
                    className="w-full border rounded px-3 py-2"
                  />
                </div>
              </div>
              <input
                type="number"
                step="0.01"
                placeholder="Cost (Optional)"
                value={downtimeForm.cost}
                onChange={(e) => setDowntimeForm({ ...downtimeForm, cost: e.target.value })}
                className="w-full border rounded px-3 py-2"
              />
              <div className="flex space-x-4">
                <button type="submit" className="flex-1 bg-red-600 text-white py-2 rounded hover:bg-red-700">
                  Add Downtime
                </button>
                <button
                  type="button"
                  onClick={() => setShowAddDowntimeModal(false)}
                  className="flex-1 bg-gray-300 text-gray-700 py-2 rounded hover:bg-gray-400"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add User Modal */}
      {showAddUserModal && isManager() && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md">
            <h2 className="text-xl font-bold mb-4">Add New User</h2>
            <form onSubmit={handleAddUser} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <input
                  type="text"
                  placeholder="Full Name"
                  value={userForm.name}
                  onChange={(e) => setUserForm({ ...userForm, name: e.target.value })}
                  className="border rounded px-3 py-2"
                  required
                />
                <input
                  type="email"
                  placeholder="Email"
                  value={userForm.email}
                  onChange={(e) => setUserForm({ ...userForm, email: e.target.value })}
                  className="border rounded px-3 py-2"
                  required
                />
              </div>
              <input
                type="password"
                placeholder="Password"
                value={userForm.password}
                onChange={(e) => setUserForm({ ...userForm, password: e.target.value })}
                className="w-full border rounded px-3 py-2"
                required
              />
              <div className="grid grid-cols-2 gap-4">
                <select
                  value={userForm.role}
                  onChange={(e) => setUserForm({ ...userForm, role: e.target.value })}
                  className="border rounded px-3 py-2"
                >
                  <option value="regular_user">Regular User</option>
                  <option value="fleet_manager">Fleet Manager</option>
                </select>
                <input
                  type="text"
                  placeholder="Department"
                  value={userForm.department}
                  onChange={(e) => setUserForm({ ...userForm, department: e.target.value })}
                  className="border rounded px-3 py-2"
                />
              </div>
              <input
                type="tel"
                placeholder="Phone Number"
                value={userForm.phone}
                onChange={(e) => setUserForm({ ...userForm, phone: e.target.value })}
                className="w-full border rounded px-3 py-2"
              />
              <div className="flex space-x-4">
                <button type="submit" className="flex-1 bg-green-600 text-white py-2 rounded hover:bg-green-700">
                  Add User
                </button>
                <button
                  type="button"
                  onClick={() => setShowAddUserModal(false)}
                  className="flex-1 bg-gray-300 text-gray-700 py-2 rounded hover:bg-gray-400"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Book Car Modal */}
      {showBookingModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md">
            <h2 className="text-xl font-bold mb-4">Request Car Booking</h2>
            <form onSubmit={handleCreateBooking} className="space-y-4">
              <select
                value={bookingForm.car_id}
                onChange={(e) => setBookingForm({ ...bookingForm, car_id: e.target.value })}
                className="w-full border rounded px-3 py-2"
                required
              >
                <option value="">Select Car</option>
                {cars.filter(car => car.status === 'available').map(car => (
                  <option key={car.id} value={car.id}>
                    {car.year} {car.make} {car.model} - {car.license_plate}
                  </option>
                ))}
              </select>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                  <input
                    type="datetime-local"
                    value={bookingForm.start_date}
                    onChange={(e) => setBookingForm({ ...bookingForm, start_date: e.target.value })}
                    className="w-full border rounded px-3 py-2"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">End Date</label>
                  <input
                    type="datetime-local"
                    value={bookingForm.end_date}
                    onChange={(e) => setBookingForm({ ...bookingForm, end_date: e.target.value })}
                    className="w-full border rounded px-3 py-2"
                    required
                  />
                </div>
              </div>
              <textarea
                placeholder="Purpose of booking (e.g., client meeting, business travel)"
                value={bookingForm.purpose}
                onChange={(e) => setBookingForm({ ...bookingForm, purpose: e.target.value })}
                className="w-full border rounded px-3 py-2 h-20"
                required
              />
              <div className="flex space-x-4">
                <button type="submit" className="flex-1 bg-purple-600 text-white py-2 rounded hover:bg-purple-700">
                  Request Booking
                </button>
                <button
                  type="button"
                  onClick={() => setShowBookingModal(false)}
                  className="flex-1 bg-gray-300 text-gray-700 py-2 rounded hover:bg-gray-400"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

function App() {
  return (
    <AuthProvider>
      <div className="App">
        <AuthenticatedApp />
      </div>
    </AuthProvider>
  );
}

const AuthenticatedApp = () => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-xl">Loading...</div>
      </div>
    );
  }

  return user ? <FleetDashboard /> : <LoginForm />;
};

export default App;
