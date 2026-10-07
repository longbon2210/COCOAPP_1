import requests
import json
import random
import time
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

base_url = "http://localhost:5000"
rnd = random.randint(100000, 999999)
email_a = f"user_a_{rnd}@cocoapp.vn"
email_b = f"user_b_{rnd}@cocoapp.vn"
password = "Password123@"

print("=" * 60)
print(" KIEM TRA TUONG TAC THUC TE GIUA 2 NGUOI DUNG MOI (A & B) ")
print("=" * 60)

# 1. Đăng ký User A
print(f"\n[1] Đăng ký User A: Nguyễn Văn An ({email_a})...")
reg_a = requests.post(f"{base_url}/api/auth/register", json={
    "email": email_a,
    "password": password,
    "fullName": "Nguyễn Văn An",
    "university": "Đại học CNTT & Truyền Thông (ICTU)",
    "major": "Kỹ thuật phần mềm"
})
assert reg_a.status_code in [200, 201], f"Đăng ký A thất bại: {reg_a.text}"
data_a = reg_a.json()
token_a = data_a["token"]
user_a_id = data_a["user"]["id"]
print(f" -> OK: User A đăng ký thành công! ID: {user_a_id}, Token: {token_a[:20]}...")

# 2. Đăng ký User B
print(f"\n[2] Đăng ký User B: Trần Thị Bình ({email_b})...")
reg_b = requests.post(f"{base_url}/api/auth/register", json={
    "email": email_b,
    "password": password,
    "fullName": "Trần Thị Bình",
    "university": "Đại học CNTT & Truyền Thông (ICTU)",
    "major": "Khoa học máy tính"
})
assert reg_b.status_code in [200, 201], f"Đăng ký B thất bại: {reg_b.text}"
data_b = reg_b.json()
token_b = data_b["token"]
user_b_id = data_b["user"]["id"]
print(f" -> OK: User B đăng ký thành công! ID: {user_b_id}, Token: {token_b[:20]}...")

headers_a = {"Authorization": f"Bearer {token_a}", "Content-Type": "application/json"}
headers_b = {"Authorization": f"Bearer {token_b}", "Content-Type": "application/json"}

# 3. User A tạo bài đăng Ở Ghép
print(f"\n[3] User A đăng bài tìm bạn ở ghép (POST /api/users)...")
post_user = requests.post(f"{base_url}/api/users", headers=headers_a, json={
    "email": email_a,
    "name": "Nguyễn Văn An",
    "university": "Đại học CNTT & Truyền Thông (ICTU)",
    "major": "Kỹ thuật phần mềm",
    "roomLocation": "Khu Z115, gần cổng trường ICTU",
    "roomStatus": "Đang tìm bạn ở ghép chung phòng",
    "rentalBudget": 1600000,
    "bio": "Sinh viên K21 nghiêm túc, không hút thuốc, thích công nghệ và học nhóm.",
    "studyGoal": "Cùng học lập trình web và làm đồ án tốt nghiệp",
    "gender": "Nam",
    "isSmoker": False,
    "hasPet": False,
    "compatibilityScore": 96
})
assert post_user.status_code in [200, 201], f"Đăng bài ở ghép lỗi: {post_user.text}"
print(f" -> OK: Bài đăng ở ghép của User A đã lưu lên server! {post_user.json().get('message')}")

# 4. User A tạo nhóm học tập (Góc Học Tập)
print(f"\n[4] User A tạo nhóm học tập mới (POST /api/posts)...")
post_study = requests.post(f"{base_url}/api/posts", headers=headers_a, json={
    "id": f"study_{rnd}",
    "title": "Nhóm ôn thi Lập trình Web & Flutter ICTU",
    "description": "Cần tìm 3-4 bạn học cùng chuyên ngành để luyện thi và làm bài tập lớn.",
    "subject": "Lập trình Web",
    "university": "ICTU",
    "authorEmail": email_a,
    "authorName": "Nguyễn Văn An",
    "authorAvatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500",
    "membersCount": 1,
    "maxMembers": 5,
    "tags": ["Flutter", "C#", "Lập trình Web"],
    "status": "Đang tuyển thành viên"
})
assert post_study.status_code in [200, 201], f"Tạo nhóm học tập lỗi: {post_study.text}"
print(f" -> OK: Nhóm học tập tạo thành công! ID: {post_study.json().get('id')}")

