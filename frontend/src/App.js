import React, { useState, useEffect } from "react";
import "./App.css";
import axios from "axios";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const FleetDashboard = () => {
  const [cars, setCars] = useState([]);
  const [downtimes, setDowntimes] = useState([]);
  const [fleetStats, setFleetStats] = useState({});
  const [categoryStats, setCategoryStats] = useState([]);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [showAddCarModal, setShowAddCarModal] = useState(false);
  const [showAddDowntimeModal, setShowAddDowntimeModal] = useState(false);
  const [selectedCar, setSelectedCar] = useState(null);

  // Form states
  const [carForm, setCarForm] = useState({
    make: '', model: '', year: '', license_plate: '', vin: '', mileage: '', category: 'sedan'
  });
  const [downtimeForm, setDowntimeForm] = useState({
    car_id: '', reason: 'maintenance', description: '', start_date: '', end_date: '', cost: ''
  });

  const carCategories = ['sedan', 'suv', 'truck', 'van', 'hatchback', 'coupe'];
  const downtimeReasons = ['maintenance', 'repair', 'accident', 'cleaning', 'inspection', 'other'];

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [carsRes, downtimesRes, statsRes, categoriesRes] = await Promise.all([
        axios.get(`${API}/cars`),
        axios.get(`${API}/downtimes`),
        axios.get(`${API}/fleet/stats`),
        axios.get(`${API}/fleet/categories`)
      ]);
      setCars(carsRes.data);
      setDowntimes(downtimesRes.data);
      setFleetStats(statsRes.data);
      setCategoryStats(categoriesRes.data);
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
    }
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
          <p className="text-xl opacity-90">Manage your company vehicles efficiently and track availability in real-time</p>
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
        <button
          onClick={() => setShowAddCarModal(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          Add New Car
        </button>
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
          </div>
        ))}
      </div>
    </div>
  );

  const DowntimesView = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Downtime Records</h2>
        <button
          onClick={() => setShowAddDowntimeModal(true)}
          className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
        >
          Add Downtime
        </button>
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

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Navigation */}
      <nav className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-8">
              <h1 className="text-xl font-bold text-gray-800">🚗 FleetManager</h1>
              <div className="flex space-x-4">
                {[
                  { id: 'dashboard', name: 'Dashboard' },
                  { id: 'cars', name: 'Cars' },
                  { id: 'downtimes', name: 'Downtimes' }
                ].map((tab) => (
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
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 px-4">
        {activeTab === 'dashboard' && <Dashboard />}
        {activeTab === 'cars' && <CarsView />}
        {activeTab === 'downtimes' && <DowntimesView />}
      </main>

      {/* Add Car Modal */}
      {showAddCarModal && (
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
      {showAddDowntimeModal && (
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
    </div>
  );
};

function App() {
  return (
    <div className="App">
      <FleetDashboard />
    </div>
  );
}

export default App;
