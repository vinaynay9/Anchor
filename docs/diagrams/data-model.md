# Data Model

This document describes the database schema and entity relationships.

```mermaid
erDiagram
    users ||--o{ friendships : "has"
    users ||--o{ lock_sessions : "creates"
    users ||--o{ unlock_requests : "requests"
    users ||--o{ unlock_requests : "receives"
    lock_sessions ||--o{ unlock_requests : "has"
    lock_sessions ||--o{ proofs : "has"
    unlock_requests ||--o| proofs : "may have"
    
    users {
        uuid id PK
        string email
        string username
        string displayName
        timestamp createdAt
    }
    
    friendships {
        uuid id PK
        uuid userId FK
        uuid friendId FK
        string status
        timestamp createdAt
    }
    
    lock_sessions {
        uuid id PK
        uuid userId FK
        string status
        timestamp startTime
        timestamp endTime
        string[] appsBlocked
        uuid accountabilityPartnerId FK
        timestamp createdAt
    }
    
    unlock_requests {
        uuid id PK
        uuid sessionId FK
        uuid requesterId FK
        uuid partnerId FK
        string status
        string message
        timestamp createdAt
        timestamp resolvedAt
    }
    
    proofs {
        uuid id PK
        uuid sessionId FK
        uuid unlockRequestId FK
        url fileUrl
        url thumbnailUrl
        timestamp createdAt
    }
```

## Entity Descriptions

### users
Stores user account information including authentication credentials and profile data.

### friendships
Represents the friendship relationship between two users. Status can be:
- `pending`: Friend request sent but not yet accepted
- `accepted`: Friendship confirmed
- `blocked`: User has blocked the friend

### lock_sessions
Represents a focus session where apps are blocked. Status can be:
- `active`: Session is currently running
- `completed`: Session ended normally
- `cancelled`: Session was cancelled early

### unlock_requests
Represents a request to unlock apps before session completion. Status can be:
- `pending`: Awaiting partner's response
- `approved`: Partner approved the unlock
- `denied`: Partner denied the unlock

### proofs
Stores photo proof images associated with sessions or unlock requests.

## Relationships

- **users ↔ friendships**: One-to-many (user can have many friendships)
- **users ↔ lock_sessions**: One-to-many (user can create many sessions)
- **users ↔ unlock_requests**: One-to-many (user can request/receive many unlock requests)
- **lock_sessions ↔ unlock_requests**: One-to-many (session can have multiple unlock requests)
- **lock_sessions ↔ proofs**: One-to-many (session can have multiple proofs)
- **unlock_requests ↔ proofs**: One-to-one (unlock request can have one proof)

