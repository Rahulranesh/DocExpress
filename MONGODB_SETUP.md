# MongoDB Authentication Setup Guide

## Overview
Your DocExpress application now uses MongoDB for user authentication and account management. User data is stored in a centralized database instead of local storage, enabling secure user registration, login, and account deletion.

## Backend Architecture

### Files Configured
1. **Database Connection** (`src/config/database.js`)
   - Connects to MongoDB using Mongoose
   - Configured via `MONGODB_URI` environment variable
   - Supports both local and Atlas MongoDB instances

2. **User Model** (`src/models/User.js`)
   - Stores user information: `name`, `email`, `password`, `role`, `isActive`
   - Automatically hashes passwords using bcryptjs
   - Includes password comparison method for authentication
   - Timestamps for `createdAt` and `updatedAt`

3. **Auth Controller** (`src/controllers/authController.js`)
   - **Register**: Creates new users, validates email uniqueness, generates JWT token
   - **Login**: Authenticates users using email/password, returns JWT token
   - **Get Current User**: Retrieves authenticated user data (protected)
   - **Update Profile**: Updates user name/email (protected)
   - **Change Password**: Updates user password (protected)
   - **Delete Account**: Removes user account permanently (protected)

4. **Auth Routes** (`src/routes/authRoutes.js`)
   - `POST /api/auth/register` - User registration
   - `POST /api/auth/login` - User login
   - `GET /api/auth/me` - Get current user (protected)
   - `PUT /api/auth/profile` - Update profile (protected)
   - `PUT /api/auth/change-password` - Change password (protected)
   - `DELETE /api/auth/account` - Delete account (protected)

5. **Auth Middleware** (`src/middleware/auth.js`)
   - Verifies JWT tokens in Authorization header
   - Protects routes that require authentication
   - Handles token validation and user lookup

## Frontend Architecture

### Flutter Implementation

1. **AuthRepository** (`flutter_app/lib/repositories/auth_repository.dart`)
   - Communicates with backend API
   - Handles user registration, login, logout
   - Manages password changes and profile updates
   - Performs account deletion with password confirmation
   - Stores JWT token and user data locally via `StorageService`

2. **Auth State Management** (`flutter_app/lib/providers/providers.dart`)
   - `AuthRepository` provider: Creates API-based auth repository
   - `AuthStateNotifier`: Manages authentication state
   - `authStateProvider`: Provides authentication state to UI
   - `currentUserProvider`: Provides current logged-in user
   - `isAuthenticatedProvider`: Provides authentication status

3. **API Service** (`flutter_app/lib/services/api_service.dart`)
   - Handles HTTP requests to backend
   - Automatically includes JWT token in requests
   - Implements interceptors for token management
   - Base URL configured in `AppConstants`

4. **Storage Service** (`flutter_app/lib/services/storage_service.dart`)
   - Securely stores JWT token in device storage
   - Stores user profile information
   - Methods: `saveToken()`, `getToken()`, `deleteToken()`, `saveUser()`, `getUser()`, `deleteUser()`

## Setup Instructions

### Backend Setup

1. **Install Dependencies**
   ```bash
   cd DocExpress
   npm install mongoose bcryptjs jsonwebtoken dotenv
   ```

2. **Configure Environment Variables** (`.env` file)
   ```env
   NODE_ENV=development
   PORT=3000
   
   # MongoDB - Choose one:
   # Local: mongodb://localhost:27017/docxpress
   # Atlas: mongodb+srv://username:password@cluster.mongodb.net/docxpress
   MONGODB_URI=mongodb://localhost:27017/docxpress
   
   # JWT Configuration
   JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
   JWT_EXPIRE=7d
   
   # Other settings
   CORS_ORIGIN=*
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX_REQUESTS=100
   STORAGE_ROOT=uploads
   ```

3. **Start MongoDB**
   - **Local MongoDB**:
     ```bash
     # Windows
     mongod
     
     # macOS (with Homebrew)
     brew services start mongodb-community
     ```
   - **MongoDB Atlas** (Cloud):
     - Create account at https://www.mongodb.com/cloud/atlas
     - Create cluster and get connection string
     - Add connection string to `.env` file

4. **Start the Server**
   ```bash
   cd src
   node server.js
   ```
   You should see:
   ```
   ✅ MongoDB Connected
   🚀 DocXpress API Server
   📍 Server running on port 3000
   ```

### Frontend Setup

