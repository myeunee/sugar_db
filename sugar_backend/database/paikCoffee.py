from selenium import webdriver 
from selenium.webdriver.common.by import By  
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import ElementClickInterceptedException, TimeoutException, NoSuchElementException
import json
import time
import re


def wait_until_page_loaded(driver):
    timeout = 20
    WebDriverWait(driver, timeout).until(
        lambda x: x.execute_script("return document.readyState == 'complete'")
    )
    print("페이지 로드 완료")

def extract_last_number(text):
    matches = re.findall(r"[-+]?\d*\.\d+|\d+", text)
    return float(matches[-1]) if matches else None

def get_volume(volume_text):
    volume = extract_last_number(volume_text)
    if volume_text.strip().lower().endswith("oz"):
        return volume * 29.5  # Convert oz to ml
    else:
        return volume
    return None  # Handle cases where the unit is unknown or missing

def crawl_and_save(url, cafe_id):
    drinks = []
    driver.get(url)
    wait_until_page_loaded(driver)

    while True:
        # 음료 목록을 가져옴
        drink_buttons = driver.find_elements(By.XPATH, '//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li/p')
        print(len(drink_buttons))

        for i in range(len(drink_buttons)):
            # 각 음료 버튼을 클릭하여 상세 정보 확인
            try:
                drink_button_xpath = f'//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li[{i+1}]/p'
                drink_button = driver.find_element(By.XPATH, drink_button_xpath)

                # 스크롤하여 요소를 화면에 표시
                driver.execute_script("arguments[0].scrollIntoView(true);", drink_button)
                
                # JavaScript 클릭
                WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, drink_button_xpath))
                )
                driver.execute_script("arguments[0].click();", drink_button)

                # 음료 이름
                name_xpath = f'//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li[{i+1}]/div[2]/h3'
                name = WebDriverWait(driver, 10).until(
                    EC.visibility_of_element_located((By.XPATH, name_xpath))
                ).text
                
                # 용량
                volume_xpath = f'//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li[{i+1}]/div[2]/div[2]/p'
                volume_text = driver.find_element(By.XPATH, volume_xpath).text
                volume = get_volume(volume_text)
                
                # 당류
                sugar_xpath = f'//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li[{i+1}]/div[2]/div[2]/ul/li[4]/div[2]'
                try:
                    sugar_text = driver.find_element(By.XPATH, sugar_xpath).text
                    sugar = extract_last_number(sugar_text)
                except NoSuchElementException:
                    sugar = 0.0

                # 나트륨
                sodium_xpath = f'//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li[{i+1}]/div[2]/div[2]/ul/li[3]/div[2]'
                try:
                    sodium_text = driver.find_element(By.XPATH, sodium_xpath).text
                    sodium = extract_last_number(sodium_text)
                except NoSuchElementException:
                    sodium = 0.0

                # 칼로리
                calories_xpath = f'//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li[{i+1}]/div[2]/div[2]/ul/li[2]/div[2]'
                calories_text = driver.find_element(By.XPATH, calories_xpath).text
                calories = extract_last_number(calories_text)

                # 이미지 URL
                image_xpath = f'//*[@id="content-wrap"]/div[2]/div/div[2]/ul/li[{i+1}]/div[1]/img'
                image_element = driver.find_element(By.XPATH, image_xpath)
                image_url = image_element.get_attribute('src')

                # 음료 정보 저장
                drinks.append({
                    "name": name,
                    "volume": volume,
                    "sugar_content": sugar,
                    "calories": calories,
                    "sodium_content": sodium,
                    "image_url": image_url,
                    "cafe_id": 2
                })

                # 상세 정보 창 닫기 (필요에 따라 수정)
                driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.ESCAPE)
                time.sleep(0.2)  # 대기 시간 추가
                
            except (ElementClickInterceptedException, NoSuchElementException, TimeoutException) as e:
                print(f"Error collecting data for drink {i + 1}: {e}. Skipping...")
                continue

        # 더 이상 페이지가 없으면 중지
        if not next_page_exists(driver):
            break

    return drinks

def next_page_exists(driver):
    try:
        next_page_button = driver.find_element(By.CSS_SELECTOR, '.next.page-numbers')
        if next_page_button:
            driver.execute_script("arguments[0].scrollIntoView(true);", next_page_button)
            driver.execute_script("arguments[0].click();", next_page_button)
            wait_until_page_loaded(driver)
            return True
    except NoSuchElementException:
        return False
    return False


options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=options)

urls = [
    ("https://paikdabang.com/menu/menu_coffee/", 1),
    ("https://paikdabang.com/menu/menu_drink/", 2),
    ("https://paikdabang.com/menu/menu_ccino/",3)
]

drinks_data = []

for url, cafe_id in urls:
    print(f"수집 중: {url}")
    drinks_data.extend(crawl_and_save(url, cafe_id))

driver.quit()

# JSON 파일로 저장
with open('paikCoffee.json', 'w', encoding='utf-8') as f:
    json.dump(drinks_data, f, ensure_ascii=False, indent=4)

print("******데이터 저장 완료******")
