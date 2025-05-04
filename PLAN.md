# MCBROKEN APP REFACTORING AND ENHANCEMENT PLAN

## Current Codebase Analysis
The mcbroken_app is a Flutter application that shows the status of McDonald's ice cream machines. The app uses a Flutter BLoC pattern for state management and fetches data from a large JSON file hosted on GitHub. The main performance issue is related to loading and processing this large JSON dataset.

### Key Issues Identified:
1. **Performance Issue**: The app loads a large JSON file via HTTP and processes it all at once.
   - File is fetched from: https://raw.githubusercontent.com/rashiq/mcbroken-archive/main/mcbroken.json
   - All locations are loaded into memory at once, which is inefficient

2. **Code Structure**: Generally well-structured using BLoC pattern, but some improvements possible.

3. **Feature Limitations**: Missing search functionality and support for countries beyond the US.

## Refactoring Recommendations

### 1. Performance Improvements

#### A. Data Loading & Processing
- **Implement Pagination**: Fetch data in smaller chunks instead of loading the entire JSON file at once.
- **Backend API**: Consider creating a lightweight backend service that can serve data incrementally with:
  - Pagination support
  - Filtering by region/proximity
  - Only returning locations within the current map viewport
- **Local Database Cache**: Use SQLite (via sqflite package) to cache downloaded data locally
  - Implement expiration policies (refresh data every X hours)
  - Background data fetching that doesn't block UI

#### B. Data Processing Optimization
- **Lazy Loading**: Load only McDonald's locations that are visible in the current viewport
- **Parallel Processing**: Use Isolates for parsing JSON data without blocking the UI thread
- **Incremental Processing**: Process the data in chunks rather than all at once

### 2. Code Structure Improvements

- **Dependency Injection**: Implement proper DI using get_it or provider package
- **Error Handling**: Add more robust error handling and retry mechanisms
- **Model Improvements**: Use JSON serialization libraries like json_serializable to reduce boilerplate
- **Repository Pattern**: Enhance the repository to handle both remote and local data sources
- **Code Style**: Apply consistent naming conventions (camelCase instead of snake_case for Dart classes)
- **Increased Test Coverage**: Add unit and integration tests

### 3. New Features

#### A. User Experience Enhancements
- **Search Functionality**: Allow users to search for specific McDonald's locations or addresses
- **Filtering Options**: Add filters for:
  - Working/non-working ice cream machines
  - Distance from current location
  - Last checked time
- **Refresh Feature**: Pull-to-refresh for updating data without restarting the app
- **Favorites**: Allow users to bookmark their frequently visited McDonald's locations
- **Notifications**: Alert users when a nearby machine becomes operational
- **Route Navigation**: Add directions to the selected McDonald's using platform map integrations

#### B. Localization & Internationalization
- **Extended Country Support**: Add support for countries beyond the US by:
  - Integrating with additional data sources
  - Creating a mechanism for community-contributed data
- **Enhanced Localization**: Add support for more languages

#### C. Advanced Features
- **Crowdsourced Data**: Allow users to report the status of ice cream machines
- **Machine Learning**: Predict when machines might be working based on historical patterns
- **Analytics**: Track user patterns and provide insights on optimal times to visit
- **Offline Mode**: Full functionality when offline, using cached data

## Implementation Roadmap

### Phase 1: Performance Optimization
1. ✅ Implement local database caching with sqflite
2. ✅ Refactor data loading with pagination and viewport-based filtering
3. ✅ Add background data fetching with refresh policies

### Phase 2: Code Structure Improvements
1. ✅ Refactor models and use json_serializable
2. ✅ Implement proper dependency injection
3. ✅ Improve error handling and add retry mechanisms

### Phase 3: New Feature Implementation
1. Add search functionality
2. Implement filtering options
3. Add favorites feature
4. Improve map interactions and clustering

### Phase 4: Extended Features
1. Add support for more countries
2. Implement crowdsourced data reporting
3. Add offline mode functionality
4. Enhance localization support

## Specific Implementation Details

### Database Schema
```
Table: mcdonalds_locations
- id: String (primary key)
- latitude: Double
- longitude: Double
- is_broken: Boolean
- is_active: Boolean
- state: String
- city: String
- street: String
- country: String
- last_checked: DateTime
- last_synced: DateTime
```

### New API Endpoints (for future backend)
- `/locations?lat=X&lng=Y&radius=Z` - Get locations within radius of coordinates
- `/locations/search?query=X` - Search locations by address or name
- `/locations/:id` - Get details for a specific location
- `/stats` - Get global statistics about broken machines

### Required Flutter Packages to Add
- sqflite: For local database
- flutter_map_supercluster: For improved clustering
- geolocator: For better location handling
- shared_preferences: For user settings
- path_provider: For local file system access
- flutter_local_notifications: For notifications
- cached_network_image: For image caching
- flutter_cache_manager: For better caching strategies
