// app.js

// ====================
// 1. Firebase Initialization
// ====================

// Firebase Configuration
const firebaseConfig = {
  apiKey: "AIzaSyAa7cT3iWuFa-XEEAkgehPH-D4W4HRKu8E",
  authDomain: "carboo-da8cf.firebaseapp.com",
  projectId: "carboo-da8cf",
  // Add other configuration details as provided by Firebase
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase services
const auth = firebase.auth();
const db = firebase.firestore();

// ====================
// 2. DOM Elements
// ====================

// User Info and Logout
const userInfoDiv = document.getElementById('user-info');

// Asset Management
const assetListSection = document.getElementById('asset-list-section');
const assetTableBody = document.querySelector('#asset-table tbody');
const addAssetBtn = document.getElementById('add-asset-btn');
const assetSearchInput = document.getElementById('asset-search-input');
const assetModal = document.getElementById('asset-modal');
const closeAssetModalBtn = document.getElementById('close-asset-modal');
const assetForm = document.getElementById('asset-form');
const assetNameInput = document.getElementById('asset-name-input');
const assetNumberPlateInput = document.getElementById('asset-number-plate-input');
const assetModalTitle = document.getElementById('asset-modal-title');

// Booking Management
const bookingSection = document.getElementById('booking-section');
const backToAssetsBtn = document.getElementById('back-to-assets-btn');
const addBookingBtn = document.getElementById('add-booking-btn');
const bookingModal = document.getElementById('booking-modal');
const closeBookingModalBtn = document.getElementById('close-booking-modal');
const bookingForm = document.getElementById('booking-form');
const bookingStartDateInput = document.getElementById('booking-start-date-input');
const bookingEndDateInput = document.getElementById('booking-end-date-input');
const bookingModalTitle = document.getElementById('booking-modal-title');
const assetNameSpan = document.getElementById('asset-name');
const bookingAssetNameSpan = document.getElementById('booking-asset-name');
const calendarDiv = document.getElementById('calendar');
const prevMonthBtn = document.getElementById('prev-month-btn');
const nextMonthBtn = document.getElementById('next-month-btn');
const calendarMonthYear = document.getElementById('calendar-month-year');
const bookingTableBody = document.querySelector('#booking-table tbody');

// ====================
// 3. Authentication State Handling
// ====================

let currentUser = null;
let currentUserRole = 'user'; // Default role
let currentUserCompanyId = null;
let allAssets = [];
let editingAssetId = null;
let currentAssetId = null;
let currentDate = new Date();
let bookings = [];
let editingBookingId = null;

// Listen for authentication state changes
auth.onAuthStateChanged(async (user) => {
  if (user) {
    currentUser = user;
    console.log('User is signed in:', user.email);
    // Fetch user data from Firestore
    const userDoc = await db.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      currentUserRole = userData.role;
      currentUserCompanyId = userData.company_id;
      console.log('User data:', userData);
    } else {
      console.error('User document does not exist for UID:', user.uid);
      alert('User data not found. Please contact support.');
      // Sign out the user to prevent unauthorized access
      await auth.signOut();
      return;
    }
    updateUserInterface();
    displayAssets();
  } else {
    // If user is not authenticated, redirect to login page
    window.location.href = 'login.html';
  }
});

// Function to update the user interface based on authentication and role
function updateUserInterface() {
  if (currentUser) {
    userInfoDiv.innerHTML = `
      <span>Welcome, ${currentUser.email} (${currentUserRole})</span>
      <button id="logout-btn">Logout</button>
    `;
    document.getElementById('logout-btn').addEventListener('click', logout);

    // Show or hide admin controls based on role
    if (currentUserRole === 'admin') {
      addAssetBtn.style.display = 'inline-block';
    } else {
      addAssetBtn.style.display = 'none';
    }

    assetListSection.classList.remove('hidden');
  } else {
    userInfoDiv.innerHTML = '';
  }
}

// Function to handle logout
async function logout() {
  try {
    await auth.signOut();
    // Redirect to login page after logout
    window.location.href = 'login.html';
  } catch (error) {
    console.error('Logout Error:', error);
    alert('An error occurred during logout.');
  }
}

// ====================
// 4. Asset Management Functions
// ====================

