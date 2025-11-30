# DocXpress Backend API

A comprehensive document processing backend for the DocXpress mobile app. Provides REST APIs for document conversion, image processing, video compression, and note-taking.

## Features

- **Authentication**: JWT-based user authentication
- **File Management**: Upload, download, and manage files
- **Image Processing**: Format conversion, resize, crop, rotate, grayscale, compression
- **Document Conversion**: PDF ⇄ DOCX ⇄ PPTX ⇄ TXT
- **PDF Tools**: Merge, split, reorder, extract text/images, watermark
- **Video Compression**: Multiple presets (480p, 720p, 1080p)
- **Notes**: Simple note-taking with tags and pinning
- **Job Tracking**: Full history of all conversion/compression operations

## Prerequisites

- Node.js >= 18.0.0
- MongoDB (local or Atlas)
- FFmpeg (for video compression)

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd DocXpress

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment (development/production) | `development` |
| `PORT` | Server port | `3000` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/docxpress` |
| `JWT_SECRET` | Secret key for JWT signing | (required) |
| `JWT_EXPIRES_IN` | JWT token expiration | `7d` |
| `STORAGE_ROOT` | Root directory for file storage | `./uploads` |
| `MAX_FILE_SIZE` | Maximum upload file size (bytes) | `52428800` (50MB) |
| `FFMPEG_PATH` | Path to FFmpeg binary (if not in PATH) | - |

## Running the Server

```bash
# Development mode with hot reload
npm run dev

# Production mode
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Get current user profile
- `PATCH /api/auth/me` - Update profile
- `POST /api/auth/change-password` - Change password
- `POST /api/auth/logout` - Logout

### Notes
- `GET /api/notes` - List user's notes
- `POST /api/notes` - Create note
- `GET /api/notes/:id` - Get single note
- `PUT /api/notes/:id` - Update note
- `DELETE /api/notes/:id` - Delete note
- `PATCH /api/notes/:id/pin` - Toggle pin status
- `GET /api/notes/tags` - Get user's tags
- `GET /api/notes/search` - Search notes

### Files
- `POST /api/files/upload` - Upload single file
- `POST /api/files/upload-multiple` - Upload multiple files
- `GET /api/files` - List user's files
- `GET /api/files/:id` - Get file metadata
- `GET /api/files/:id/download` - Download file
- `DELETE /api/files/:id` - Soft delete file

### Conversions
- `POST /api/convert/images-to-pdf` - Convert images to PDF
- `POST /api/convert/images-to-pptx` - Convert images to PPTX
- `POST /api/convert/images-to-docx` - Convert images to DOCX
- `POST /api/convert/image-to-text` - OCR text extraction
- `POST /api/convert/image-format` - Convert image format
- `POST /api/convert/image-transform` - Apply transforms
- `POST /api/convert/merge-images` - Merge multiple images
- `POST /api/convert/pdf-to-docx` - PDF to DOCX
- `POST /api/convert/pdf-to-pptx` - PDF to PPTX
- `POST /api/convert/pdf-to-text` - Extract text from PDF
- `POST /api/convert/docx-to-pdf` - DOCX to PDF
- `POST /api/convert/pptx-to-pdf` - PPTX to PDF

### PDF Operations
- `POST /api/pdf/merge` - Merge PDFs
- `POST /api/pdf/split` - Split PDF by ranges
- `POST /api/pdf/reorder` - Reorder pages
- `POST /api/pdf/extract-text` - Extract text
- `POST /api/pdf/extract-images` - Extract images
- `POST /api/pdf/compress` - Compress PDF
- `POST /api/pdf/watermark` - Add watermark
- `POST /api/pdf/remove-pages` - Remove pages
- `POST /api/pdf/rotate-pages` - Rotate pages
- `GET /api/pdf/:id/info` - Get PDF info

### Compression
- `GET /api/compress/presets` - Get available presets
- `POST /api/compress/image` - Compress image
- `POST /api/compress/images` - Batch compress images
- `POST /api/compress/video` - Compress video
- `POST /api/compress/video/resolution` - Compress to resolution
- `POST /api/compress/video/thumbnail` - Extract thumbnail
- `POST /api/compress/video/extract-audio` - Extract audio
- `POST /api/compress/pdf` - Compress PDF
- `GET /api/compress/video/:id/info` - Get video info

### Jobs
- `GET /api/jobs` - List user's jobs
- `GET /api/jobs/:id` - Get job details
- `GET /api/jobs/recent` - Get recent jobs
- `GET /api/jobs/stats` - Get job statistics
- `GET /api/jobs/types` - Get available job types
- `POST /api/jobs/:id/cancel` - Cancel pending job
- `POST /api/jobs/:id/retry` - Retry failed job

### Admin (requires admin role)
- `GET /api/admin/stats` - System statistics
- `GET /api/admin/users` - List all users
- `GET /api/admin/users/:id` - Get user details
- `GET /api/admin/jobs` - List all jobs
- `GET /api/admin/jobs/:id` - Get job details
- `GET /api/admin/notes` - List all notes
- `POST /api/admin/cleanup/jobs` - Cleanup old jobs

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE"
  }
}
```

### Paginated Response
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

## Project Structure

```
src/
├── controllers/     # Request handlers
├── middleware/      # Auth, validation, upload, error handling
├── models/          # Mongoose schemas (User, Note, File, Job)
├── routes/          # Express route definitions
├── services/        # Business logic
│   ├── authService.js
│   ├── fileService.js
│   ├── imageService.js
│   ├── pdfService.js
│   ├── documentService.js
│   ├── videoService.js
│   ├── jobService.js
│   ├── noteService.js
│   └── storageService.js
├── utils/           # Constants, helpers, error classes
├── app.js           # Express app setup
└── server.js        # Entry point
```

## Notes

- Some document conversions (DOCX↔PDF, PPTX↔PDF) use stubs and would need LibreOffice integration for full functionality
- OCR uses Tesseract.js - ensure proper installation for production use
- Video processing requires FFmpeg to be installed on the system
- Storage is local filesystem by default; `storageService.js` can be extended for S3/cloud storage

## License

ISC