#!/bin/bash

# Fix for index.html not found error during frontend build

echo "🔍 Diagnosing frontend build issue..."

# Check if index.html exists
if [ -f "/app/frontend/public/index.html" ]; then
    echo "✅ index.html exists in /app/frontend/public/"
else
    echo "❌ index.html not found in /app/frontend/public/"
    echo "Creating index.html..."
    
    # Create public directory if it doesn't exist
    mkdir -p /app/frontend/public
    
    # Create index.html
    cat > /app/frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta
      name="description"
      content="FleetManager Pro - Professional Fleet Management Platform"
    />
    <title>FleetManager Pro</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF
    echo "✅ Created index.html"
fi

# Check file permissions
echo "📁 Checking file permissions..."
ls -la /app/frontend/public/

# Check if .dockerignore is blocking the public directory
if [ -f "/app/frontend/.dockerignore" ]; then
    echo "📄 Checking .dockerignore..."
    if grep -q "public" /app/frontend/.dockerignore; then
        echo "⚠️  .dockerignore contains 'public' - this might be the issue!"
        echo "Removing 'public' from .dockerignore..."
        sed -i '/^public$/d' /app/frontend/.dockerignore
        sed -i '/^public\/$/d' /app/frontend/.dockerignore
    else
        echo "✅ .dockerignore doesn't block public directory"
    fi
fi

# Create or update .dockerignore to ensure public is not ignored
cat > /app/frontend/.dockerignore << 'EOF'
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.git
.gitignore
README.md
.env.local
.env.development.local
.env.test.local
.env.production.local
coverage
.nyc_output
EOF

echo "✅ Updated .dockerignore"

# Ensure all required React files are present
echo "📋 Checking required React files..."

# Check for src/index.js
if [ ! -f "/app/frontend/src/index.js" ]; then
    echo "❌ src/index.js not found, creating..."
    mkdir -p /app/frontend/src
    cat > /app/frontend/src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
fi

# Create a simple index.css if it doesn't exist
if [ ! -f "/app/frontend/src/index.css" ]; then
    echo "Creating basic index.css..."
    cat > /app/frontend/src/index.css << 'EOF'
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF
fi

# Test build locally first
echo "🔨 Testing local build..."
cd /app/frontend

# Clear any existing build
rm -rf build/

# Try yarn build
echo "Running yarn build..."
if yarn build; then
    echo "✅ Local build successful!"
    echo "Build output:"
    ls -la build/ 2>/dev/null || echo "No build directory created"
else
    echo "❌ Local build failed"
    echo "This might be a dependency issue. Let's check..."
    
    # Try installing dependencies again
    echo "Reinstalling dependencies..."
    rm -rf node_modules yarn.lock
    yarn install
    
    echo "Retrying build..."
    yarn build
fi

cd /app

echo ""
echo "🛠️  Fix applied! Try running your deployment again:"
echo "   ./setup.sh prod"
echo "   OR"
echo "   docker-compose up --build"