// Function to fetch and display assets
async function displayAssets() {
  try {
    const assetsSnapshot = await db.collection('assets')
      .where('company_id', '==', currentUserCompanyId)
      .get();
    allAssets = assetsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Fetch bookings related to these assets
    const assetIds = allAssets.map(asset => asset.id);
    if (assetIds.length === 0) {
      // No assets to display
      assetTableBody.innerHTML = '<tr><td colspan="4">No assets available.</td></tr>';
      return;
    }

    const bookingsSnapshot = await db.collection('bookings')
      .where('asset_id', 'in', assetIds)
      .where('company_id', '==', currentUserCompanyId)
      .get();
    bookings = bookingsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    filterAndDisplayAssets();
  } catch (error) {
    console.error('Error fetching assets:', error);
    alert('An error occurred while fetching assets.');
  }
}

// Function to filter and display assets based on search query
function filterAndDisplayAssets() {
  const searchQuery = assetSearchInput.value.trim().toLowerCase();
  const filteredAssets = allAssets.filter((asset) => {
    const nameMatch = asset.name.toLowerCase().includes(searchQuery);
    const numberPlateMatch = asset.number_plate.toLowerCase().includes(searchQuery);
    return nameMatch || numberPlateMatch;
  });

  assetTableBody.innerHTML = '';
  filteredAssets.forEach((asset) => {
    const status = determineAssetStatus(asset.id);
    const statusIcon = getStatusIcon(status);

    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${asset.name}</td>
      <td>${asset.number_plate}</td>
      <td>${statusIcon}</td>
      <td>
        <button class="view-bookings-btn" data-id="${asset.id}">View Bookings</button>
        ${currentUserRole === 'admin' ? `
          <button class="edit-asset-btn" data-id="${asset.id}">Edit</button>
          <button class="delete-asset-btn" data-id="${asset.id}">Delete</button>
        ` : ''}
      </td>
    `;
    assetTableBody.appendChild(row);
  });

  if (filteredAssets.length === 0) {
    assetTableBody.innerHTML = '<tr><td colspan="4">No assets found.</td></tr>';
  }
}

// Function to determine the status of an asset
function determineAssetStatus(assetId) {
  const today = new Date();
  today.setHours(0, 0, 0, 0); // Normalize to midnight
  const threeDaysFromNow = new Date(today);
  threeDaysFromNow.setDate(today.getDate() + 3);

  let status = 'green'; // Default status

  bookings.forEach((booking) => {
    if (booking.asset_id === assetId) {
      const bookingStart = new Date(booking.start_date);
      const bookingEnd = new Date(booking.end_date);
      bookingStart.setHours(0, 0, 0, 0);
      bookingEnd.setHours(0, 0, 0, 0);

      // Currently Booked
      if (today >= bookingStart && today <= bookingEnd) {
        status = 'red';
      }

      // Booked Tomorrow
      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);
      if (bookingStart.getTime() === tomorrow.getTime()) {
        if (status !== 'red') { // Do not override red status
          status = 'yellow';
        }
      }

      // Booked Within Next 3 Days
      const bookingStartsWithinNext3Days = bookingStart > today && bookingStart <= threeDaysFromNow;
      if (bookingStartsWithinNext3Days && status === 'green') {
        status = 'yellow';
      }
    }
  });

  return status;
}

// Function to get the corresponding status icon
function getStatusIcon(status) {
  let className = '';
  let ariaLabel = '';

  switch (status) {
    case 'green':
      className = 'status-icon green';
      ariaLabel = 'Available for the next 3 days';
      break;
    case 'yellow':
      className = 'status-icon yellow';
      ariaLabel = 'Booked tomorrow or within the next 3 days';
      break;
    case 'red':
      className = 'status-icon red';
      ariaLabel = 'Currently booked';
      break;
    default:
      className = 'status-icon gray';
      ariaLabel = 'Unknown status';
  }

  return `<span class="${className}" aria-label="${ariaLabel}" title="${ariaLabel}"></span>`;
}

// Event listener for the asset search input
assetSearchInput.addEventListener('input', () => {
  filterAndDisplayAssets();
});

// Event listener for "Add New Asset" button
addAssetBtn.addEventListener('click', () => {
  if (currentUserRole !== 'admin') {
    alert('You do not have permission to add assets.');
    return;
  }
  editingAssetId = null;
  assetModalTitle.textContent = 'Add New Asset';
  assetNameInput.value = '';
  assetNumberPlateInput.value = '';
  assetModal.classList.remove('hidden');
});

// Event listener to close the asset modal
closeAssetModalBtn.addEventListener('click', () => {
  assetModal.classList.add('hidden');
});

// Handle Asset Form Submission (Add or Edit)
assetForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const name = assetNameInput.value.trim();
  const number_plate = assetNumberPlateInput.value.trim();

  if (currentUserRole !== 'admin') {
    alert('You do not have permission to perform this action.');
    return;
  }

  try {
    if (editingAssetId !== null) {
      // Update existing asset
      await db.collection('assets').doc(editingAssetId).update({
        name,
        number_plate,
        updated_at: firebase.firestore.FieldValue.serverTimestamp()
      });
      alert('Asset updated successfully.');
    } else {
      // Create new asset
      await db.collection('assets').add({
        name,
        number_plate,
        company_id: currentUserCompanyId,
        created_at: firebase.firestore.FieldValue.serverTimestamp(),
        updated_at: firebase.firestore.FieldValue.serverTimestamp()
      });
      alert('Asset added successfully.');
    }
    assetModal.classList.add('hidden');
    assetForm.reset();
    await displayAssets();
  } catch (error) {
    console.error('Error saving asset:', error);
    alert('An error occurred while saving the asset.');
  }
});

// Delegate Edit and Delete Button Clicks within the asset table
assetTableBody.addEventListener('click', async (e) => {
  const assetId = e.target.getAttribute('data-id');
  if (e.target.classList.contains('edit-asset-btn')) {
    if (currentUserRole !== 'admin') {
      alert('You do not have permission to edit assets.');
      return;
    }
    editingAssetId = assetId;
    const assetDoc = await db.collection('assets').doc(assetId).get();
    if (assetDoc.exists) {
      const assetData = assetDoc.data();
      assetModalTitle.textContent = 'Edit Asset';
      assetNameInput.value = assetData.name;
      assetNumberPlateInput.value = assetData.number_plate;
      assetModal.classList.remove('hidden');
    }
  } else if (e.target.classList.contains('delete-asset-btn')) {
    if (currentUserRole !== 'admin') {
      alert('You do not have permission to delete assets.');
      return;
    }
    const confirmDelete = confirm('Are you sure you want to delete this asset? This will also delete all associated bookings.');
    if (confirmDelete) {
      try {
        // Delete associated bookings
        const bookingsSnapshot = await db.collection('bookings')
          .where('asset_id', '==', assetId)
          .get();
        const batch = db.batch();
        bookingsSnapshot.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();

        // Delete the asset
        await db.collection('assets').doc(assetId).delete();
        alert('Asset and its bookings deleted successfully.');
        await displayAssets();
      } catch (error) {
        console.error('Error deleting asset:', error);
        alert('An error occurred while deleting the asset.');
      }
    }
  } else if (e.target.classList.contains('view-bookings-btn')) {
    showBookingSection(assetId);
  }
});

// ====================
// 5. Booking Management Functions
// ====================

// Function to show Booking Section
async function showBookingSection(assetId) {
  currentAssetId = assetId;
  const assetDoc = await db.collection('assets').doc(assetId).get();
  if (assetDoc.exists) {
    const assetData = assetDoc.data();
    assetNameSpan.textContent = assetData.name;
    bookingAssetNameSpan.textContent = assetData.name;
    assetListSection.classList.add('hidden');
    bookingSection.classList.remove('hidden');
    currentDate = new Date(); // Reset to current date when viewing bookings
    await loadBookings();
    renderCalendar();
  } else {
    alert('Asset not found.');
  }
}

// Function to load bookings for the current asset
async function loadBookings() {
  try {
    const snapshot = await db.collection('bookings')
      .where('asset_id', '==', currentAssetId)
      .where('company_id', '==', currentUserCompanyId)
      .get();
    bookings = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    displayBookingsList();
  } catch (error) {
    console.error('Error fetching bookings:', error);
    alert('An error occurred while fetching bookings.');
  }
}

// Function to display bookings in a list
function displayBookingsList() {
  bookingTableBody.innerHTML = '';
  bookings.forEach((booking) => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${formatDateToYYYYMMDD(booking.start_date)}</td>
      <td>${formatDateToYYYYMMDD(booking.end_date)}</td>
      <td>
        ${currentUserRole === 'admin' || isBookingOwner(booking) ? `
          <button class="edit-booking-btn" data-id="${booking.id}">Edit</button>
          <button class="delete-booking-btn" data-id="${booking.id}">Delete</button>
        ` : ''}
      </td>
    `;
    bookingTableBody.appendChild(row);
  });

  if (bookings.length === 0) {
    bookingTableBody.innerHTML = '<tr><td colspan="3">No bookings found.</td></tr>';
  }
}

