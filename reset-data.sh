#!/bin/bash
# Reset all transactional data (requests, quotes, photos) while preserving logins

SERVER_URL="${1:-http://localhost:3000}"

echo "Resetting transactional data on $SERVER_URL ..."

response=$(curl -s -X POST "$SERVER_URL/api/reset" -H "Content-Type: application/json")

if echo "$response" | grep -q '"status":"ok"'; then
    echo "Done! All requests, quotes, and photos have been cleared."
else
    echo "Error: $response"
    echo "Make sure the server is running."
    exit 1
fi
