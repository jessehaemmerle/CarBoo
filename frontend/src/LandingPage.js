import React, { useState } from "react";
import "./LandingPage.css";

const LandingPage = ({ onGetStarted }) => {
  const [activeTab, setActiveTab] = useState('features');

  const features = [
    {
      icon: "🚗",
      title: "Fleet Management",
      description: "Complete vehicle lifecycle management with real-time tracking and maintenance scheduling."
    },
    {
      icon: "👥",
      title: "Multi-User Access",
      description: "Role-based access control for fleet managers and employees with secure authentication."
    },
    {
      icon: "📅",
      title: "Booking System",
      description: "Streamlined car booking with approval workflows and availability checking."
    },
    {
      icon: "📊",
      title: "Analytics & Reports",
      description: "Comprehensive dashboards with fleet utilization metrics and cost tracking."
    },
    {
      icon: "🔧",
      title: "Maintenance Tracking",
      description: "Proactive maintenance scheduling with downtime management and cost monitoring."
    },
    {
      icon: "🌐",
      title: "Free & Open Platform",
      description: "Complete fleet management solution with no limits on vehicles, users, or features."
    }
  ];

  const testimonials = [
    {
      name: "Sarah Johnson",
      title: "Fleet Manager, TechCorp",
      content: "FleetManager Pro transformed our vehicle operations. We reduced downtime by 40% and improved booking efficiency significantly.",
      avatar: "👩‍💼"
    },
    {
      name: "Mike Chen",
      title: "Operations Director, LogiFlow",
      content: "The multi-tenant architecture was perfect for our enterprise needs. Each department manages their own fleet independently.",
      avatar: "👨‍💼"
    },
    {
      name: "Emma Rodriguez",
      title: "Fleet Coordinator, GreenTrans",
      content: "Outstanding support and intuitive interface. Our team was up and running in minutes with the comprehensive booking system.",
      avatar: "👩‍🔧"
    }
  ];

  return (
    <div className="landing-page">
      {/* Header */}
      <header className="landing-header">
        <div className="container">
          <div className="nav">
            <div className="logo">
              <span className="logo-icon">🚗</span>
              <span className="logo-text">FleetManager Pro</span>
            </div>
            <div className="nav-links">
              <a href="#features">Features</a>
              <a href="#about">About</a>
              <button className="btn-secondary" onClick={() => onGetStarted('login')}>
                Sign In
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="hero">
        <div className="container">
          <div className="hero-content">
            <div className="hero-text">
              <h1>
                Manage Your Fleet
                <span className="highlight"> Like a Pro</span>
              </h1>
              <p className="hero-description">
                Complete fleet management solution for modern businesses. Track vehicles, 
                manage bookings, schedule maintenance, and optimize your fleet operations 
                with our powerful platform - completely free.
              </p>
              <div className="hero-buttons">
                <button 
                  className="btn-primary large"
                  onClick={() => onGetStarted('register')}
                >
                  Get Started
                </button>
                <button className="btn-secondary large">
                  Watch Demo
                </button>
              </div>
              <div className="hero-stats">
                <div className="stat">
                  <div className="stat-number">500+</div>
                  <div className="stat-label">Companies</div>
                </div>
                <div className="stat">
                  <div className="stat-number">10K+</div>
                  <div className="stat-label">Vehicles</div>
                </div>
                <div className="stat">
                  <div className="stat-number">99.9%</div>
                  <div className="stat-label">Uptime</div>
                </div>
              </div>
            </div>
            <div className="hero-image">
              <img 
                src="https://images.unsplash.com/photo-1558618047-b0d94c37cceb" 
                alt="Fleet Management Dashboard"
                className="dashboard-preview"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="features">
        <div className="container">
          <div className="section-header">
            <h2>Powerful Features for Modern Fleet Management</h2>
            <p>Everything you need to manage your fleet efficiently and cost-effectively</p>
          </div>
          <div className="features-grid">
            {features.map((feature, index) => (
              <div key={index} className="feature-card">
                <div className="feature-icon">{feature.icon}</div>
                <h3>{feature.title}</h3>
                <p>{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="testimonials">
        <div className="container">
          <div className="section-header">
            <h2>Trusted by Industry Leaders</h2>
            <p>See what our customers say about FleetManager Pro</p>
          </div>
          <div className="testimonials-grid">
            {testimonials.map((testimonial, index) => (
              <div key={index} className="testimonial-card">
                <div className="testimonial-content">
                  <p>"{testimonial.content}"</p>
                </div>
                <div className="testimonial-author">
                  <div className="author-avatar">{testimonial.avatar}</div>
                  <div className="author-info">
                    <div className="author-name">{testimonial.name}</div>
                    <div className="author-title">{testimonial.title}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="cta">
        <div className="container">
          <div className="cta-content">
            <h2>Ready to Transform Your Fleet Management?</h2>
            <p>Join hundreds of companies already using FleetManager Pro to optimize their operations</p>
            <div className="cta-buttons">
              <button 
                className="btn-primary large"
                onClick={() => onGetStarted('register')}
              >
                Get Started
              </button>
              <button className="btn-secondary large">
                Schedule Demo
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="footer-section">
              <div className="footer-logo">
                <span className="logo-icon">🚗</span>
                <span className="logo-text">FleetManager Pro</span>
              </div>
              <p>The complete fleet management solution for modern businesses.</p>
            </div>
            <div className="footer-section">
              <h4>Product</h4>
              <ul>
                <li><a href="#features">Features</a></li>
                <li><a href="#demo">Demo</a></li>
                <li><a href="#api">API</a></li>
              </ul>
            </div>
            <div className="footer-section">
              <h4>Company</h4>
              <ul>
                <li><a href="#about">About</a></li>
                <li><a href="#blog">Blog</a></li>
                <li><a href="#careers">Careers</a></li>
                <li><a href="#contact">Contact</a></li>
              </ul>
            </div>
            <div className="footer-section">
              <h4>Support</h4>
              <ul>
                <li><a href="#docs">Documentation</a></li>
                <li><a href="#help">Help Center</a></li>
                <li><a href="#status">Status</a></li>
                <li><a href="#security">Security</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <p>&copy; 2024 FleetManager Pro. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;