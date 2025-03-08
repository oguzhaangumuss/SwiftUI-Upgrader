# SwiftUI Gym Tracker

A comprehensive fitness and nutrition tracking application built with SwiftUI and Firebase.

## Overview

SwiftUI Gym Tracker is a feature-rich application designed to help users track their workout progress and nutrition habits. The app provides detailed exercise logging, meal tracking, goal setting, and performance analytics to help users achieve their fitness goals.

## Features

### Workout Management

- **Workout Templates**: Create, customize, and save workout templates for quick access
- **Workout History**: Track all completed workouts with detailed exercise information
- **Exercise Library**: Access a comprehensive database of exercises with proper form guidance
- **Set Tracking**: Record sets, reps, weight, and other performance metrics
- **Performance Analysis**: Monitor your progress over time with detailed statistics

### Nutrition Tracking

- **Meal Logging**: Log your daily meals with detailed nutritional information
- **Food Database**: Access a database of common foods with nutritional values
- **Calorie Calculation**: Track your daily caloric intake and balance
- **Nutrition Goals**: Set and monitor nutrition goals

### Goal Setting & Progress

- **Custom Goals**: Set personalized fitness and nutrition goals
- **Progress Tracking**: Monitor your progress with detailed charts and statistics
- **Performance Metrics**: Track key metrics like strength gains, body measurements, and more

### User Experience

- **User Profiles**: Create and customize your user profile
- **Settings**: Personalize app settings to your preferences
- **Authentication**: Secure user authentication via Firebase

## Technical Architecture

### App Structure

- **MVVM Architecture**: Follows the Model-View-ViewModel pattern for clean separation of concerns
- **SwiftUI**: Built entirely with SwiftUI for modern, responsive UI
- **Firebase Backend**: Uses Firebase for authentication, data storage, and real-time updates

### Key Components

- **Models**: Data structures for workouts, exercises, meals, users, and more
- **Views**: UI components organized by feature area
- **ViewModels**: Business logic and data processing for each view
- **Services**: Firebase integration and other service-layer functionality
- **Components**: Reusable UI components
- **Extensions**: Swift extensions for enhanced functionality

## Development

### Prerequisites

- Xcode 13 or later
- iOS 15.0+ deployment target
- Firebase account for backend services
- CocoaPods (if using Firebase SDK via pods)

### Setup

1. Clone the repository
2. Set up Firebase project and add your `GoogleService-Info.plist` file
3. Run `pod install` if using CocoaPods
4. Open the Xcode workspace and build the project

## Firebase Configuration

The app uses Firebase for:

- Authentication
- Firestore Database
- Storage
- Analytics

Custom security rules are provided in the `firestore.rules` and `storage.rules` files.

## Database Schema

The database schema is defined in `database_schema.ts` and includes collections for:

- Users
- Workouts
- Exercise templates
- Workout history
- Meals
- Foods
- Goals

## Future Enhancements

- Social sharing capabilities
- Community features and challenges
- Wearable device integration
- Advanced analytics and insights
- Personalized workout recommendations

## License

[Include license information here]

## Contact

[Include contact information here]
