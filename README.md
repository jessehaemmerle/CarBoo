# CarBoo - Book Your Ride, Simplified



CarBoo is a web-based application designed to simplify the process of booking and managing vehicle rentals. Whether you're an administrator overseeing a fleet of vehicles or a user looking to book a ride, CarBoo offers a seamless and intuitive experience tailored to your needs.

Visit our live application at [CarBoo](https:carboo.at)

# Table of Contents

    Features
    Technology Stack
    Demo
    Installation
    Usage
    Contributing
    License
    Contact

# Features
## User Authentication

Secure Login & Registration: Users can create accounts and securely log in using Firebase Authentication.
Role-Based Access Control: Differentiate between regular users and administrators to control access to various functionalities.

## Asset Management
Add, Edit, Delete Assets: Administrators can manage a fleet of vehicles with ease.
Search & Filter: Users can search for assets by name or number plate and filter them based on availability status.

## Booking Management
Create Bookings: Users can book available vehicles for desired dates and times.
Edit & Cancel Bookings: Modify or cancel existing bookings as needed.
Conflict Detection: Prevent overlapping bookings to ensure vehicle availability.

## Calendar Integration
All Assets Calendar: View bookings for all assets in a unified calendar view.
Per-Asset Calendar: Administrators can view detailed bookings for individual assets.
Responsive Design: Calendars are designed to be coherent and responsive across all devices.

## Theming
Dark Mode: Toggle between light and dark themes to suit your preference.

## Real-Time Updates
Live Data Sync: Changes to assets and bookings are reflected in real-time across all users.

## Accessibility
ARIA Attributes: Enhanced accessibility features to support users with assistive technologies.
Keyboard Navigation: Navigate through the application seamlessly using the keyboard.

## Technology Stack

### Frontend:
- HTML5
- CSS3 (with CSS Variables for Theming)
- JavaScript (ES6+)

### Backend:
- Firebase
- Firebase Authentication
- Firestore Database

### Hosting:
- Custom Domain

## Demo

<!-- TODO Replace with actual screenshot URLs --> Main Dashboard displaying assets and booking statuses.

Unified calendar view showing all bookings.

Booking creation and management interface.
# Installation

To set up the CarBoo project locally, follow these steps:
## Prerequisites

    Node.js installed on your machine.
    Firebase CLI installed globally.
    A Firebase project set up with Authentication and Firestore enabled.

## Steps

    Clone the Repository

    bash

git clone https://github.com/yourusername/carboo.git
cd carboo

Install Dependencies

bash

npm install

Configure Firebase

    Rename the firebase.example.js file to firebase.js.

    bash

    cp firebase.example.js firebase.js

    Open firebase.js and replace the placeholder Firebase configuration with your project's actual configuration details.

Run the Application Locally

You can use a local development server like Live Server or serve the files using Firebase Hosting.

Using Firebase Hosting:

bash

    firebase login
    firebase init
    firebase serve

    The application will be available at http://localhost:5000 by default.

# Usage
## For Administrators

    Login: Sign in using your admin credentials.
    Manage Assets:
        Add New Asset: Click on the "Add Asset" button, fill in the details, and save.
        Edit Asset: Click on the "Edit" button next to an asset, modify the details, and save.
        Delete Asset: Click on the "Delete" button to remove an asset and all its associated bookings.
    View Bookings:
        All Assets Calendar: View a consolidated calendar of all bookings across assets.
        Per-Asset Calendar: Click on "View Bookings" for a specific asset to see its detailed booking schedule.
    Manage Bookings:
        Create Booking: Use the "Add Booking" button within the Per-Asset Booking Section.
        Edit/Delete Booking: Modify or cancel existing bookings as needed.

## For Regular Users

    Login/Register: Create an account or sign in using existing credentials.
    Search & Filter Assets:
        Use the search bar to find assets by name or number plate.
        Apply filters to view assets based on their availability status.
    Create Bookings:
        Select an available asset and book it for your desired date and time.
        Ensure there are no conflicting bookings before confirming.
    Manage Bookings:
        View your existing bookings.
        Edit or cancel bookings as needed.

# Contributing

We welcome contributions to enhance the functionality and performance of CarBoo! Follow these steps to contribute:

    Fork the Repository

    Click the "Fork" button at the top-right corner of the repository page.

    Clone Your Fork

    bash

git clone https://github.com/yourusername/carboo.git
cd carboo

Create a New Branch

bash

git checkout -b feature/YourFeatureName

Make Your Changes

Implement your feature or bug fix.

Commit Your Changes

bash

git commit -m "Add feature: YourFeatureName"

Push to Your Fork

bash

    git push origin feature/YourFeatureName

    Create a Pull Request

    Navigate to the original repository and click on "Compare & pull request". Provide a clear description of your changes and submit the pull request.

# Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct.
## License

This project is licensed under the MIT License.
# Contact

For any inquiries, suggestions, or support, please reach out to us:

    Email: support@carboo.at
    Website: carboo.at
    Twitter: @CarBooApp
    GitHub: https://github.com/jessehaemmerle/carboo

We look forward to hearing from you!
# Acknowledgements

    Firebase: Providing robust backend services for authentication and database management.
    Google Fonts: For the Roboto font.
    Open Source Community: For continuous support and contributions.

This README was generated with ❤️ by CarBoo Development Team.
