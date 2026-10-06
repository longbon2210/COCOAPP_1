import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

options = Options()
options.add_argument('--headless=new')
options.add_argument('--window-size=1920,1080')
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')

print("Starting driver...")
driver = webdriver.Chrome(options=options)
try:
    print("Navigating to http://localhost:3000...")
    driver.get("http://localhost:3000")
    time.sleep(5)
    driver.save_screenshot("test_screen_login.png")
    print("Screenshot saved successfully!")
finally:
    driver.quit()