// Function to check if the current user is the owner of the booking
function isBookingOwner(booking) {
  return currentUser && booking.user_id === currentUser.uid;
}

// Delegate Booking Button Clicks
bookingTableBody.addEventListener('click', async (e) => {
  const bookingId = e.target.getAttribute('data-id');
  if (e.target.classList.contains('edit-booking-btn')) {
    if (currentUserRole !== 'admin' && !isBookingOwner(bookings.find(b => b.id === bookingId))) {
      alert('You do not have permission to edit this booking.');
      return;
    }
    editingBookingId = bookingId;
    const booking = bookings.find(b => b.id === bookingId);
    if (booking) {
      bookingStartDateInput.value = booking.start_date;
      bookingEndDateInput.value = booking.end_date;
      bookingModalTitle.textContent = `Edit Booking for ${bookingAssetNameSpan.textContent}`;
      bookingModal.classList.remove('hidden');
    }
  } else if (e.target.classList.contains('delete-booking-btn')) {
    if (currentUserRole !== 'admin' && !isBookingOwner(bookings.find(b => b.id === bookingId))) {
      alert('You do not have permission to delete this booking.');
      return;
    }
    const confirmDelete = confirm('Are you sure you want to delete this booking?');
    if (confirmDelete) {
      try {
        await db.collection('bookings').doc(bookingId).delete();
        alert('Booking deleted successfully.');
        await loadBookings();
        renderCalendar();
        await displayAssets(); // Refresh asset statuses after booking deletion
      } catch (error) {
        console.error('Error deleting booking:', error);
        alert('An error occurred while deleting the booking.');
      }
    }
  }
});

