# News Intelligence 📰🤖

A Flutter mobile application that fetches the latest articles from selected news sources and uses AI to generate summaries, extract keywords, and highlight key insights.

## 🌟 Features

- **Multi-source support**: Select from various news sources (Le Monde, Les Echos, etc.)
- **Latest articles retrieval**: Automatically fetch the most recent articles from your chosen sources
- **AI-powered summaries**: Generate concise summaries using Anthropic Claude or Google AI
- **Keyword extraction**: Automatically identify and extract key terms from articles
- **Highlight detection**: Surface the most important insights and quotes from each article
- **In-app AI configuration**: Select your AI provider and enter your API key directly in the app (no environment files needed)
- **Cross-platform**: Available on Android and iOS

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- An API key from either:
  - [Anthropic](https://www.anthropic.com/) (Claude API)
  - [Google AI Studio](https://makersuite.google.com/app/apikey) (Gemini API)
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Aluzy/news_intelligence.git
cd news_intelligence
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

4. Configure your AI provider:
   - Open the app settings
   - Select your preferred AI provider (Anthropic or Google)
   - Enter your API key
   - Start analyzing articles!

## 📖 Usage

1. **Launch the app**: Open News Intelligence on your mobile device
2. **Configure AI settings**: 
   - Go to Settings
   - Choose your AI provider (Anthropic Claude or Google Gemini)
   - Enter your API key
3. **Select news sources**: Choose from available news outlets (Le Monde, Les Echos, etc.)
4. **Browse articles**: View the latest articles from your selected sources
5. **Analyze with AI**: Tap on any article to:
   - Generate a concise summary
   - Extract key topics and keywords
   - View important highlights and quotes

## 🔧 Configuration

All configuration is done directly in the application:

- **AI Provider**: Switch between Anthropic Claude and Google Gemini
- **API Key**: Securely stored on your device
- **News Sources**: Enable/disable specific sources
- **Article Limit**: Set the number of articles to fetch per source

## 🏗️ Project Structure

```
news_intelligence/
├── lib/
│   ├── models/          # Data models
│   ├── services/        # API services (AI, news scrapers)
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable widgets
│   └── utils/           # Helper functions
├── android/             # Android specific files
├── ios/                 # iOS specific files
├── pubspec.yaml         # Flutter dependencies
└── README.md
```

## 🤖 Supported AI Providers

### Anthropic Claude
- Advanced language understanding
- Excellent summarization capabilities
- Superior context handling

### Google AI (Gemini)
- Fast processing
- Cost-effective
- Strong multilingual support

## 📰 Supported News Sources

- Le Monde
- Les Echos
- [Add your sources here]

Want to add more sources? Contributions are welcome!

## 🛠️ Technologies Used

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Anthropic Claude API** - AI-powered text analysis
- **Google Gemini API** - Alternative AI provider
- **HTTP/Dio** - Network requests
- Web scraping for news sources

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This tool is for personal use and educational purposes. Please respect the terms of service of news sources and ensure compliance with their robots.txt and scraping policies.

## 🙏 Acknowledgments

- Thanks to Anthropic and Google for providing powerful AI APIs
- All the news organizations for their quality journalism

## 📧 Contact

Aluzy - [@Aluzy](https://github.com/Aluzy)

Project Link: [https://github.com/Aluzy/news_intelligence](https://github.com/Aluzy/news_intelligence)

---

⭐ If you find this project useful, please consider giving it a star!