# PawScope 🐾

PawScope is a comprehensive pet management and health monitoring application built with Flutter and Firebase. It helps pet owners track their pets' profiles, identify breeds and skin diseases through AI-powered image scanning, manage care schedules with local notifications, and access community tips — all backed by a secure administrative dashboard.

## 🌟 Key Features

### For Pet Owners (Users)
- **Pet Profiles** — Create and manage detailed profiles for your pets, including photo galleries and breed information.
- **AI-Powered Scanning** — Snap a photo to identify your pet's breed (top-5 predictions) or detect potential skin diseases (top-3 predictions) using deep learning models.
- **Scan History** — View past scan results with confidence scores, stored per user in Firestore.
- **Schedule & Calendar** — Create, edit, and track pet care schedules (vet visits, grooming, medication, etc.) with a full calendar view.
- **Local Notifications** — Get timely push notification reminders for upcoming schedules, with user-configurable sound and vibration preferences.
- **Feedback System** — Submit feedback directly from the app; admins can review and reply.
- **Community Tips & FAQs** — Access a curated knowledge base for pet care guidance.
- **Privacy & Security** — Change password, manage account details, and review the privacy policy within the app.
- **OTP Email Verification** — Secure registration and password reset via 6-digit OTP, delivered through SendGrid.
- **Google Sign-In** — Authenticate with Google in addition to email/password login.

### For Administrators
- **Admin Dashboard** — Centralised overview of platform usage and activity.
- **User Account Management** — View, suspend, or modify user accounts.
- **Feedback Management** — Read, reply to, and manage user feedback submissions.
- **FAQ & Community Tips Management** — Create, edit, and delete FAQ entries and community tips.
- **Analysis Records** — Review AI scan analysis records across the platform.
- **System Activity Logs** — Immutable audit trail of system-wide events (logins, suspensions, critical actions).

## 🏗️ Architecture

The project follows the **MVVM (Model-View-ViewModel)** pattern:

```
lib/
├── main.dart                  # App entry point, Firebase init, route definitions
├── AI/models/                 # Keras ML models & label JSON files (local reference)
├── View/                      # 43 UI screen files (login, scan, calendar, admin, etc.)
├── ViewModel/                 # 43 ViewModel files (business logic, state management)
├── models/                    # Data models (PetInfo, UserAccount, FeedbackModel, etc.)
├── services/                  # Core services:
│   ├── ai_service.dart        #   Communicates with the FastAPI AI backend
│   ├── notification_service.dart  #   Local push notification scheduling
│   ├── otp_service.dart       #   OTP generation, verification via Cloud Functions
│   └── activity_service.dart  #   System activity audit logging
├── config/                    # API keys configuration (git-ignored)
├── theme/                     # App-wide theming (AppTheme)
└── utils/                     # Validation utilities
```

## 🛠️ Technology Stack

