# Friends Feature

## Overview
The Friends feature manages user connections, allowing users to add, search, and manage their accountability partners.

## Components

### Views
- **FriendsView**: Main friends list view
  - Displays list of friends with search functionality
  - Shows empty state when no friends are added
  - Provides add friend button

- **AddFriendSheet**: Modal sheet for adding new friends
  - Allows users to search and add friends by username
  - Handles friend request sending

- **PendingRequestsView**: Displays pending friend requests
  - Shows incoming and outgoing friend requests
  - Allows accepting/declining requests

### ViewModels
- **FriendsViewModel**: Manages friends list and operations
  - Loads and filters friends
  - Handles friend addition and removal
  - Manages search functionality

### Models
- **FriendMockModel**: Mock model for friend data (used during development)

## Features
- Search friends by name or username
- Add friends by username
- Remove friends
- View friend details
- Handle pending friend requests

## Dependencies
- `FriendService`: Core friend management service
- `UserService`: User data retrieval