1. **API Base URL** (`flutter_app/lib/core/constants/app_constants.dart`)
   - Production: `https://doc-backend-1-187r.onrender.com/api` (default)
   - Local Development (Android Emulator): `http://10.0.2.2:3000/api`
   - Local Development (Physical Device): `http://YOUR_IP:3000/api`

2. **Build and Run Flutter App**
   ```bash
   cd flutter_app
   flutter pub get
   flutter run
   ```

## User Authentication Flow

### Registration
1. User enters name, email, and password
2. App sends `POST /api/auth/register` request
3. Backend validates email uniqueness
4. Backend hashes password using bcryptjs
5. Backend creates new user in MongoDB
6. Backend returns JWT token
7. App stores token and user data in secure storage
8. User is authenticated and can access app

### Login
1. User enters email and password
2. App sends `POST /api/auth/login` request
3. Backend finds user by email
4. Backend compares password using bcryptjs
5. Backend generates JWT token (valid for 7 days)
6. App stores token and user data in secure storage
7. Subsequent API requests include token in header: `Authorization: Bearer {token}`

### Delete Account
1. User clicks "Delete Account" from settings
2. App shows confirmation dialogs
3. User enters password for confirmation
4. App sends `DELETE /api/auth/account` request with password
5. Backend verifies password
6. Backend removes user from MongoDB
7. Backend returns success response
8. App clears stored token and user data
9. User is logged out and redirected to login screen

## API Response Format

### Successful Registration/Login
```json
{
  "success": true,
  "message": "Registration/Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Email already registered"
}
```

## Security Features

1. **Password Hashing**: Bcryptjs with salt rounds of 10
2. **JWT Tokens**: 7-day expiration, signed with secret key
3. **Secure Storage**: Flutter secure storage with encrypted preferences
4. **CORS Protection**: Whitelist origins
5. **Rate Limiting**: 100 requests per 15 minutes
6. **Account Confirmation**: Password required for account deletion

## Testing the Auth Flow

### Using cURL or Postman

1. **Register a User**
   ```bash
   curl -X POST http://localhost:3000/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "name": "John Doe",
       "email": "john@example.com",
       "password": "password123"
     }'
   ```

2. **Login**
   ```bash
   curl -X POST http://localhost:3000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "john@example.com",
       "password": "password123"
     }'
   ```

3. **Get Current User** (use token from login response)
   ```bash
   curl -X GET http://localhost:3000/api/auth/me \
     -H "Authorization: Bearer {token}"
   ```

4. **Delete Account**
   ```bash
   curl -X DELETE http://localhost:3000/api/auth/account \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer {token}" \
     -d '{"password": "password123"}'
   ```

## Troubleshooting

### MongoDB Connection Issues
- **Error**: `MongoDB Connection Error`
- **Solutions**:
  - Verify MongoDB is running: `mongod` (local) or check Atlas status
  - Check `MONGODB_URI` in `.env` file
  - Ensure network access in MongoDB Atlas (IP whitelist)

### JWT Secret Issues
- **Error**: `Invalid or expired token`
- **Solutions**:
  - Change `JWT_SECRET` in `.env` to a strong key
  - Keep secret consistent between backend and frontend

### CORS Issues
- **Error**: `CORS error: No 'Access-Control-Allow-Origin' header`
- **Solutions**:
  - Update `CORS_ORIGIN` in `.env`
  - For development, use `CORS_ORIGIN=*`
  - For production, specify exact frontend URL

### Token Not Being Sent
- **Error**: `Not authorized to access this route`
- **Solutions**:
  - Verify token is saved in secure storage
  - Check API interceptor is adding `Authorization` header
  - Ensure token format is `Bearer {token}`

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | development | Environment mode |
| `PORT` | 3000 | Server port |
| `MONGODB_URI` | None | MongoDB connection string |
| `JWT_SECRET` | None | JWT signing secret key |
| `JWT_EXPIRE` | 7d | Token expiration time |
| `CORS_ORIGIN` | * | CORS allowed origin |
| `RATE_LIMIT_WINDOW_MS` | 900000 | Rate limit window (ms) |
| `RATE_LIMIT_MAX_REQUESTS` | 100 | Max requests per window |
| `STORAGE_ROOT` | uploads | Upload storage directory |

## Next Steps

1. Test the authentication flow using curl/Postman
2. Deploy MongoDB (using Atlas or managed service)
3. Deploy backend to cloud (Railway, Render, Heroku, etc.)
4. Update `defaultBaseUrl` in Flutter app to production URL
5. Build and release Flutter app to Play Store/App Store