// Back to Assets Button
backToAssetsBtn.addEventListener('click', async () => {
  bookingSection.classList.add('hidden');
  assetListSection.classList.remove('hidden');
  await displayAssets(); // Refresh asset statuses when returning
});

// Add Booking Button
addBookingBtn.addEventListener('click', () => {
  editingBookingId = null;
  bookingModalTitle.textContent = `Add New Booking for ${bookingAssetNameSpan.textContent}`;
  bookingStartDateInput.value = '';
  bookingEndDateInput.value = '';
  bookingModal.classList.remove('hidden');
});

// Close Booking Modal
closeBookingModalBtn.addEventListener('click', () => {
  bookingModal.classList.add('hidden');
  editingBookingId = null;
});

// Handle Booking Form Submission (Add or Edit)
bookingForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const start_date = bookingStartDateInput.value;
  const end_date = bookingEndDateInput.value;

  if (new Date(start_date) > new Date(end_date)) {
    alert('End date cannot be before start date.');
    return;
  }

  try {
    if (editingBookingId !== null) {
      // Update existing booking
      await db.collection('bookings').doc(editingBookingId).update({
        start_date,
        end_date,
        updated_at: firebase.firestore.FieldValue.serverTimestamp()
      });
      alert('Booking updated successfully.');
    } else {
      // Create new booking
      await db.collection('bookings').add({
        asset_id: currentAssetId,
        user_id: currentUser.uid,
        company_id: currentUserCompanyId,
        start_date,
        end_date,
        created_at: firebase.firestore.FieldValue.serverTimestamp(),
        updated_at: firebase.firestore.FieldValue.serverTimestamp()
      });
      alert('Booking created successfully.');
    }
    bookingModal.classList.add('hidden');
    bookingForm.reset();
    await loadBookings();
    renderCalendar();
    await displayAssets(); // Refresh asset statuses after booking
  } catch (error) {
    console.error('Error saving booking:', error);
    alert('An error occurred while saving the booking.');
  }
});

