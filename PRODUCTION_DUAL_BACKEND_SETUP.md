# Production Setup - Dual Backend Configuration

## 🎯 Architecture Overview

Your app now uses **TWO separate backends**:

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter App                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Backend 1: Authentication (MongoDB)                  │
│  ├── Login/Register                                    │
│  ├── User Management                                   │
│  └── Account Operations                                │
│  └── NEW Render URL or your hosted server             │
│                                                         │
│  Backend 2: Document/Video Processing                 │
│  ├── Video Compression                                 │
│  ├── Document Conversion                               │
│  ├── Image Extraction                                  │
│  └── OLD Render URL (doc-backend-1-187r.onrender.com) │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Configuration

### Flutter Constants (`app_constants.dart`)

```dart
// Authentication Backend (MongoDB) - NEW
static const String defaultBaseUrl = 'http://10.163.87.180:3000/api';

// Conversion Backend - OLD
static const String conversionBaseUrl = 'https://doc-backend-1-187r.onrender.com/api';
```

Update for production:
```dart
// Authentication Backend - Deploy MongoDB backend to production
static const String defaultBaseUrl = 'https://your-mongodb-backend.onrender.com/api';

// Conversion Backend - Keep OLD endpoint
static const String conversionBaseUrl = 'https://doc-backend-1-187r.onrender.com/api';
```

---

## 📋 What's Using Which Backend

### Backend 1 (Authentication - MongoDB)
✅ User Registration
✅ User Login  
✅ Get Current User
✅ Update Profile
✅ Change Password
✅ Delete Account

**Endpoints:**
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `PUT /api/auth/profile`
- `PUT /api/auth/change-password`
- `DELETE /api/auth/account`

### Backend 2 (Conversions - OLD)
✅ DOCX → PDF
✅ PPTX → PDF
✅ PDF → DOCX
✅ PDF → PPTX
✅ Extract Images from PDF
✅ Video Compression

**Endpoints:**
- `POST /api/simple-convert/docx-to-pdf`
- `POST /api/simple-convert/pptx-to-pdf`
- `POST /api/simple-convert/pdf-to-docx`
- `POST /api/simple-convert/pdf-to-pptx`
- `POST /api/simple-convert/pdf-extract-images`

---

## 🚀 Production Deployment Steps

### Step 1: Deploy Authentication Backend (MongoDB)

**Option A: Deploy to Render**
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click "New +" → "Web Service"
3. Connect your GitHub with MongoDB backend code
4. Set environment variables:
   ```
   NODE_ENV=production
   PORT=3000
   MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/dbname
   JWT_SECRET=your-very-secure-secret-key-min-32-chars
   JWT_EXPIRE=7d
   CORS_ORIGIN=*
   ```
5. Deploy
6. Copy the **deployed URL** (e.g., `https://your-auth-backend.onrender.com`)

**Option B: Deploy to Railway**
1. Go to [Railway.app](https://railway.app)
2. Click "New Project" → "Deploy from GitHub"
3. Select your MongoDB backend repo
4. Set environment variables (same as above)
5. Deploy
6. Copy the **deployed URL**

### Step 2: Update Flutter Constants

Update `app_constants.dart`:
```dart
// NEW MongoDB backend
static const String defaultBaseUrl = 'https://your-auth-backend.onrender.com/api';

// OLD conversion backend (keep as is)
static const String conversionBaseUrl = 'https://doc-backend-1-187r.onrender.com/api';
```

### Step 3: Verify Both Backends Work

Test authentication endpoint:
```powershell
$body = @{
    name = "Test"
    email = "test@example.com"
    password = "TestPass123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://your-auth-backend.onrender.com/api/auth/register" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

Test conversion endpoint:
```powershell
# Upload and convert a file to the OLD backend
Invoke-WebRequest -Uri "https://doc-backend-1-187r.onrender.com/api/simple-convert/health" `
  -Method GET
```

### Step 4: Build and Release Flutter App

```bash
cd flutter_app

# Build APK for Android
flutter build apk --release

# Build IPA for iOS  
flutter build ipa --release

# Build Web
flutter build web --release
```

---

## 🔐 Environment Variables

### MongoDB Backend (.env)
```env
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/docxpress?retryWrites=true&w=majority
JWT_SECRET=your_super_secret_key_minimum_32_characters_long_for_production
JWT_EXPIRE=7d
CORS_ORIGIN=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
STORAGE_ROOT=uploads
```

### Flask Variables
```env
FLASK_ENV=production
DATABASE_URL=your-database-url
API_KEY=your-api-key
```

---

## ✨ Production Checklist

- [ ] MongoDB backend deployed to production URL
- [ ] Flutter `defaultBaseUrl` updated to new backend
- [ ] Flutter `conversionBaseUrl` still points to old backend
- [ ] Both endpoints tested and working
- [ ] SSL/HTTPS enabled on both backends
- [ ] CORS configured correctly
- [ ] JWT_SECRET changed from default
- [ ] Rate limiting enabled
- [ ] Monitoring/logging set up
- [ ] Flutter app rebuilt with production URLs
- [ ] App signed and ready for release

---

## 📝 Code Changes Summary

### 1. app_constants.dart
- ✅ Added `conversionBaseUrl` for old backend
- ✅ Updated `defaultBaseUrl` for new MongoDB backend

### 2. providers.dart
- ✅ Created `conversionApiServiceProvider` with custom URL
- ✅ Updated `conversionRepositoryProvider` to use new provider

## 🔄 Data Flow

**Login Flow:**
```
Flutter App → Auth Api Service (defaultBaseUrl)
→ MongoDB Backend → Verify Credentials & Return Token
→ Token stored in secure storage
```

**Video Compression Flow:**
```
Flutter App → Conversion Api Service (conversionBaseUrl)
→ OLD Backend → Process Video → Return Result
→ File saved locally or to storage
```

---

## 💡 Important Notes

1. **Dual APIs are independent** - If one goes down, the other still works
2. **Users only need login credentials** - Platform handles both URLs internally
3. **No code changes needed in app UI** - Everything is handled in providers
4. **Both URLs should be HTTPS** in production
5. **Keep old backend running** - Don't deprecate it while in use
6. **Monitor both endpoints** - Set up alerts for both services

---

## 🆘 Troubleshooting

### Users can't login
- Check `defaultBaseUrl` points to MongoDB backend
- Verify MongoDB backend is running
- Check network access in MongoDB Atlas

### Video compression fails
- Check `conversionBaseUrl` points to old backend
- Verify old backend is still running
- Check conversion service logs

### Token issues
- Verify both backends use same `JWT_SECRET` if sharing sessions
- Or keep tokens separate (recommended)

---

## 📞 Quick URLs for Reference

| Service | URL | Type |
|---------|-----|------|
| Auth Backend | `https://your-auth-backend.onrender.com/api` | MongoDB |
| Conversion | `https://doc-backend-1-187r.onrender.com/api` | Existing |
| Docs | See each backend's /api/health | Info |

---

## ✅ You're Production Ready!

Once both backends are deployed and tested:
1. Build release APK/IPA
2. Submit to Play Store/App Store
3. Monitor logs for errors
4. Be ready to switch URLs if needed

Let me know if you need help with deployment! 🚀
