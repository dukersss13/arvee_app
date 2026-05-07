# ArVee - iOS Receipt Validator & Spending Analyzer

An iOS app for validating receipts against bank transactions and analyzing spending patterns with an AI-powered chat assistant.

## Features

- **Session Management** — Create or resume validation sessions
- **Receipt Validation** — Upload transaction records and proof-of-purchase photos for automated matching
- **AI Chat (ArVee)** — Ask natural language questions about your spending with chart and table responses
  - Bar charts, grouped bar charts, pie charts (Swift Charts)
  - Top categories tables
  - Period comparison tables with delta and percent change

## Architecture

- **SwiftUI** with MVVM pattern
- **Swift Charts** for data visualization
- **URLSession** for REST API + SSE streaming
- Connects to the existing [receipt_validator](https://github.com/dukersss13/receipt_validator) Flask backend

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Running instance of the receipt_validator backend

## Project Structure

```
ArVee/
├── ArVeeApp.swift              # App entry point
├── Models/
│   ├── AnyCodable.swift        # Type-erased JSON value wrapper
│   ├── Session.swift           # Session & input data models
│   ├── ValidationResult.swift  # Validation response models
│   ├── ChatMessage.swift       # Chat message & response models
│   └── ChartData.swift         # Chart & table data models
├── Services/
│   ├── APIService.swift        # HTTP client for Flask backend
│   └── SSEClient.swift         # Server-Sent Events streaming client
├── ViewModels/
│   ├── SessionViewModel.swift
│   ├── ValidationViewModel.swift
│   └── ChatViewModel.swift
└── Views/
    ├── MainTabView.swift       # Tab-based navigation
    ├── SettingsView.swift      # API URL configuration
    ├── Components/
    │   └── StatusBanner.swift  # Reusable banners & loading overlay
    ├── Session/
    │   └── SessionView.swift
    ├── Validation/
    │   ├── ValidationView.swift
    │   └── ResultTableView.swift
    └── Chat/
        ├── ChatView.swift
        ├── ChatBubble.swift
        ├── ChartCardView.swift # Bar, grouped bar, pie charts
        └── DataTableCards.swift # Top categories & comparison tables
```

## Setup

1. Clone this repo
2. Open `ArVee.xcodeproj` in Xcode
3. Set the backend URL in Settings tab (default: `http://localhost:5000`)
4. Build and run on simulator or device

## API Endpoints Used

| Endpoint | Method | Description |
|---|---|---|
| `/api/session/new` | POST | Create new session |
| `/api/session/<id>` | GET | Load session inputs |
| `/api/session/<id>/state` | GET | Load saved state |
| `/api/session/<id>/save` | POST | Save session state |
| `/api/validate` | POST | Validate receipts (multipart) |
| `/api/chat/ask` | POST | Chat (full response) |
| `/api/chat/ask/stream` | POST | Chat (SSE streaming) |
| `/api/export/validated` | POST | Export validated rows as PDF |