### Frontend (Mobile App)
| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev/) (Dart) | Cross-platform mobile framework |
| [Provider](https://pub.dev/packages/provider) | State management |
| `flutter_local_notifications` | Local push notification scheduling |
| `image_picker` / `camera` | Photo capture & gallery selection |
| `flutter_image_compress` | Client-side image compression before AI upload |
| `intl` / `timezone` | Date formatting & timezone handling |
| `smooth_page_indicator` | Onboarding/carousel page indicators |
| `shared_preferences` | Persisting user notification settings locally |

### Backend — AI Inference Server (`backend/`)
| Technology | Purpose |
|---|---|
| [FastAPI](https://fastapi.tiangolo.com/) (Python) | REST API framework |
| [TensorFlow / Keras](https://www.tensorflow.org/) | Deep learning inference |
| Firebase Admin SDK | Server-side password reset |
| [Docker](https://www.docker.com/) | Containerised deployment |
| [Google Cloud Run](https://cloud.google.com/run) | Production hosting |

**AI Models (Keras `.keras` format):**
| Model | Architecture | Purpose |
|---|---|---|
| `species_best.keras` | CNN | Species classification (cat vs dog) |
| `cat_breed_kaggle.keras` | EfficientNet | Cat breed identification (top-5) |
| `dog_breed_best_model.keras` | EfficientNet | Dog breed identification (top-5) |
| `cat_disease_model.keras` | MobileNetV2 | Cat skin disease detection (top-3) |
| `dog_disease_model.keras` | MobileNetV2 | Dog skin disease detection (top-3) |

**API Endpoints:**
| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/predict` | Breed prediction (species → top-5 breeds) |
| `POST` | `/predict-disease` | Disease prediction (species → top-3 diseases) |
| `POST` | `/reset-password` | In-app password reset via Firebase Admin SDK |

### Firebase Services
| Service | Usage |
|---|---|
| **Firebase Authentication** | Email/password login, Google Sign-In |
| **Cloud Firestore** | Primary database (users, pets, schedules, scans, feedback, FAQs, OTPs, activity logs) |
| **Firebase Storage** | Pet images, profile images, scan images (owner-scoped security rules) |
| **Cloud Functions** (Node.js 22) | `resetPassword` — server-side password reset; `sendOtp` — OTP email delivery via SendGrid |

### Firestore Collections
| Collection | Description |
|---|---|
| `user` | User profiles (custom IDs e.g. `U000001`) |
| `pet` | Pet profiles |
| `ScanHistory` | AI scan results (owner-scoped reads) |
| `schedules` | Pet care schedules |
| `notifications` | In-app notification records |
| `feedback` | User feedback & admin replies |
| `community_tips` | Admin-managed pet care tips |
| `faq` | Frequently asked questions |
| `breed` | Breed reference data (read-only) |
| `counters` | Auto-increment ID generation |
| `otps` | OTP verification tokens |
| `system_activity_logs` | Immutable audit trail |

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (SDK `^3.9.2`)
- [Dart SDK](https://dart.dev/get-dart)
- [Python 3.11+](https://www.python.org/downloads/) (for the AI backend)
- [Node.js 22](https://nodejs.org/) (for Cloud Functions)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- An IDE such as VS Code, Android Studio, or IntelliJ
- A configured **Firebase project** with Authentication, Firestore, Storage, and Functions enabled

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd FYP_Project
```

### 2. Flutter App Setup

```bash
# Install Flutter dependencies
flutter pub get

# Ensure Firebase config files are in place:
#   Android → android/app/google-services.json
#   iOS     → ios/Runner/GoogleService-Info.plist
```

### 3. API Keys Configuration

The `lib/config/api_keys.dart` file is **git-ignored** for security. Create it locally:

```bash
cp lib/config/api_keys.example.dart lib/config/api_keys.dart
```

Then update the file with the actual SendGrid API key. See [`lib/config/README.md`](lib/config/README.md) for detailed instructions.

### 4. AI Backend Setup (Local Development)

```bash
# Create a Python virtual environment
cd backend
python3 -m venv .venv
source .venv/bin/activate   # On Windows: .venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Copy AI model files into backend/models/ (for Docker) or ensure
# they exist at lib/AI/models/ (for local dev)

# Start the FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
# — or use the helper script:
./start.sh
```

> **Note:** Update `AiService.baseUrl` in `lib/services/ai_service.dart` to point to your local IP when testing on a physical device (e.g. `http://192.168.x.x:8000`).

### 5. Cloud Functions Setup

```bash
cd functions
npm install

# Deploy to Firebase
firebase deploy --only functions

# Or run locally with the emulator
firebase emulators:start --only functions
```

### 6. Deploy Firebase Rules & Indexes

```bash
# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy Storage security rules
firebase deploy --only storage
```

### 7. Run the App

```bash
flutter run
```

## 🐳 AI Backend — Cloud Run Deployment

```bash
# Build and deploy to Google Cloud Run
cd backend
gcloud run deploy petscan-ai \
  --source . \
  --region asia-southeast1 \
  --allow-unauthenticated

# Or build the Docker image locally
docker build -t petscan-ai ./backend
docker run -p 8080:8080 petscan-ai
```

## 📁 Project Structure

```
FYP_Project/
├── lib/                        # Flutter application source code
│   ├── main.dart               # Entry point
│   ├── AI/models/              # Keras AI models & label files
│   ├── View/                   # UI screens (43 views)
│   ├── ViewModel/              # Business logic (43 view models)
│   ├── models/                 # Data models
│   ├── services/               # Core services (AI, notifications, OTP, activity)
│   ├── config/                 # API key configuration (git-ignored)
│   ├── theme/                  # App theme definitions
│   └── utils/                  # Validation utilities
├── backend/                    # FastAPI AI inference server (Python)
│   ├── main.py                 # FastAPI app with /predict, /predict-disease, /reset-password
│   ├── Dockerfile              # Cloud Run container definition
│   ├── requirements.txt        # Python dependencies
│   └── start.sh                # Local dev startup script
├── functions/                  # Firebase Cloud Functions (Node.js)
│   ├── index.js                # resetPassword & sendOtp callable functions
│   └── package.json            # Node.js dependencies
├── docs/                       # Use case specifications & documentation
├── images/assets/              # App icons, logos, and static assets
├── firestore.rules             # Firestore security rules
├── firestore.indexes.json      # Firestore composite index definitions
├── storage.rules               # Firebase Storage security rules
├── firebase.json               # Firebase project configuration
└── pubspec.yaml                # Flutter dependencies & asset declarations
```

## 📝 Authors

- **TY Chew**
- **Jimmy Kee**

## 🔐 License

Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.  
Licensed under the [MIT License](LICENSE).
