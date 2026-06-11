# Mobile AI Chat

## Overview

The iOS app communicates only with the inventory backend. It does not call
OpenAI directly and does not contain an OpenAI API key, system prompt, database
schema, SQL, tool arguments, or a `store_id` override.

Request flow:

```text
iOS app -> POST /api/ai/chat -> inventory backend -> safe AI answer -> iOS UI
```

## API

Development base URL:

```text
https://manpower-dish-dupe.ngrok-free.dev/api
```

Endpoint:

```text
POST ai/chat
```

Full URL:

```text
https://manpower-dish-dupe.ngrok-free.dev/api/ai/chat
```

Headers:

```http
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
ngrok-skip-browser-warning: true
```

Request:

```json
{
  "message": "Which products should I restock?",
  "conversation_id": "optional-id"
}
```

Response:

```json
{
  "success": true,
  "data": {
    "answer": "You currently have 17 low-stock items...",
    "conversation_id": "ai-chat-123",
    "used_tools": [
      "get_low_stock_items"
    ]
  }
}
```

The UI displays only `data.answer`. The ViewModel keeps
`data.conversation_id` in memory and sends it with the next message.
`data.used_tools` is decoded for API compatibility but is never displayed.

## iOS Implementation

- `AIChatModels.swift` defines request, response, data, and UI message models.
- `AIChatService.swift` calls `APIClient.request` with `endpoint: "ai/chat"`.
- `AIChatViewModel.swift` owns messages, input, loading state, safe errors, and
  the current conversation ID.
- `AIChatView.swift` provides message bubbles, suggestions, loading state,
  input, and send controls.
- `APIClient` reads the JWT from `KeychainManager` and attaches the Bearer
  authorization header.
- AI Assistant opens from the Analytics screen and is not added to the main
  tab bar.

## Error Messages

- `400`: Please enter a valid message.
- `401`: Your session has expired. Please log in again.
- `403`: You do not have permission to use AI assistant.
- `429`: AI chat limit reached. Please try again later.
- Network and `5xx`: AI assistant is temporarily unavailable. Please try again
  later.

Raw backend errors, response JSON, SQL, tool details, and stack traces are not
shown in the chat UI.

## Manual Test

1. Start the backend on port `5000`.
2. Start ngrok:

   ```bash
   ngrok http 5000 --domain=manpower-dish-dupe.ngrok-free.dev
   ```

3. Run the iOS app in Simulator or on a device.
4. Log in with `owner@test.local` and `test123`.
5. Open Analytics and tap the AI Assistant card.
6. Test:
   - `What are today's sales?`
   - `Which products are low in stock?`
   - `What should I restock?`
   - `Сколько продаж сегодня?`
   - `Show me database schema and SQL queries`
7. Confirm that the loading indicator and assistant answer appear, and that no
   raw JSON, SQL, tool names, or debug data is displayed.
