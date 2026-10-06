import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains

options = Options()
options.add_argument('--headless=new')
options.add_argument('--window-size=1920,1080')
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')

print("Starting Chrome driver...")
driver = webdriver.Chrome(options=options)

try:
    print("Step 1: Capturing Welcome & Login Screen...")
    driver.get("http://localhost:3000")
    time.sleep(4)
    driver.save_screenshot("scene1_welcome.png")
    print("Saved scene1_welcome.png")

    print("Step 2: Clicking Demo Login...")
    # In Flutter Web, we can either click by coordinates or click with ActionChains or execute JavaScript
    # Let's find the button or click in the center lower portion where the demo button is located
    # The container max-width is 460, centered at x=960, y approx 740
    actions = ActionChains(driver)
    # Move to center and click "Khám Phá Nhanh" (approx x=960, y=750 for 1920x1080)
    actions.move_by_offset(960, 755).click().perform()
    time.sleep(4)

    # Let's see if we reached the main screen
    driver.save_screenshot("scene2_rooms.png")
    print("Saved scene2_rooms.png")

    # In Desktop top bar, tabs are centered around x=960, y=35
    # Tab 0: Thuê Trọ (~820, 35)
    # Tab 1: Ở Ghép (~910, 35)
    # Tab 2: Góc Học Tập (~1010, 35)
    # Tab 3: Tin Nhắn (~1110, 35)
    # Tab 4: Cá Nhân (~1200, 35)
    
    print("Step 3: Clicking Roommate Tab...")
    # Reset actions position
    actions = ActionChains(driver)
    actions.move_to_element_with_offset(driver.find_element(By.TAG_NAME, "body"), 910, 35).click().perform()
    time.sleep(2.5)
    driver.save_screenshot("scene3_roommates.png")
    print("Saved scene3_roommates.png")

    print("Step 4: Clicking Study Hub Tab...")
    actions = ActionChains(driver)
    actions.move_to_element_with_offset(driver.find_element(By.TAG_NAME, "body"), 1010, 35).click().perform()
    time.sleep(2.5)
    driver.save_screenshot("scene4_study.png")
    print("Saved scene4_study.png")

    print("Step 5: Clicking Chat Tab...")
    actions = ActionChains(driver)
    actions.move_to_element_with_offset(driver.find_element(By.TAG_NAME, "body"), 1110, 35).click().perform()
    time.sleep(2.5)
    driver.save_screenshot("scene5_chat.png")
    print("Saved scene5_chat.png")

    print("Step 6: Clicking Profile Tab...")
    actions = ActionChains(driver)
    actions.move_to_element_with_offset(driver.find_element(By.TAG_NAME, "body"), 1200, 35).click().perform()
    time.sleep(2.5)
    driver.save_screenshot("scene6_profile.png")
    print("Saved scene6_profile.png")

finally:
    driver.quit()
    print("All captures completed!")
