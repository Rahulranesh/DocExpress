# DocXpress Backend Setup Guide

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or Atlas)
- npm or yarn

## MongoDB Configuration

### Option 1: Local MongoDB

1. **Install MongoDB** (if not already installed)
   ```bash
   # macOS
   brew install mongodb-community
   brew services start mongodb-community

   # Ubuntu/Debian
   sudo apt-get install -y mongodb
   sudo systemctl start mongodb

   # Windows
   # Download from https://www.mongodb.com/try/download/community
   ```

2. **Verify MongoDB is running**
   ```bash
   mongosh
   ```

### Option 2: MongoDB Atlas (Cloud)

1. **Create MongoDB Atlas Account**
   - Go to https://www.mongodb.com/cloud/atlas
   - Sign up for free account
   - Create a new project

2. **Create a Cluster**
   - Click "Create" to build a new cluster
   - Choose free tier (M0)
   - Select your region
   - Click "Create Cluster"

3. **Get Connection String**
   - Go to "Clusters" → "Connect"
   - Choose "Connect your application"
   - Copy the connection string
   - Replace `<password>` with your database password

## Backend Environment Setup

### 1. Create `.env` file in backend root directory

```env
# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017/docxpress
# OR for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/docxpress?retryWrites=true&w=majority

# Server Configuration
PORT=5000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here_change_in_production
JWT_EXPIRE=7d

# File Upload Configuration
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=104857600

# API Configuration
API_BASE_URL=http://localhost:5000
CORS_ORIGIN=http://localhost:3000,http://localhost:8080

# Optional: Third-party services
# CLOUDINARY_CLOUD_NAME=your_cloudinary_name
# CLOUDINARY_API_KEY=your_api_key
# CLOUDINARY_API_SECRET=your_api_secret
```

### 2. Install Backend Dependencies

```bash
cd backend
npm install
```

### 3. Start Backend Server

```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The server will start on `http://localhost:5000`

## Flutter App Configuration

The Flutter app is already configured to connect to:
- **Backend URL**: `http://localhost:3000/api` (default)
- **API Endpoints**: All configured in `lib/core/constants/app_constants.dart`

### Update Backend URL (if needed)

Edit `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String defaultBaseUrl = 'http://localhost:3000/api';
  // Change to your backend URL
}
```

Or update at runtime via the `baseUrlProvider`:

```dart
final baseUrl = ref.watch(baseUrlProvider);
ref.read(baseUrlProvider.notifier).state = 'http://your-backend-url/api';
```

## Database Initialization

### 1. Create Database Collections

The backend will automatically create collections on first use. However, you can manually create them:

```javascript
// MongoDB shell
use docxpress

// Create collections
db.createCollection("users")
db.createCollection("files")
db.createCollection("jobs")
db.createCollection("notes")

// Create indexes
db.users.createIndex({ email: 1 }, { unique: true })
db.files.createIndex({ userId: 1 })
db.jobs.createIndex({ userId: 1 })
db.notes.createIndex({ userId: 1 })
```

### 2. Seed Initial Data (Optional)

```javascript
// Add test user
db.users.insertOne({
  _id: ObjectId(),
  email: "test@example.com",
  password: "hashed_password",
  name: "Test User",
  createdAt: new Date(),
  updatedAt: new Date()
})
```

## Testing the Setup

### 1. Test Backend Connection

```bash
curl http://localhost:5000/api/health
```

Expected response:
```json
{
  "status": "ok",
  "message": "Server is running"
}
```

### 2. Test MongoDB Connection

```bash
curl http://localhost:5000/api/db/status
```

### 3. Run Backend Tests

```bash
npm test
```

## Flutter App Testing

### 1. Run Flutter App

```bash
cd flutter_app
flutter run -d linux
# or
flutter run -d chrome
```

### 2. Test Authentication

1. Click "Register" on login screen
2. Enter email and password
3. Click "Register"
4. Should redirect to home screen after successful registration

### 3. Test File Operations

1. Go to any compression/conversion screen
2. Select a file
3. Process should start
4. Check jobs screen for job status

## Troubleshooting

### MongoDB Connection Error

**Error**: `MongoServerError: connect ECONNREFUSED 127.0.0.1:27017`

**Solution**:
- Ensure MongoDB is running: `sudo systemctl status mongodb`
- Check MongoDB URI in `.env` file
- Verify MongoDB port (default: 27017)

### CORS Error

**Error**: `Access to XMLHttpRequest blocked by CORS policy`

**Solution**:
- Update `CORS_ORIGIN` in `.env`
- Ensure backend is running
- Check if frontend URL matches CORS configuration

### JWT Token Error

**Error**: `Invalid token` or `Token expired`

**Solution**:
- Clear app cache: `flutter clean`
- Re-login to get new token
- Check `JWT_SECRET` matches between frontend and backend

### File Upload Error

**Error**: `File upload failed`

**Solution**:
- Check `UPLOAD_DIR` exists and has write permissions
- Verify `MAX_FILE_SIZE` is sufficient
- Check available disk space

## Production Deployment

### 1. Update Environment Variables

```env
NODE_ENV=production
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/docxpress
JWT_SECRET=generate_strong_secret_key
API_BASE_URL=https://your-domain.com
CORS_ORIGIN=https://your-domain.com
```

### 2. Build Flutter App for Release

```bash
flutter build linux --release
# or
flutter build web --release
```

### 3. Deploy Backend

- Use services like Heroku, Railway, Render, or AWS
- Set environment variables on hosting platform
- Ensure MongoDB Atlas is configured for production

### 4. Update Flutter App

- Update `defaultBaseUrl` to production backend URL
- Build and release app

## Security Checklist

- [ ] Change `JWT_SECRET` to a strong random string
- [ ] Enable MongoDB authentication
- [ ] Use HTTPS for production
- [ ] Set `NODE_ENV=production`
- [ ] Configure CORS properly
- [ ] Enable rate limiting
- [ ] Use environment variables for sensitive data
- [ ] Regular backups of MongoDB
- [ ] Monitor API logs
- [ ] Keep dependencies updated

## Support

For issues or questions:
1. Check backend logs: `npm run dev`
2. Check Flutter console: `flutter run -v`
3. Verify MongoDB connection: `mongosh`
4. Check network connectivity: `curl http://localhost:5000/api/health`

## Additional Resources

- [MongoDB Documentation](https://docs.mongodb.com/)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Express.js Guide](https://expressjs.com/)
