#!/bin/bash
# Test A2A transport connectivity

set -e

TRANSPORT_TYPE="$1"
HOST="${2:-localhost}"
PORT="${3:-8000}"

if [ -z "$TRANSPORT_TYPE" ]; then
    echo "Usage: $0 <transport-type> [host] [port]"
    echo ""
    echo "Transport types: http, sse, websocket"
    echo "Default host: localhost"
    echo "Default port: 8000"
    echo ""
    echo "Examples:"
    echo "  $0 http"
    echo "  $0 http localhost 3000"
    echo "  $0 sse"
    echo "  $0 websocket"
    exit 1
fi

case "$TRANSPORT_TYPE" in
    http)
        echo "Testing HTTP transport at http://$HOST:$PORT"
        echo ""

        # Test basic connectivity
        if command -v curl &> /dev/null; then
            echo "Testing GET request..."
            curl -f -s -o /dev/null -w "Status: %{http_code}\n" "http://$HOST:$PORT/" || echo "Connection failed"

            echo ""
            echo "Testing CORS headers..."
            curl -s -I "http://$HOST:$PORT/" | grep -i "access-control" || echo "No CORS headers found"
        else
            echo "curl not found. Install curl to test HTTP transport."
        fi
        ;;

    sse)
        echo "Testing SSE transport at http://$HOST:$PORT/events"
        echo ""

        if command -v curl &> /dev/null; then
            echo "Connecting to SSE stream (5 second timeout)..."
            timeout 5s curl -N "http://$HOST:$PORT/events" || echo "Stream test completed"
        else
            echo "curl not found. Install curl to test SSE transport."
        fi
        ;;

    websocket)
        echo "Testing WebSocket transport at ws://$HOST:$PORT/ws"
        echo ""

        if command -v websocat &> /dev/null; then
            echo "Connecting to WebSocket (5 second timeout)..."
            timeout 5s websocat "ws://$HOST:$PORT/ws" || echo "WebSocket test completed"
        elif command -v wscat &> /dev/null; then
            echo "Connecting to WebSocket (5 second timeout)..."
            timeout 5s wscat -c "ws://$HOST:$PORT/ws" || echo "WebSocket test completed"
        else
            echo "websocat or wscat not found."
            echo "Install: npm install -g wscat"
            echo "Or: cargo install websocat"
        fi
        ;;

    stdio)
        echo "STDIO transport uses process pipes and cannot be tested via network."
        echo "To test STDIO:"
        echo "1. Run server in stdio mode"
        echo "2. Send JSON-RPC messages via stdin"
        echo "3. Read responses from stdout"
        exit 0
        ;;

    *)
        echo "Error: Invalid transport type: $TRANSPORT_TYPE"
        echo "Valid types: http, sse, websocket, stdio"
        exit 1
        ;;
esac

echo ""
echo "Test completed."
