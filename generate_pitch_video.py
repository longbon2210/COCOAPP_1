import os
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')
import time
import math
import wave
import struct
import asyncio
import subprocess
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

# Danh sách các cảnh Pitching giới thiệu COCO APP
SCENES = [
    {
        "id": "scene1_intro",
        "url": "http://localhost:3000",
        "badge": "COCO APP · CAMPUS LIVING ECOSYSTEM",
        "title": "Welcome to COCO App",
        "subtitle": "The smart student living, roommate finding, and study platform",
        "narration": "For university students, finding safe housing and the right roommate is often overwhelming. Fake listings, inflated broker fees, and mismatched lifestyles create endless frustration. Welcome to COCO App — the all-in-one living and collaborative study platform built for university students."
    },
    {
        "id": "scene2_rooms",
        "url": "http://localhost:3000/?tab=0",
        "badge": "VERIFIED HOUSING · DIRECT BOOKING",
        "title": "Verified Student Accommodations",
        "subtitle": "Browse 100 Percent verified rooms near campus with zero broker fees",
        "narration": "First, explore Verified Student Accommodations. Students can browse quality rooms near campus with transparent pricing, full amenity details, and verified landlord contacts. With just one click, schedule a viewing directly with zero middleman fees."
    },
    {
        "id": "scene3_roommates",
        "url": "http://localhost:3000/?tab=1",
        "badge": "SMART MATCHING · LIFESTYLE & HABITS",
        "title": "AI-Powered Roommate Matching",
        "subtitle": "Match with ideal roommates based on lifestyle, sleep habits, and budget",
        "narration": "Second, discover Smart Roommate Matching. Finding someone you truly get along with has never been easier. COCO analyzes study habits, sleep schedules, budgets, and cleanliness preferences to calculate a compatibility score, helping you connect with the ideal roommate."
    },
    {
        "id": "scene4_study",
        "url": "http://localhost:3000/?tab=2",
        "badge": "CAMPUS STUDY HUB · COLLABORATION",
        "title": "Collaborative Study & Capstone Groups",
        "subtitle": "Find teammates for capstone projects, exam prep, and share resources",
        "narration": "Third, step into the Campus Study Hub. Beyond housing, COCO empowers students to excel academically. Create or join study groups for challenging subjects, find teammates for capstone projects in Flutter or Software Engineering, and share valuable learning materials."
    },
    {
        "id": "scene5_chat",
        "url": "http://localhost:3000/?tab=3",
        "badge": "REAL-TIME MESSAGING · SAFE CONNECT",
        "title": "Real-Time Direct Messaging",
        "subtitle": "Instant, safe conversations with potential roommates and landlords",
        "narration": "Fourth, experience Real-Time Direct Messaging. Communicate instantly and securely with potential roommates, landlords, and study partners. Discuss room details, plan move-in dates, and organize study sessions in one unified space."
    },
    {
        "id": "scene6_profile",
        "url": "http://localhost:3000/?tab=4",
        "badge": "STUDENT IDENTITY · VERIFIED BADGE",
        "title": "Personalized Student Profile",
        "subtitle": "Showcase your major, academic goals, and living preferences",
        "narration": "Fifth, customize your Student Profile. Highlight your major, academic goals, technical skills, and living habits with verified student badges, building an authentic and trusted campus community."
    },
    {
        "id": "scene7_conclusion",
        "url": "http://localhost:3000/?tab=0",
        "badge": "THE FUTURE OF STUDENT LIFE",
        "title": "Live Better, Study Smarter Together",
        "subtitle": "Join thousands of university students on COCO App today",
        "narration": "COCO App brings verified housing, intelligent matching, and academic collaboration together in one modern platform. Empowering students to live comfortably, connect meaningfully, and thrive throughout their university journey. Join COCO App today!"
    }
]

# 1. Tạo giọng đọc AI bằng edge-tts
def generate_voiceovers():
    print("=== BƯỚC 1: TẠO GIỌNG ĐỌC TIẾNG ANH (EDGE-TTS) ===")
    os.makedirs("video_assets/audio", exist_ok=True)
    voice = "en-US-ChristopherNeural"

    for scene in SCENES:
        out_file = f"video_assets/audio/{scene['id']}.mp3"
        if os.path.exists(out_file) and os.path.getsize(out_file) > 1000:
            print(f" -> Đã có audio: {out_file}")
            continue
        print(f"Generating voice for: {scene['id']}...")
        cmd = [
            sys.executable, "-m", "edge_tts",
            "--voice", voice,
            "--text", scene["narration"],
            "--write-media", out_file
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"Lỗi tạo voice: {res.stderr}")
        else:
            print(f" -> Đã tạo: {out_file}")

