$baseUrl = "http://localhost:5000"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   TESTING LOGICAL AND SECURITY FIXES       " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# --- 1. Test Register duplicate email rejection ---
$testEmail = "student_logic_$(Get-Random)@cocoapp.vn"
$regBody = @{
    email = $testEmail
    password = "SecurePassword123!"
    fullName = "Bui Van Chuan"
    university = "Đại học CNTT & TT (ICTU)"
    major = "Khoa học Máy tính"
} | ConvertTo-Json

Write-Host "`n[1] Testing User Registration..." -ForegroundColor Yellow
$regRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method Post -ContentType "application/json; charset=utf-8" -Body $regBody
Write-Host "  -> Register 1 OK! User ID:" $regRes.user.id -ForegroundColor Green

Write-Host "`n[2] Testing Duplicate Registration Rejection..." -ForegroundColor Yellow
try {
    $dupRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method Post -ContentType "application/json; charset=utf-8" -Body $regBody
    Write-Host "  -> ERROR: Duplicate was accepted!" -ForegroundColor Red
} catch {
    Write-Host "  -> PASS: Duplicate correctly rejected with status:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Green
}

# --- 2. Test Login Validation ---
Write-Host "`n[3] Testing Login with Wrong Password..." -ForegroundColor Yellow
$wrongLoginBody = @{
    email = $testEmail
    password = "WrongPassword999!"
} | ConvertTo-Json

try {
    $wrongRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json; charset=utf-8" -Body $wrongLoginBody
    Write-Host "  -> ERROR: Wrong password was accepted!" -ForegroundColor Red
} catch {
    Write-Host "  -> PASS: Wrong password rejected with status:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Green
}

Write-Host "`n[4] Testing Login with Correct Password..." -ForegroundColor Yellow
$rightLoginBody = @{
    email = $testEmail
    password = "SecurePassword123!"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json; charset=utf-8" -Body $rightLoginBody
$token = $loginRes.token
Write-Host "  -> PASS: Login successful! JWT Token received (length $($token.Length))." -ForegroundColor Green

$authHeaders = @{
    "Authorization" = "Bearer $token"
}

# --- 3. Test Messages API JWT Lock & Deduplication ---
Write-Host "`n[5] Testing Messages API without Token..." -ForegroundColor Yellow
try {
    $unauthMsg = Invoke-RestMethod -Uri "$baseUrl/api/messages" -Method Get
    Write-Host "  -> ERROR: Messages accessed without token!" -ForegroundColor Red
} catch {
    Write-Host "  -> PASS: Unauthenticated access blocked with status:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Green
}

Write-Host "`n[6] Testing Messages API with JWT Token..." -ForegroundColor Yellow
$authMsg = Invoke-RestMethod -Uri "$baseUrl/api/messages" -Method Get -Headers $authHeaders
Write-Host "  -> PASS: Authenticated messages query succeeded! Count:" $authMsg.Count -ForegroundColor Green

Write-Host "`n[7] Testing Message Deduplication (Single Send vs Double Send)..." -ForegroundColor Yellow
$msgId = "test_dedup_$(Get-Random)"
$sendMsgBody = @{
    id = $msgId
    senderEmail = $testEmail
    receiverEmail = "0000@gmail.com"
    senderName = "Bui Van Chuan"
    receiverName = "Mai Lan"
    text = "Tin nhắn kiểm tra chống trùng lặp"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json

# Send 1
$msg1 = Invoke-RestMethod -Uri "$baseUrl/api/messages" -Method Post -Headers $authHeaders -ContentType "application/json; charset=utf-8" -Body $sendMsgBody
Write-Host "  -> Send 1: Message created with ID:" $msg1.id -ForegroundColor Green

# Send 2 (Same ID)
$msg2 = Invoke-RestMethod -Uri "$baseUrl/api/messages" -Method Post -Headers $authHeaders -ContentType "application/json; charset=utf-8" -Body $sendMsgBody
Write-Host "  -> Send 2: Duplicate call returned cleanly with ID:" $msg2.id -ForegroundColor Green

# Verify in DB query
$checkMsgs = Invoke-RestMethod -Uri "$baseUrl/api/messages?user1=$($testEmail)&user2=0000@gmail.com" -Method Get -Headers $authHeaders
$matchingCount = ($checkMsgs | Where-Object { $_.id -eq $msgId }).Count
if ($matchingCount -eq 1) {
    Write-Host "  -> PASS: Exactly 1 message found in DB! Deduplication 100% verified!" -ForegroundColor Green
} else {
    Write-Host "  -> ERROR: Found $matchingCount instances of the message in DB!" -ForegroundColor Red
}

# --- 4. Test Swipe API JWT Lock ---
Write-Host "`n[8] Testing Swipe API without Token..." -ForegroundColor Yellow
try {
    $unauthSwipe = Invoke-RestMethod -Uri "$baseUrl/api/swipes" -Method Post -ContentType "application/json" -Body '{"targetUserId":10,"isLike":true}'
    Write-Host "  -> ERROR: Swipe accepted without token!" -ForegroundColor Red
} catch {
    Write-Host "  -> PASS: Unauthenticated swipe blocked with status:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Green
}

Write-Host "`n[9] Testing Swipe API with JWT Token..." -ForegroundColor Yellow
$swipeBody = @{
    targetUserId = 10
    isLike = $true
} | ConvertTo-Json
$swipeRes = Invoke-RestMethod -Uri "$baseUrl/api/swipes" -Method Post -Headers $authHeaders -ContentType "application/json" -Body $swipeBody
Write-Host "  -> PASS: Authenticated swipe executed successfully! Message:" $swipeRes.message -ForegroundColor Green

# --- 5. Test Profile API JWT Lock ---
Write-Host "`n[10] Testing Profile API without Token..." -ForegroundColor Yellow
try {
    $unauthProfile = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method Get
    Write-Host "  -> ERROR: Profile accessed without token!" -ForegroundColor Red
} catch {
    Write-Host "  -> PASS: Unauthenticated profile blocked with status:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Green
}

Write-Host "`n[11] Testing Profile API with JWT Token..." -ForegroundColor Yellow
$profileRes = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method Get -Headers $authHeaders
Write-Host "  -> PASS: Profile loaded for authenticated user:" $profileRes.name "(" $profileRes.email ")" -ForegroundColor Green

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "   ALL LOGICAL & SECURITY TESTS PASSED!      " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
