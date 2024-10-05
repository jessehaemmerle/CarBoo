// signup.js

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
  
  const signupForm = document.getElementById('signup-form');
  const signupEmailInput = document.getElementById('signup-email');
  const signupPasswordInput = document.getElementById('signup-password');
  const signupCompanySelect = document.getElementById('signup-company');
  const errorMessageDiv = document.getElementById('error-message');
  
  // ====================
  // 3. Populate Companies Dropdown
  // ====================
  
  async function populateCompanies() {
    try {
      const snapshot = await db.collection('companies').get();
      snapshot.forEach(doc => {
        const option = document.createElement('option');
        option.value = doc.id;
        option.textContent = doc.data().name;
        signupCompanySelect.appendChild(option);
      });
    } catch (error) {
      console.error('Error fetching companies:', error);
      displayErrorMessage('An error occurred while fetching companies.');
    }
  }
  
  // Populate companies on page load
  populateCompanies();
  
  // ====================
  // 4. Handle Signup Form Submission
  // ====================
  
  signupForm.addEventListener('submit', async (e) => {
    e.preventDefault(); // Prevent form from submitting the traditional way
  
    const email = signupEmailInput.value.trim();
    const password = signupPasswordInput.value;
    const company_id = signupCompanySelect.value;
  
    if (!company_id) {
      displayErrorMessage('Please select a company.');
      return;
    }
  
    try {
      // Create the user
      const userCredential = await auth.createUserWithEmailAndPassword(email, password);
      const user = userCredential.user;
  
      // Send verification email
      await user.sendEmailVerification();
  
      // Set user data in Firestore
      await db.collection('users').doc(user.uid).set({
        email: email,
        role: 'user', // Default role; admins can be assigned manually
        company_id: company_id
      });
  
      alert('Signup successful! A verification email has been sent to your email address. Please verify your email before logging in.');
      // Redirect to login page
      window.location.href = 'login.html';
    } catch (error) {
      console.error('Signup Error:', error);
      let errorMessage = 'An error occurred during signup.';
      switch (error.code) {
        case 'auth/email-already-in-use':
          errorMessage = 'This email is already in use.';
          break;
        case 'auth/invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'auth/weak-password':
          errorMessage = 'Password should be at least 6 characters.';
          break;
        default:
          errorMessage = error.message;
      }
      displayErrorMessage(errorMessage);
    }
  });
  
  // ====================
  // 5. Helper Function to Display Error Messages
  // ====================
  
  function displayErrorMessage(message) {
    errorMessageDiv.textContent = message;
    errorMessageDiv.style.color = 'red'; // Style as needed
  }
  
  // ====================
  // 6. Clear Error Message on Input Focus
  // ====================
  
  signupEmailInput.addEventListener('focus', () => {
    errorMessageDiv.textContent = '';
  });
  signupPasswordInput.addEventListener('focus', () => {
    errorMessageDiv.textContent = '';
  });
  signupCompanySelect.addEventListener('focus', () => {
    errorMessageDiv.textContent = '';
  });
  