# 2. Chụp ảnh màn hình thực tế từ web app
def capture_screenshots():
    print("\n=== BƯỚC 2: CHỤP ẢNH MÀN HÌNH THỰC TẾ (SELENIUM CHROME) ===")
    os.makedirs("video_assets/raw_screens", exist_ok=True)

    if all(os.path.exists(f"video_assets/raw_screens/{s['id']}.png") and os.path.getsize(f"video_assets/raw_screens/{s['id']}.png") > 1000 for s in SCENES):
        print(" -> Toàn bộ 7 ảnh chụp thực tế đã sẵn sàng, bỏ qua bước chụp lại!")
        return

    options = Options()
    options.add_argument('--headless=new')
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')

    driver = webdriver.Chrome(options=options)
    try:
        # Bước khởi tạo session đăng nhập để các tab sau có đầy đủ dữ liệu
        print("Mở trang web để thiết lập phiên đăng nhập...")
        driver.get("http://localhost:3000")
        time.sleep(3)

        # Lưu session vào localStorage
        driver.execute_script("""
            localStorage.setItem('flutter.jwt_token', '"demo_jwt_token_video"');
            localStorage.setItem('flutter.user_email', '"0000@gmail.com"');
        """)
        time.sleep(1)

        for scene in SCENES:
            save_path = f"video_assets/raw_screens/{scene['id']}.png"
            if scene['id'] == 'scene1_intro':
                # Scene 1: Chụp màn hình đăng nhập nghệ thuật (xóa token tạm)
                driver.execute_script("localStorage.removeItem('flutter.jwt_token');")
                driver.get("http://localhost:3000")
                time.sleep(4)
                driver.save_screenshot(save_path)
                # Đặt lại token cho các cảnh sau
                driver.execute_script("""
                    localStorage.setItem('flutter.jwt_token', '"demo_jwt_token_video"');
                    localStorage.setItem('flutter.user_email', '"0000@gmail.com"');
                """)
            else:
                driver.get(scene["url"])
                time.sleep(4.5)
                driver.save_screenshot(save_path)

            print(f" -> Đã chụp ảnh thực tế: {save_path}")

    finally:
        driver.quit()

# 3. Tạo nhạc nền nhẹ nhàng (Ambient Lo-Fi Tech BGM)
def generate_ambient_bgm(total_duration=120, output_path="video_assets/bgm.wav"):
    print("\n=== BƯỚC 3: TẠO NHẠC NỀN AMBIENT BGM BẰNG PYTHON ===")
    if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
        print(" -> Nhạc nền BGM đã có sẵn, bỏ qua bước tạo lại!")
        return
    sample_rate = 44100
    num_samples = int(total_duration * sample_rate)
    
    # Hợp âm êm dịu phong cách Tech Startup: D maj7 -> G maj7 -> A sus -> F# min7
    chords = [
        [146.83, 220.00, 277.18, 329.63, 440.0],  # Dmaj7
        [196.00, 246.94, 293.66, 369.99, 440.0],  # Gmaj7
        [220.00, 293.66, 329.63, 440.00, 554.37], # Asus4 / A
        [185.00, 220.00, 277.18, 329.63, 440.0],  # F#m7
    ]
    chord_len = 4.0 # Mỗi hợp âm kéo dài 4 giây

    with wave.open(output_path, 'w') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)

        frames = bytearray()
        for i in range(num_samples):
            t = i / sample_rate
            chord_idx = int((t / chord_len) % len(chords))
            chord = chords[chord_idx]
            
            # Fade in/out giữa các hợp âm
            pos_in_chord = (t % chord_len) / chord_len
            env = math.sin(pos_in_chord * math.pi)

            # Tổng hợp các sóng sine ấm áp
            sample_val = 0.0
            for freq in chord:
                sample_val += math.sin(2 * math.pi * freq * t) * 0.2
                # Thêm hài âm nhẹ
                sample_val += math.sin(2 * math.pi * (freq * 2) * t) * 0.05

            sample_val *= env * 0.18 # Âm lượng vừa phải làm nền (-20dB)
            
            # Stereo panning nhẹ
            left_val = sample_val * (0.8 + 0.2 * math.sin(2 * math.pi * 0.1 * t))
            right_val = sample_val * (0.8 - 0.2 * math.sin(2 * math.pi * 0.1 * t))

            left_int = int(max(-32767, min(32767, left_val * 32767)))
            right_int = int(max(-32767, min(32767, right_val * 32767)))

            frames.extend(struct.pack('<hh', left_int, right_int))

        wav.writeframes(frames)
    print(f" -> Đã tạo BGM: {output_path}")

# 4. Lấy thời lượng audio bằng ffprobe
def get_audio_duration(file_path):
    cmd = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        file_path
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return float(res.stdout.strip())
    except Exception:
        return 12.0

