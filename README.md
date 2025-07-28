# NeoFund

An *AI-powered personal finance companion for students*. NeoFund helps you manage your finances, get investment insights, and plan your financial future with the help of AI.

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
  - [Backend](#backend-setup)
  - [Frontend](#frontend-setup)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

---

## Overview
NeoFund is designed to empower students to take control of their finances. With AI-driven insights, investment forecasting, and a user-friendly dashboard, NeoFund makes personal finance simple, smart, and accessible.

## Features
- User authentication and secure session management
- AI-powered investment and finance insights
- Investment Advisor
- Dashboard for budget and investment overview
- Voice Q&A
- Investment history
- Modern, responsive UI built with Flutter

## Tech Stack
- *Frontend:* Flutter (Dart), Provider, Google Fonts, Lottie, fl_chart, shared_preferences, flutter_secure_storage, http, intl, image_picker, speech_to_text, flutter_tts
- *Backend:* Node.js, Express, MongoDB (Mongoose), JWT, Multer, Winston, dotenv, axios, express-validator

## Project Structure

neo-Fund/
├── 
│   ├── backend/         # Node.js/Express backend
│   └── frontend/        # Flutter frontend
└── README.md          # (Another project, not part of MintMate)


### Backend Structure
- controllers/ - Route controllers for business logic
- middleware/ - Express middleware (auth, error handling, validation)
- models/ - Mongoose models (AIInsight, Forecast, Investment, etc.)
- routes/ - API route definitions
- services/ - Business logic and AI integration
- utils/ - Utility functions (JWT, logger, etc.)
- uploads/ - Uploaded files (e.g., profile images)

### Frontend Structure
- lib/ - Main Flutter app code
  - models/ - Data models
  - screens/ - UI screens (dashboard, auth, investment, etc.)
  - services/ - API and business logic
  - widgets/ - Reusable UI components
  - theme/ - App theming
  - utils/ - Utility functions
- assets/ - Images, icons, animations
- test/ - Unit and widget tests

---

## Setup Instructions

### Backend Setup
1. *Navigate to the backend folder:*
   sh
   cd neo-fund/backend
   
2. *Install dependencies:*
   sh
   npm install
   
3. **Create a .env file** with the following variables:
   env
   MONGODB_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret
   JWT_REFRESH_SECRET=your_jwt_refresh_secret
   
4. *Start the backend server:*
   sh
   npm start
   # or for development with auto-reload
   npm run dev
   

### Frontend Setup
1. *Navigate to the frontend folder:*
   sh
   cd neo-fund/frontend
   
2. *Install dependencies:*
   sh
   flutter pub get
   
3. **Create a .env file** in the assets/ directory (if required) with your API keys and backend URL:
   env
   GROQ_API_KEY=your_groq_api_key
   GROQ_MODEL=meta-llama/llama-4-scout-17b-16e-instruct
   BACKEND_URL=http://localhost:3000/api
   
4. *Run the app:*
   - For web:
     sh
     flutter run -d chrome
     
   - For Android/iOS:
     sh
     flutter run
     
   
---

## Usage
- Register or log in as a user
- Explore the dashboard for an overview of your finances
- Use the AI advisor for investment insights
- Get Investment History and understand how your investment would have aged
- Receive notifications and forecasts

---

## Contributing
1. Fork the repository
2. Create a new branch (git checkout -b feature/your-feature)
3. Commit your changes (git commit -am 'Add new feature')
4. Push to the branch (git push origin feature/your-feature)
5. Open a Pull Request

---

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.