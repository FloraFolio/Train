# FloraFolio - Gamified Plant Discovery with AI

[![Demo Video](https://img.shields.io/badge/Demo-Watch%20Video-red)](https://youtu.be/Z6SlXJZFX3c) 
[![Prototype](https://img.shields.io/badge/Prototype-Download-blue)](https://github.com/FloraFolio/Train/releases)

# Notice
If the project is detect some errors for `lib/main.dart` please do the following commands:

```bash
flutter clean
flutter packages get
flutter packages upgrade
```
Then restart vscode or android studio and so on.

When you compile the code remember copy the `/lib/config/api_config.example.dart` and paste it to `/lib/config/api_config.dart`

And add your gemini API to the correspond place.  


## Key Features
🌿 **AI-Powered Plant Identification**  
- Snap photos of plants and get instant analysis using Gemini AI
- Accurate species recognition and detailed information

📊 **Smart Digital Herbarium** 
- Auto-organizes plants by species, location, and rarity
- Personalized collection tracking

🎮 **Gamified Discovery**
- Earn badges and unlock rewards
- Conservation challenges to boost engagement

📁 **Data Flexibility**
- Import/export plant data in CSV/JSON formats
- Offline mode with cloud sync capability

## Technology Stack
**Core Technologies:**
- **Frontend**: Flutter (iOS & Android)
- **Database**: SQLite (offline-first) with cloud sync
- **AI Engine**: Google Gemini 1.5 Flash API
  - Plant recognition
  - Ecological insights generation

**Development Tools:**
- Android Studio & Xcode
- Java Development Kit (JDK)
- Dart programming language

## Prototype
Explore our working prototype available for download:
[Prototype Releases](https://github.com/FloraFolio/Train/releases)

## Future Roadmap
- Cloud account integration (Firebase Auth/AWS Cognito)
- Advanced visualization modes (map view, 3D plant models)
- Community features for plant enthusiasts
- Expanded AI capabilities for disease detection

## Implementation Considerations
**Cost Estimates:**
- Gemini API: ~$100–$1,000/month at scale
- Infrastructure: Firebase/AWS backend services
- Platform fees: App store developer accounts

## How to Contribute
We welcome contributions! Please fork the repository and submit pull requests.

## Developers
Iwan Li, Luwei Xu, Xianna Weng, Qijun Pan