# 5. Dựng từng phân cảnh với hiệu ứng Zoom chuyển động & Banner phụ đề nghệ thuật
def render_scenes():
    print("\n=== BƯỚC 4: RENDER TỪNG CẢNH VIDEO NGHỆ THUẬT (FFMPEG) ===")
    os.makedirs("video_assets/clips", exist_ok=True)
    clip_files = []

    for i, scene in enumerate(SCENES):
        audio_file = f"video_assets/audio/{scene['id']}.mp3"
        image_file = f"video_assets/raw_screens/{scene['id']}.png"
        clip_file = f"video_assets/clips/{scene['id']}.mp4"

        if os.path.exists(clip_file) and os.path.getsize(clip_file) > 100000:
            print(f" -> Clip đã có sẵn: {clip_file}")
            clip_files.append(clip_file)
            continue

        duration = get_audio_duration(audio_file) + 1.0 # Thêm 1.0s đệm chuyển cảnh
        fps = 30
        total_frames = int(duration * fps)

        badge_txt = scene['badge'].replace(":", "\\:").replace("'", "").replace("%", " Percent")
        title_txt = scene['title'].replace(":", "\\:").replace("'", "").replace("%", " Percent")
        subtitle_txt = scene['subtitle'].replace(":", "\\:").replace("'", "").replace("%", " Percent")

        font_bold = "C\\:/Windows/Fonts/arialbd.ttf"
        font_regular = "C\\:/Windows/Fonts/arial.ttf"

        vf_filter = (
            f"scale=1920:1080,"
            f"zoompan=z='min(zoom+0.0003,1.05)':d={total_frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps={fps},"
            f"drawbox=x=0:y=860:w=1920:h=4:color=0x4F46E5@0.95:t=fill,"
            f"drawbox=x=0:y=864:w=1920:h=216:color=0x0B0F19@0.88:t=fill,"
            f"drawtext=fontfile='{font_bold}':text='{badge_txt}':fontsize=20:fontcolor=0x818CF8:x=80:y=890,"
            f"drawtext=fontfile='{font_bold}':text='{title_txt}':fontsize=42:fontcolor=white:x=80:y=925,"
            f"drawtext=fontfile='{font_regular}':text='{subtitle_txt}':fontsize=24:fontcolor=0xCBD5E1:x=80:y=985"
        )

        print(f"Rendering clip {i+1}/{len(SCENES)}: {scene['id']} ({duration:.1f}s)...")
        cmd = [
            "ffmpeg", "-y",
            "-loop", "1", "-i", image_file,
            "-i", audio_file,
            "-vf", vf_filter,
            "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "192k",
            "-t", str(duration),
            "-shortest",
            clip_file
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"Lỗi render {scene['id']}: {res.stderr}")
        else:
            clip_files.append(clip_file)
            print(f" -> Hoàn thành clip: {clip_file}")

    return clip_files

# 6. Ghép toàn bộ phân cảnh và hòa trộn nhạc nền
def assemble_final_video(clip_files):
    print("\n=== BƯỚC 5: HÒA TRỘN VIDEO, LỒNG TIẾNG & NHẠC NỀN RA FILE MP4 ===")
    
    # Tạo file danh sách nối clip
    concat_list = "video_assets/concat_list.txt"
    with open(concat_list, "w", encoding="utf-8") as f:
        for clip in clip_files:
            abs_path = os.path.abspath(clip).replace("\\", "/")
            f.write(f"file '{abs_path}'\n")

    temp_video = "video_assets/temp_merged.mp4"
    print("Nối tất cả các cảnh video...")
    cmd_concat = [
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0",
        "-i", concat_list,
        "-c", "copy",
        temp_video
    ]
    subprocess.run(cmd_concat, check=True)

    # Lấy thời lượng thực tế của toàn bộ video
    total_dur = get_audio_duration(temp_video)
    fade_start = max(1.0, total_dur - 4.0)

    # Hòa trộn âm thanh giọng đọc với nhạc nền BGM êm ái
    output_final = "coco_app_pitch.mp4"
    bgm_file = "video_assets/bgm.wav"

    print(f"Hòa trộn âm thanh lồng tiếng với nhạc nền BGM (Tổng thời lượng: {total_dur:.1f}s)...")
    cmd_mix = [
        "ffmpeg", "-y",
        "-i", temp_video,
        "-i", bgm_file,
        "-filter_complex",
        f"[1:a]volume=0.15,afade=t=in:ss=0:d=2,afade=t=out:st={fade_start:.1f}:d=4[bgm];"
        f"[0:a][bgm]amix=inputs=2:duration=first:dropout_transition=2[aout]",
        "-map", "0:v",
        "-map", "[aout]",
        "-c:v", "copy",
        "-c:a", "aac", "-b:a", "256k",
        output_final
    ]
    subprocess.run(cmd_mix, check=True)

    print("\n=======================================================")
    print(f"🎉 HOÀN THÀNH VIDEO PITCHING: {os.path.abspath(output_final)}")
    print("=======================================================")

if __name__ == "__main__":
    generate_voiceovers()
    capture_screenshots()
    generate_ambient_bgm(total_duration=180)
    clips = render_scenes()
    assemble_final_video(clips)
