$regBody = @{
    email = "teststudent1@cocoapp.vn"
    password = "Password123!"
    fullName = "Nguyen Van Test"
    university = "Đại học CNTT & Truyền Thông"
    major = "Kỹ thuật phần mềm"
} | ConvertTo-Json

Write-Host "--- 1. Testing Register ---"
try {
    $regRes = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/register" -Method Post -ContentType "application/json; charset=utf-8" -Body $regBody
    Write-Host "Register Success:" ($regRes | ConvertTo-Json -Depth 2)
} catch {
    Write-Host "Register Failed:" $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Response Body:" $reader.ReadToEnd()
    }
}

Write-Host "`n--- 2. Testing Login ---"
$loginBody = @{
    email = "teststudent1@cocoapp.vn"
    password = "Password123!"
} | ConvertTo-Json

try {
    $loginRes = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -ContentType "application/json; charset=utf-8" -Body $loginBody
    Write-Host "Login Success! Token received. User ID:" $loginRes.user.id
    $token = $loginRes.token
} catch {
    Write-Host "Login Failed:" $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Response Body:" $reader.ReadToEnd()
    }
}

Write-Host "`n--- 3. Testing Get Users ---"
try {
    $users = Invoke-RestMethod -Uri "http://localhost:5000/api/users" -Method Get
    Write-Host "Users Count:" $users.Count
    Write-Host "First user:" $users[0].name "(" $users[0].email ")"
} catch {
    Write-Host "Get Users Failed:" $_.Exception.Message
}

Write-Host "`n--- 4. Testing Send Message ---"
$msgBody = @{
    senderEmail = "teststudent1@cocoapp.vn"
    receiverEmail = "0000@gmail.com"
    senderName = "Nguyen Van Test"
    receiverName = "Mai Lan"
    text = "Chào bạn Lan, mình muốn hỏi về phòng trọ ghép!"
} | ConvertTo-Json

try {
    $msgRes = Invoke-RestMethod -Uri "http://localhost:5000/api/messages" -Method Post -ContentType "application/json; charset=utf-8" -Body $msgBody
    Write-Host "Send Message Success! Message ID:" $msgRes.id
} catch {
    Write-Host "Send Message Failed:" $_.Exception.Message
}

Write-Host "`n--- 5. Testing Get Messages Between Users ---"
try {
    $msgs = Invoke-RestMethod -Uri "http://localhost:5000/api/messages?user1=teststudent1@cocoapp.vn&user2=0000@gmail.com" -Method Get
    Write-Host "Found Messages Count:" $msgs.Count
    foreach ($m in $msgs) {
        Write-Host "[$($m.senderEmail) -> $($m.receiverEmail)]: $($m.text)"
    }
} catch {
    Write-Host "Get Messages Failed:" $_.Exception.Message
}
