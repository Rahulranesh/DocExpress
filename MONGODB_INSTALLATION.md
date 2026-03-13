# MongoDB Backend - Setup & Troubleshooting Guide

## ✅ What Was Fixed

1. **Removed deprecated Mongoose options** from `src/config/database.js`
   - Removed `useNewUrlParser: true` 
   - Removed `useUnifiedTopology: true`
   - These options are not supported in Mongoose v6+

2. **Fixed `.env` file loading** in `src/server.js`
   - Updated to load `.env` from parent directory when running from `src/` folder
   - Ensures environment variables are correctly read

3. **Updated `.env` configuration**
   - Defaulted to local MongoDB for easy testing
   - Can be switched to MongoDB Atlas later

---

## 🔧 Choose Your MongoDB Setup

### Option 1: Local MongoDB (Recommended for Development)

#### Windows Installation

**Using Chocolatey (Easiest)**
```powershell
# Install Chocolatey if you don't have it
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install MongoDB
choco install mongodb-community

# Start MongoDB service
net start MongoDB
```

**Using Direct Download**
1. Download from https://www.mongodb.com/try/download/community
2. Run installer (choose custom installation)
3. Install MongoDB as Windows Service
4. MongoDB will start automatically

**Verify Installation**
```powershell
mongod --version
mongo --version
```

**Start MongoDB**
```powershell
# Start the service (auto-starts after installation)
net start MongoDB

# Or manually start mongod
mongod
```

#### macOS Installation

**Using Homebrew**
```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
brew services stop mongodb-community  # to stop
```

**Verify**
```bash
mongod --version
which mongod
```

#### Linux Installation (Ubuntu/Debian)

```bash
# Import MongoDB GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Install MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod  # Enable auto-start
```

---

### Option 2: MongoDB Atlas (Cloud - No Installation Needed)

**Steps:**

1. **Create Free Account**
   - Visit https://www.mongodb.com/cloud/atlas
   - Sign up for free account
   - Verify email

2. **Create a Project**
   - Click "New Project"
   - Name it "DocExpress"
   - Add members (optional)
   - Create project

3. **Create a Cluster**
   - Click "Create a Deployment"
   - Choose "M0 Sandbox" (Free tier)
   - Select cloud provider and region
   - Create cluster (takes ~5-10 minutes)

4. **Create a Database User**
   - Go to "Database Access"
   - Click "Add New Database User"
   - Username: `docxpress_user`
   - Password: Generate secure password or set custom
   - Built-in Role: `Atlas Admin` (for development)
   - Add User

5. **Configure Network Access**
   - Go to "Network Access"
   - Click "Add IP Address"
   - Choose "Allow access from anywhere" (0.0.0.0/0) for development
   - ⚠️ For production, whitelist specific IPs only
   - Confirm

6. **Get Connection String**
   - Go to "Databases" → Cluster → "Connect"
   - Choose "Drivers"
   - Language: Node.js, Version: Latest
   - Copy connection string format

7. **Update `.env` File**
   ```env
   MONGODB_URI=mongodb+srv://docxpress_user:PASSWORD@cluster0.xxxxx.mongodb.net/docxpress?retryWrites=true&w=majority
   ```
   Replace:
   - `PASSWORD` with your database user password
   - `cluster0.xxxxx` with your cluster address

---

## 🚀 Quick Start - After MongoDB Setup

### 1. Verify MongoDB is Running

**Local MongoDB:**
```powershell
# Open new terminal
mongosh

# You should see MongoDB shell prompt
test>
# Type: exit
# Should exit successfully
```

**MongoDB Atlas:**
- No local verification needed
- Can test connection through backend

### 2. Start the Backend Server

```powershell
# From DocExpress\src directory
cd C:\Users\SRIKA\OneDrive\Documents\d\DocExpress\src
node server.js
```

