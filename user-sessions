#user-sessions.sh — Show active user sessions on the server

echo "Active sessions:"
who

echo ""
echo "Logged in users:"
w

echo ""
echo "Last 5 logins:"
last -n 5

echo ""
echo "Failed login attempts:"
lastb -n 5 2>/dev/null || echo "No failed login data available"