# 5. User A đăng tin cho thuê phòng (Tìm Phòng)
print(f"\n[5] User A đăng tin phòng trọ cho thuê (POST /api/rooms)...")
post_room = requests.post(f"{base_url}/api/rooms", headers=headers_a, json={
    "id": f"room_{rnd}",
    "title": "Phòng trọ khép kín 22m2 đường Z115 cổng ICTU",
    "address": "Số 45, Đường Z115, Tân Thịnh, Thái Nguyên",
    "universityNear": "ICTU",
    "pricePerMonth": 1500000,
    "deposit": 1500000,
    "areaM2": 22,
    "landlordName": "Nguyễn Văn An",
    "landlordPhone": "0988123456",
    "authorEmail": email_a,
    "description": "Phòng sạch sẽ, điều hòa, nóng lạnh, giờ giấc tự do.",
    "isAvailable": True
})
assert post_room.status_code in [200, 201], f"Đăng tin phòng lỗi: {post_room.text}"
print(f" -> OK: Tin phòng tạo thành công! ID: {post_room.json().get('id')}")

# 6. User B duyệt ứng dụng và tìm thấy các bài đăng của User A
print(f"\n[6] User B duyệt và nhìn thấy các bài đăng của User A...")
get_users = requests.get(f"{base_url}/api/users", headers=headers_b)
users_list = get_users.json()
found_user_a = next((u for u in users_list if u.get("email") == email_a), None)
assert found_user_a is not None, "User B không thấy hồ sơ ở ghép của User A!"
print(f" -> PASS: User B thấy bài đăng ở ghép của User A: Vị trí='{found_user_a['roomLocation']}', Trạng thái='{found_user_a['roomStatus']}'")

get_posts = requests.get(f"{base_url}/api/posts", headers=headers_b)
posts_list = get_posts.json()
found_post_a = next((p for p in posts_list if p.get("authorEmail") == email_a), None)
assert found_post_a is not None, "User B không thấy bài đăng nhóm học của User A!"
print(f" -> PASS: User B thấy nhóm học tập của User A: '{found_post_a['title']}'")

get_rooms = requests.get(f"{base_url}/api/rooms", headers=headers_b)
rooms_list = get_rooms.json()
found_room_a = next((r for r in rooms_list if r.get("authorEmail") == email_a), None)
assert found_room_a is not None, "User B không thấy tin phòng trọ của User A!"
print(f" -> PASS: User B thấy tin phòng trọ của User A: '{found_room_a['title']}'")

# 7. User B liên hệ nhắn tin cho User A
print(f"\n[7] User B nhắn tin liên hệ cho User A...")
send_b = requests.post(f"{base_url}/api/messages", headers=headers_b, json={
    "id": f"msg_b_to_a_{rnd}",
    "senderEmail": email_b,
    "receiverEmail": email_a,
    "senderName": "Trần Thị Bình",
    "receiverName": "Nguyễn Văn An",
    "text": "Chào bạn An! Mình thấy bài đăng tìm bạn ở ghép của bạn ở Z115. Phòng còn chỗ không bạn?"
})
assert send_b.status_code in [200, 201], f"Gửi tin nhắn từ B lỗi: {send_b.text}"
print(f" -> OK: Tin nhắn từ User B đã gửi thành công! Nội dung: '{send_b.json().get('text')}'")