// ====================
// 6. Calendar Rendering
// ====================

// Calendar Navigation Buttons
prevMonthBtn.addEventListener('click', () => {
  currentDate.setMonth(currentDate.getMonth() - 1);
  renderCalendar();
});

nextMonthBtn.addEventListener('click', () => {
  currentDate.setMonth(currentDate.getMonth() + 1);
  renderCalendar();
});

// Render Calendar
function renderCalendar() {
  // Clear existing calendar
  calendarDiv.innerHTML = '';

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  const date = new Date(currentDate);
  const month = date.getMonth();
  const year = date.getFullYear();
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  calendarMonthYear.textContent = `${monthNames[month]} ${year}`;

  // Days of the week headers
  const daysHeader = document.createElement('div');
  daysHeader.classList.add('calendar-header');
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  dayNames.forEach((day) => {
    const dayDiv = document.createElement('div');
    dayDiv.classList.add('calendar-day-header');
    dayDiv.textContent = day;
    daysHeader.appendChild(dayDiv);
  });
  calendarDiv.appendChild(daysHeader);

  // Dates Grid
  const datesGrid = document.createElement('div');
  datesGrid.classList.add('calendar-grid');

  // Empty cells for days before the first day
  for (let i = 0; i < firstDay; i++) {
    const emptyCell = document.createElement('div');
    emptyCell.classList.add('calendar-day', 'empty');
    datesGrid.appendChild(emptyCell);
  }

  // Days of the month
  for (let day = 1; day <= daysInMonth; day++) {
    const dayCell = document.createElement('div');
    dayCell.classList.add('calendar-day');
    dayCell.dataset.date = `${year}-${('0' + (month + 1)).slice(-2)}-${('0' + day).slice(-2)}`;

    const dayNumber = document.createElement('span');
    dayNumber.classList.add('day-number');
    dayNumber.textContent = day;
    dayCell.appendChild(dayNumber);

    // Add booking bars
    const bookingsForDay = bookings.filter((booking) => {
      const bookingStart = new Date(booking.start_date);
      const bookingEnd = new Date(booking.end_date);
      const currentDayDate = new Date(year, month, day);
      // Normalize dates to remove time component
      const normalizedBookingStart = new Date(bookingStart.getFullYear(), bookingStart.getMonth(), bookingStart.getDate());
      const normalizedBookingEnd = new Date(bookingEnd.getFullYear(), bookingEnd.getMonth(), bookingEnd.getDate());
      const normalizedCurrentDay = new Date(currentDayDate.getFullYear(), currentDayDate.getMonth(), currentDayDate.getDate());
      return normalizedBookingStart <= normalizedCurrentDay && normalizedBookingEnd >= normalizedCurrentDay;
    });

    if (bookingsForDay.length > 0) {
      const bookingBar = document.createElement('div');
      bookingBar.classList.add('booking-bar');
      bookingBar.title = `${bookingsForDay.length} Booking(s)`;
      dayCell.appendChild(bookingBar);
    }

    datesGrid.appendChild(dayCell);
  }

  // Empty cells after the last day
  const totalCells = firstDay + daysInMonth;
  const remainingCells = totalCells % 7 === 0 ? 0 : 7 - (totalCells % 7);
  for (let i = 0; i < remainingCells; i++) {
    const emptyCell = document.createElement('div');
    emptyCell.classList.add('calendar-day', 'empty');
    datesGrid.appendChild(emptyCell);
  }

  calendarDiv.appendChild(datesGrid);
}

// ====================
// 7. Helper Functions
// ====================

// Format Date to YYYY-MM-DD
function formatDateToYYYYMMDD(dateStr) {
  const date = new Date(dateStr);
  const year = date.getFullYear();
  const month = ('0' + (date.getMonth() + 1)).slice(-2);
  const day = ('0' + date.getDate()).slice(-2);
  return `${year}-${month}-${day}`;
}
