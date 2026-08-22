#!/bin/bash
# Test script to verify the deployed application is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTANCE_IP="${1:?Usage: ./test-application.sh <instance-ip>}"
APP_URL="http://${INSTANCE_IP}"
TIMEOUT=10

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Web Application Verification Tests               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

echo "Target: $APP_URL"
echo "Timeout: ${TIMEOUT}s per request\n"

# Test counter
PASSED=0
FAILED=0

# Function to print test result
print_result() {
    local test_name=$1
    local status=$2
    local message=$3

    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        if [ -n "$message" ]; then
            echo -e "  ${YELLOW}→${NC} $message"
        fi
        ((FAILED++))
    fi
}

# Test 1: Check if instance is accessible
echo -e "${YELLOW}[1/5]${NC} Testing network connectivity..."
if timeout $TIMEOUT curl -s -o /dev/null -w "%{http_code}" "$APP_URL" > /dev/null 2>&1; then
    print_result "Network connectivity" "pass"
else
    print_result "Network connectivity" "fail" "Cannot reach instance at $APP_URL"
    echo -e "\n${YELLOW}Troubleshooting:${NC}"
    echo "  • Check instance IP is correct"
    echo "  • Ensure security group allows port 80"
    echo "  • Wait 2-3 minutes for services to start"
    exit 1
fi

echo

# Test 2: Check HTTP status code
echo -e "${YELLOW}[2/5]${NC} Testing HTTP response..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m $TIMEOUT "$APP_URL")
if [ "$HTTP_CODE" = "200" ]; then
    print_result "HTTP 200 OK" "pass"
else
    print_result "HTTP 200 OK" "fail" "Got HTTP $HTTP_CODE"
fi

echo

# Test 3: Check if HTML contains hit counter elements
echo -e "${YELLOW}[3/5]${NC} Testing application response..."
RESPONSE=$(curl -s -m $TIMEOUT "$APP_URL")

if echo "$RESPONSE" | grep -q "Hit Counter"; then
    print_result "Page title" "pass"
else
    print_result "Page title" "fail" "Missing 'Hit Counter' in response"
fi

if echo "$RESPONSE" | grep -q "Total Page Hits"; then
    print_result "Counter display" "pass"
else
    print_result "Counter display" "fail" "Missing counter display in HTML"
fi

if echo "$RESPONSE" | grep -qE '<div class="count">[0-9]+</div>'; then
    COUNTER_VALUE=$(echo "$RESPONSE" | grep -oP '<div class="count">\K[0-9]+' | head -1)
    print_result "Counter value rendering" "pass" "Current count: $COUNTER_VALUE"
else
    print_result "Counter value rendering" "fail" "Invalid counter HTML structure"
fi

echo

# Test 4: Test health endpoint
echo -e "${YELLOW}[4/5]${NC} Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -m $TIMEOUT "$APP_URL/health" 2>&1)

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    print_result "Health check endpoint" "pass"
else
    print_result "Health check endpoint" "fail" "Response: $HEALTH_RESPONSE"
fi

echo

# Test 5: Test database read/write (hit counter increment)
echo -e "${YELLOW}[5/5]${NC} Testing database operations..."

# Get initial count
INITIAL_COUNT=$(curl -s -m $TIMEOUT "$APP_URL" | grep -oP '<div class="count">\K[0-9]+' | head -1)

if [ -z "$INITIAL_COUNT" ]; then
    print_result "Database connectivity" "fail" "Cannot extract counter value"
else
    # Wait a moment and make another request
    sleep 1

    # Get new count
    NEW_COUNT=$(curl -s -m $TIMEOUT "$APP_URL" | grep -oP '<div class="count">\K[0-9]+' | head -1)

    if [ -z "$NEW_COUNT" ]; then
        print_result "Database read" "fail" "Cannot read updated value"
    elif [ "$NEW_COUNT" -gt "$INITIAL_COUNT" ]; then
        print_result "Database read/write" "pass" "$INITIAL_COUNT → $NEW_COUNT"
    else
        print_result "Database read/write" "fail" "Counter did not increment ($INITIAL_COUNT → $NEW_COUNT)"
    fi
fi

echo
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Test Summary                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

TOTAL=$((PASSED + FAILED))
echo -e "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
else
    echo -e "${GREEN}Failed: $FAILED${NC}"
fi

echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✓ All tests passed!                         ║${NC}"
    echo -e "${GREEN}║     Your application is working correctly.             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"

    echo "Application Details:"
    echo "  URL: $APP_URL"
    echo "  Health Check: $APP_URL/health"
    echo "  Current Hit Count: $NEW_COUNT"

    echo -e "\nNext Steps:"
    echo "  • Share the URL to start accumulating hits"
    echo "  • Monitor logs: ssh ubuntu@$INSTANCE_IP 'sudo journalctl -u app -f'"
    echo "  • Scale up the instance if needed"

    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║            ✗ Some tests failed                         ║${NC}"
    echo -e "${RED}║     Check the application logs for details.            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}\n"

    echo "Debugging Steps:"
    echo "  1. SSH into the instance:"
    echo "     ssh -i /path/to/keypair.pem ubuntu@$INSTANCE_IP"
    echo ""
    echo "  2. Check service status:"
    echo "     sudo systemctl status app"
    echo "     sudo systemctl status nginx"
    echo ""
    echo "  3. View application logs:"
    echo "     sudo journalctl -u app -n 50"
    echo ""
    echo "  4. View user data script logs:"
    echo "     sudo tail -100 /var/log/user-data.log"
    echo ""
    echo "  5. Test local connectivity:"
    echo "     curl http://localhost:8000"
    echo "     curl http://localhost/health"
    echo ""
    echo "  6. Check Nginx configuration:"
    echo "     sudo nginx -t"
    echo ""
    echo "  7. View Nginx error logs:"
    echo "     sudo tail -50 /var/log/nginx/error.log"

    exit 1
fi