**Expected Output:**
```
✅ MongoDB Connected: localhost
📊 Database: docxpress
🚀 DocExpress API Server
📍 Server running on port 3000
📍 Environment: development
API Base URL: http://localhost:3000/api

✅ Available features:
   • User Authentication (Register/Login)
   • Account Management (Update/Delete)
   ...
```

If you see "MongoDB Connected" - **You're all set! ✅**

---

## 🧪 Test the API

Once server is running, test endpoints in new terminal:

### Register a User
```powershell
$body = @{
    name = "Test User"
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3000/api/auth/register" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body | Select-Object -ExpandProperty Content | ConvertFrom-Json | ConvertTo-Json
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "name": "Test User",
      "email": "test@example.com"
    }
  }
}
```

### Login
```powershell
$body = @{
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body | Select-Object -ExpandProperty Content | ConvertFrom-Json | ConvertTo-Json
```

### Check MongoDB Data

**Using mongosh (local):**
```powershell
mongosh

# In MongoDB shell
use docxpress
db.users.find().pretty()
```

**Using MongoDB Atlas GUI:**
- Go to "Databases" → "Browse Collections"
- Select database and view documents

---

## ❌ Troubleshooting

### Error: "MongoDB connection refused"
**Cause:** MongoDB not running
**Solution:** 
- Windows: `net start MongoDB`
- macOS: `brew services start mongodb-community`
- Linux: `sudo systemctl start mongod`

### Error: "MongoDB disconnected"
**Cause:** MongoDB crashed or connection lost
**Solution:**
- Check MongoDB is still running
- Check firewall isn't blocking connection
- Restart MongoDB service

### Error: "querySrv ENOTFOUND _mongodb._tcp.*.mongodb.net"
**Cause:** Network issue or invalid connection string
**Solution:**
- Check internet connectivity
- Verify MongoDB Atlas username/password
- Check IP whitelist in MongoDB Atlas
- Verify cluster name in connection string

### Error: "Invalid email or password" (on login)
**Cause:** Password hashing issue or credential mismatch
**Solution:**
- Register new user and immediately login
- Check password is correct
- Clear browser cache

### Error: "Port 3000 in use"
**Cause:** Another service using port 3000
**Solution:**
```powershell
# Find process using port 3000
netstat -ano | findstr :3000

# Kill the process (replace PID)
taskkill /PID <PID> /F

# Or change PORT in .env
```

### Server hangs on startup
**Cause:** MongoDB not running or connection timeout
**Solution:**
1. Verify MongoDB is running
2. Check connection string is correct
3. For MongoDB Atlas, ensure IP is whitelisted

---

## 📋 Environment Variables Reference

Update `.env` file as needed:

```env
# MongoDB
# Local: mongodb://localhost:27017/docxpress
# Atlas: mongodb+srv://user:password@cluster.mongodb.net/dbname
MONGODB_URI=mongodb://localhost:27017/docxpress

# Server
NODE_ENV=development
PORT=3000

# JWT (change in production!)
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRE=7d

# CORS
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Storage
STORAGE_ROOT=uploads
```

---

## ✨ Next Steps

1. **Choose MongoDB setup** (Local or Atlas)
2. **Install and start MongoDB**
3. **Start backend server**: `node server.js`
4. **Test API endpoints** (using curl or Postman)
5. **Update Flutter app** API URL
6. **Run Flutter app** and test authentication

---

## 📞 Quick Reference

| Task | Command |
|------|---------|
| Start MongoDB (Windows) | `net start MongoDB` |
| Start MongoDB (macOS) | `brew services start mongodb-community` |
| Start server | `node C:\Users\SRIKA\OneDrive\Documents\d\DocExpress\src\server.js` |
| Connect to local DB | `mongosh` |
| View users | `db.users.find()` |
| Stop server | `Ctrl+C` |
| Stop MongoDB | `net stop MongoDB` / `brew services stop` |

---

## 🎯 Backend Status

✅ **Code is ready**
✅ **Dependencies installed** 
✅ **Configuration fixed**
⏳ **Waiting for MongoDB setup**

Once you have MongoDB running, the backend will work perfectly with Flutter!
