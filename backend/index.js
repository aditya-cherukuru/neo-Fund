require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { errorHandler } = require('./middleware/errorHandler');
const { logger } = require('./utils/logger');

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: function (req, file, cb) {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const investmentRoutes = require('./routes/investment');
const aiRoutes = require('./routes/ai');
const forecastRoutes = require('./routes/forecast');
const financeRoutes = require('./routes/finance');

// Validate required environment variables
const requiredEnvVars = ['MONGODB_URI', 'JWT_SECRET', 'JWT_REFRESH_SECRET'];
const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingEnvVars.length > 0) {
  logger.error('Missing required environment variables:', missingEnvVars);
  process.exit(1);
}

const uri = process.env.MONGODB_URI;
if (!uri) {
  logger.error('MONGODB_URI is not defined in environment variables');
  process.exit(1);
}

// Format the URI to ensure database name is before query parameters
const formatMongoUri = (uri) => {
  // Split the URI at the query parameters
  const [baseUri, queryParams] = uri.split('?');
  // Remove any trailing slash from base URI
  const cleanBaseUri = baseUri.endsWith('/') ? baseUri.slice(0, -1) : baseUri;
  // Add the database name and reattach query parameters if they exist
  return queryParams ? `${cleanBaseUri}/MintMateDB?${queryParams}` : `${cleanBaseUri}/MintMateDB`;
};

const formattedUri = formatMongoUri(uri);

const app = express();

// Middleware
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:3001', 
    'http://localhost:8080',
    'http://localhost:8081',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:3001',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:8081',
    'http://localhost:5173',
    'http://localhost:4173',
    // Add Flutter web development ports
    'http://localhost:60555',
    'http://127.0.0.1:60555',
    'http://localhost:60556',
    'http://127.0.0.1:60556',
    // Allow all localhost ports for development
    /^http:\/\/localhost:\d+$/,
    /^http:\/\/127\.0\.0\.1:\d+$/
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));

app.use(express.json());

// Error handler for JSON parsing errors
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    logger.error('JSON parsing error:', {
      error: err.message,
      path: req.path,
      method: req.method,
      headers: req.headers,
      body: req.body
    });
    return res.status(400).json({
      status: 'error',
      message: 'Invalid JSON in request body',
      details: err.message
    });
  }
  next(err);
});

// Serve uploaded files statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));



// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    body: req.body,
    query: req.query,
    params: req.params,
    headers: {
      'content-type': req.headers['content-type'],
      'content-length': req.headers['content-length'],
      'user-agent': req.headers['user-agent']
    },
    rawBody: req.body ? JSON.stringify(req.body) : 'No body'
  });
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/investment', investmentRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/forecast', forecastRoutes);
app.use('/api/finance', financeRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'success', 
    message: 'MintMate API is running',
    timestamp: new Date().toISOString()
  });
});

// Error handling
app.use(errorHandler);

// MongoDB connection options
const mongooseOptions = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  family: 4,
  maxPoolSize: 10,
  minPoolSize: 5,
  retryWrites: true,
  retryReads: true
};

// MongoDB connection with retry logic
const connectWithRetry = async (retries = 5, delay = 5000) => {
  try {
    console.log('Attempting to connect to MongoDB...');
    console.log('MongoDB URI:', formattedUri.replace(/\/\/[^:]+:[^@]+@/, '//****:****@'));
    
    await mongoose.connect(formattedUri, mongooseOptions);
    
    // Verify database name
    const dbName = mongoose.connection.db.databaseName;
    console.log('Connected to database:', dbName);
    
    if (dbName !== 'MintMateDB') {
      logger.error('Connected to wrong database:', { 
        expected: 'MintMateDB',
        actual: dbName,
        uri: formattedUri.replace(/\/\/[^:]+:[^@]+@/, '//****:****@')
      });
      process.exit(1);
    }

    logger.info('Connected to MongoDB', { 
      database: dbName,
      uri: formattedUri.replace(/\/\/[^:]+:[^@]+@/, '//****:****@'),
      options: mongooseOptions
    });

    // Set up connection event handlers
    mongoose.connection.on('error', (err) => {
      logger.error('MongoDB connection error:', {
        error: err.message,
        stack: err.stack
      });
    });

    mongoose.connection.on('disconnected', () => {
      logger.warn('MongoDB disconnected. Attempting to reconnect...');
      setTimeout(() => connectWithRetry(retries - 1, delay), delay);
    });

    mongoose.connection.on('reconnected', () => {
      logger.info('MongoDB reconnected successfully');
    });

    // Start server after successful connection
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
      console.log(`✅ Server is running on http://localhost:${PORT}`);
      console.log('✅ MongoDB connected successfully');
      console.log('✅ JWT secrets configured');
      console.log('✅ Ready to handle requests!');
    });
  } catch (error) {
    logger.error('MongoDB connection error:', {
      error: error.message,
      stack: error.stack,
      retriesLeft: retries
    });

    if (retries > 0) {
      logger.info(`Retrying connection in ${delay}ms...`);
      setTimeout(() => connectWithRetry(retries - 1, delay), delay);
    } else {
      logger.error('Max retries reached. Exiting...');
      process.exit(1);
    }
  }
};

// Initial connection attempt
connectWithRetry();

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Promise Rejection:', {
    error: err.message,
    stack: err.stack
  });
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', {
    error: err.message,
    stack: err.stack
  });
  process.exit(1);
}); 