# 8. User A vào hộp thư nhận được tin nhắn từ User B
print(f"\n[8] User A kiểm tra hòm thư nhận tin nhắn...")
inbox_a = requests.get(f"{base_url}/api/messages?myEmail={email_a}", headers=headers_a)
assert inbox_a.status_code == 200, f"Lấy inbox A lỗi: {inbox_a.text}"
msg_received_by_a = next((m for m in inbox_a.json() if m.get("senderEmail") == email_b), None)
assert msg_received_by_a is not None, "User A không thấy tin nhắn của User B trong hòm thư!"
print(f" -> PASS: User A đã nhận được tin nhắn từ {msg_received_by_a['senderName']}: '{msg_received_by_a['text']}'")

# 9. User A trả lời lại cho User B
print(f"\n[9] User A phản hồi tin nhắn lại cho User B...")
send_a = requests.post(f"{base_url}/api/messages", headers=headers_a, json={
    "id": f"msg_a_to_b_{rnd}",
    "senderEmail": email_a,
    "receiverEmail": email_b,
    "senderName": "Nguyễn Văn An",
    "receiverName": "Trần Thị Bình",
    "text": "Chào Bình nhé! Phòng vẫn còn 1 chỗ sạch sẽ đủ đồ. Chiều mai 17h30 bạn qua xem phòng được không?"
})
assert send_a.status_code in [200, 201], f"Gửi phản hồi từ A lỗi: {send_a.text}"
print(f" -> OK: Phản hồi từ User A đã gửi thành công! Nội dung: '{send_a.json().get('text')}'")

# 10. User B kiểm tra cuộc hội thoại hoàn chỉnh 2 chiều
print(f"\n[10] User B kiểm tra cuộc hội thoại 2 chiều hoàn chỉnh...")
convo = requests.get(f"{base_url}/api/messages?user1={email_b}&user2={email_a}", headers=headers_b)
assert convo.status_code == 200, f"Lấy hội thoại lỗi: {convo.text}"
messages = convo.json()
print(f" -> Tổng số tin nhắn trong cuộc trò chuyện: {len(messages)}")
for m in messages:
    print(f"    [{m['senderName']}]: {m['text']}")
assert len(messages) >= 2, "Cuộc hội thoại thiếu tin nhắn!"
print(" -> PASS: Xác nhận tương tác hội thoại 2 chiều thực tế hoàn toàn chính xác!")

# 11. Tương tác Quẹt Thẻ & Tương Hợp (Swipe & Match)
print(f"\n[11] Kiểm tra Quẹt thẻ tương hợp 2 chiều giữa User A và User B...")
swipe_a = requests.post(f"{base_url}/api/swipes", headers=headers_a, json={
    "swiperId": user_a_id,
    "targetUserId": user_b_id,
    "isLike": True
})
assert swipe_a.status_code in [200, 201]
print(f" -> User A 'Thích' User B: isMatch={swipe_a.json().get('isMatch')}")

swipe_b = requests.post(f"{base_url}/api/swipes", headers=headers_b, json={
    "swiperId": user_b_id,
    "targetUserId": user_a_id,
    "isLike": True
})
assert swipe_b.status_code in [200, 201]
print(f" -> User B 'Thích' lại User A: isMatch={swipe_b.json().get('isMatch')}")
assert swipe_b.json().get("isMatch") is True, "Tương hợp 2 chiều thất bại!"

matches_a = requests.get(f"{base_url}/api/swipes/matches/{user_a_id}", headers=headers_a)
assert matches_a.status_code == 200
matched_b = next((m for m in matches_a.json() if m.get("id") == user_b_id or m.get("email") == email_b), None)
assert matched_b is not None, "User B không có trong danh sách Match của User A!"
print(f" -> PASS: User B đã xuất hiện trong danh sách bạn bè Tương Hợp của User A: '{matched_b['name']}' 🎉")

print("\n" + "=" * 60)
print(" TOÀN BỘ 11 BƯỚC TƯƠNG TÁC THỰC TẾ GIỮA 2 TÀI KHOẢN ĐÃ THÀNH CÔNG RỰC RỠ! ")
print("=" * 60)
