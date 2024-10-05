// settings.js

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
  
  // DOM Elements
  const darkModeToggle = document.getElementById('dark-mode-toggle');
  
  // Function to apply the theme based on preference
  function applyTheme(isDark) {
    if (isDark) {
      document.body.classList.add('dark-mode');
    } else {
      document.body.classList.remove('dark-mode');
    }
  }
  
  // Load theme preference on page load
  window.addEventListener('DOMContentLoaded', () => {
    const theme = localStorage.getItem('theme');
    if (theme === 'dark') {
      darkModeToggle.checked = true;
      applyTheme(true);
    } else {
      darkModeToggle.checked = false;
      applyTheme(false);
    }
  });
  
  // Event listener for the dark mode toggle
  darkModeToggle.addEventListener('change', () => {
    if (darkModeToggle.checked) {
      applyTheme(true);
      localStorage.setItem('theme', 'dark');
    } else {
      applyTheme(false);
      localStorage.setItem('theme', 'light');
    }
  });
  
  // ====================
  // 1. Authentication State Handling
  // ====================
  
  let currentUser = null;
  let currentUserRole = 'user'; // Default role
  let currentUserCompanyId = null;
  
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
    } else {
      // If user is not authenticated, redirect to login page
      window.location.href = 'login.html';
    }
  });
  
  // Function to update the user interface based on authentication and role
  function updateUserInterface() {
    if (currentUser) {
      const userInfoDiv = document.getElementById('user-info');
      userInfoDiv.innerHTML = `
        <span>Welcome, ${currentUser.email} (${currentUserRole})</span>
        <button id="logout-btn">Logout</button>
      `;
      document.getElementById('logout-btn').addEventListener('click', logout);
    } else {
      // No user is signed in
      const userInfoDiv = document.getElementById('user-info');
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
  