# Quick Start - MongoDB Backend Setup

## 1. Backend Configuration

### Install Dependencies (if not already installed)
```bash
cd DocExpress
npm install mongoose bcryptjs jsonwebtoken
```

### Create `.env` File
Create a file named `.env` in the `DocExpress` directory with the following content:

```env
# Environment Configuration
NODE_ENV=development

# Server Configuration
PORT=3000

# MongoDB Configuration
# Use MongoDB locally or Atlas cloud
MONGODB_URI=mongodb://localhost:27017/docxpress

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRE=7d

# CORS Configuration
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Storage Configuration
STORAGE_ROOT=uploads
```

## 2. Start MongoDB

### Option A: Local MongoDB
```bash
# Windows
mongod

# macOS (with Homebrew)
brew services start mongodb-community
```

### Option B: MongoDB Atlas (Cloud)
1. Visit https://www.mongodb.com/cloud/atlas
2. Create free account and cluster
3. Get connection string: `mongodb+srv://username:password@cluster...`
4. Update `MONGODB_URI` in `.env`

## 3. Start the Backend Server

```bash
cd DocExpress/src
node server.js
```

Expected output:
```
✅ MongoDB Connected: localhost
📊 Database: docxpress
🚀 DocXpress API Server
📍 Server running on port 3000
📍 Environment: development
```

## 4. Test the API

### Register a User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }'
```

Response:
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "name": "Test User",
      "email": "test@example.com",
      "role": "user",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  }
}
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## 5. Configure Flutter App

### Update API Base URL (if running locally)
Edit `flutter_app/lib/core/constants/app_constants.dart`:

```dart
// For Android Emulator:
static const String defaultBaseUrl = 'http://10.0.2.2:3000/api';

// For Physical Device (replace YOUR_IP with your machine IP):
static const String defaultBaseUrl = 'http://YOUR_IP:3000/api';

// For Production:
static const String defaultBaseUrl = 'https://your-deployed-backend.com/api';
```

### Run Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```

## 6. Feature Summary

✅ **User Registration** - Create new accounts stored in MongoDB
✅ **User Login** - Authenticate with email/password, get JWT token  
✅ **Delete Account** - Delete user account permanently from database
✅ **Password Hashing** - Bcryptjs automatically hashes passwords
✅ **JWT Authentication** - Token-based API authentication
✅ **Secure Storage** - Token stored securely on device
✅ **CORS Protection** - Cross-origin request protection
✅ **Rate Limiting** - API abuse prevention

## 7. Database Schema

Users in MongoDB are stored with:
- `name` (string) - User's full name
- `email` (string) - User's email (unique)
- `password` (string) - Hashed password
- `role` (string) - 'user' or 'admin', defaults to 'user'
- `isActive` (boolean) - Account status, defaults to true
- `createdAt` (date) - Account creation timestamp
- `updatedAt` (date) - Last update timestamp

## 8. Troubleshooting

| Issue | Solution |
|-------|----------|
| `MONGODB_URI is not defined` | Create `.env` file with `MONGODB_URI` |
| `MongoDB Connection Error` | Start MongoDB service (mongod or brew services) |
| `Cannot find module 'mongoose'` | Run `npm install mongoose bcryptjs jsonwebtoken` |
| `JWT_SECRET is not defined` | Add `JWT_SECRET` to `.env` file |
| `CORS error` | Change `CORS_ORIGIN` to Match your frontend URL |

## 9. Next Steps

- [ ] Install dependencies: `npm install`
- [ ] Create `.env` file with MongoDB URI
- [ ] Start MongoDB service
- [ ] Start backend: `node src/server.js`
- [ ] Test registration/login with curl
- [ ] Update Flutter app API base URL
- [ ] Run Flutter app and test auth flow
- [ ] Deploy MongoDB (Atlas or managed service)
- [ ] Deploy backend (Railway, Render, Heroku, etc.)
- [ ] Update production API URL in Flutter app

## Useful Commands

```bash
# Start backend in development mode with auto-reload
npm run dev

# Start backend in production mode
npm start

# Connect to MongoDB locally
mongosh

# View all users
db.users.find()

# Delete a user
db.users.deleteOne({ email: "test@example.com" })
```
