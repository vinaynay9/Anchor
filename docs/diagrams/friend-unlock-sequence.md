# Friend Unlock Sequence

This document describes the complete flow of requesting and approving an unlock.

```mermaid
sequenceDiagram
    participant Requester
    participant RequesterApp
    participant Backend
    participant APNs
    participant Friend
    participant FriendApp
    participant ScreenTimeService
    
    Note over Requester,ScreenTimeService: 1. Request Unlock
    
    Requester->>RequesterApp: Tap "Request Unlock"
    RequesterApp->>RequesterApp: Capture proof photo (optional)
    RequesterApp->>Backend: POST /unlock-requests
    Backend->>Backend: Create unlock_request record
    Backend->>Backend: Store proof (if provided)
    Backend-->>RequesterApp: UnlockRequest created
    
    Note over Requester,ScreenTimeService: 2. Notify Friend
    
    Backend->>Backend: Query friend's device token
    Backend->>APNs: Send push notification
    APNs->>Friend: Push notification received
    Friend->>FriendApp: Tap notification
    FriendApp->>Backend: GET /unlock-requests/pending
    Backend-->>FriendApp: List of pending requests
    
    Note over Requester,ScreenTimeService: 3. Friend Reviews Request
    
    FriendApp->>FriendApp: Display unlock request detail
    FriendApp->>FriendApp: Show proof photo (if available)
    Friend->>FriendApp: Review request and proof
    
    alt Friend Approves
        Friend->>FriendApp: Tap "Approve"
        FriendApp->>Backend: PUT /unlock-requests/{id}/approve
        Backend->>Backend: Update unlock_request status = "approved"
        Backend->>Backend: Update lock_session status = "cancelled"
        Backend-->>FriendApp: Success
        
        Note over Requester,ScreenTimeService: 4. Notify Requester
        
        Backend->>APNs: Send approval notification
        APNs->>Requester: Push notification received
        Requester->>RequesterApp: Tap notification
        RequesterApp->>Backend: GET /sessions/active
        Backend-->>RequesterApp: Session status updated
        
        Note over Requester,ScreenTimeService: 5. Lift Shields
        
        RequesterApp->>ScreenTimeService: deactivateShields()
        ScreenTimeService->>ScreenTimeService: Clear ManagedSettings restrictions
        ScreenTimeService->>ScreenTimeService: Clear AppGroup session state
        ScreenTimeService-->>RequesterApp: Shields deactivated
        RequesterApp-->>Requester: Apps now accessible
        
    else Friend Denies
        Friend->>FriendApp: Tap "Deny"
        FriendApp->>Backend: PUT /unlock-requests/{id}/deny
        Backend->>Backend: Update unlock_request status = "denied"
        Backend-->>FriendApp: Success
        
        Backend->>APNs: Send denial notification
        APNs->>Requester: Push notification received
        RequesterApp->>RequesterApp: Show denial message
        RequesterApp-->>Requester: Session continues, apps remain blocked
    end
```

## Key Steps

1. **Request Unlock**: User creates unlock request with optional photo proof
2. **Notify Friend**: Backend sends push notification to accountability partner
3. **Friend Reviews**: Partner sees request details and proof (if provided)
4. **Decision**: Partner approves or denies the request
5. **Update Session**: Backend updates unlock request and session status
6. **Lift Shields**: If approved, Screen Time restrictions are removed

## Error Handling

- If friend's device is offline, notification is queued and delivered when device comes online
- If requester's app is closed, notification will open app to show updated session status
- If Screen Time deactivation fails, app will retry and show error to user

