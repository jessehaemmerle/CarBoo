// login.js

// ====================
// 1. Firebase Initialization
// ====================

// Firebase Configuration
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

const loginForm = document.getElementById('login-form');
const loginEmailInput = document.getElementById('login-email');
const loginPasswordInput = document.getElementById('login-password');
const errorMessageDiv = document.getElementById('error-message');

// ====================
// 3. Handle Login Form Submission
// ====================

loginForm.addEventListener('submit', async (e) => {
  e.preventDefault(); // Prevent form from submitting the traditional way

  const email = loginEmailInput.value.trim();
  const password = loginPasswordInput.value;

  try {
    // Authenticate the user
    const userCredential = await auth.signInWithEmailAndPassword(email, password);
    const user = userCredential.user;

    // Check if email is verified
    if (!user.emailVerified) {
      displayErrorMessage('Please verify your email before logging in.');
      // Optionally, resend verification email
      const resend = confirm('Would you like us to resend the verification email?');
      if (resend) {
        await user.sendEmailVerification();
        alert('A new verification email has been sent to your email address.');
      }
      // Sign out the user to prevent unauthorized access
      await auth.signOut();
      return;
    }

    // Fetch user data to verify association with a company
    const userDoc = await db.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();

      // Check if the user is associated with a company
      if (userData.company_id) {
        // Redirect to main app page upon successful login
        window.location.href = 'index.html';
      } else {
        displayErrorMessage('Your account is not associated with any company. Please contact support.');
        // Sign out the user to prevent unauthorized access
        await auth.signOut();
      }
    } else {
      displayErrorMessage('User data not found. Please contact support.');
      // Sign out the user to prevent unauthorized access
      await auth.signOut();
    }
  } catch (error) {
    console.error('Login Error:', error);

    // Enhanced Error Handling
    let errorMessage = 'An error occurred during login.';
    switch (error.code) {
      case 'auth/invalid-email':
        errorMessage = 'Invalid email address.';
        break;
      case 'auth/user-disabled':
        errorMessage = 'This user has been disabled.';
        break;
      case 'auth/user-not-found':
        errorMessage = 'No user found with this email.';
        break;
      case 'auth/wrong-password':
        errorMessage = 'Incorrect password.';
        break;
      default:
        errorMessage = error.message;
    }

    // Display error message to the user
    displayErrorMessage(errorMessage);
  }
});

// ====================
// 4. Helper Function to Display Error Messages
// ====================

function displayErrorMessage(message) {
  errorMessageDiv.textContent = message;
  errorMessageDiv.style.color = 'red'; // Style as needed
}

// ====================
// 5. Clear Error Message on Input Focus
// ====================

loginEmailInput.addEventListener('focus', () => {
  errorMessageDiv.textContent = '';
});
loginPasswordInput.addEventListener('focus', () => {
  errorMessageDiv.textContent = '';
});
