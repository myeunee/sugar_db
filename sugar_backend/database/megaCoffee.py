from selenium import webdriver 
from selenium.webdriver.common.by import By  
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import ElementClickInterceptedException, TimeoutException
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

def crawl_and_save():
    drinks = []
    page_number = 1

    next_page_selectors = [
        '#board_page > li:nth-child(6) > a',
        '#board_page > li:nth-child(7) > a',
        '#board_page > li:nth-child(7) > a',
        '#board_page > li:nth-child(7) > a',
        '#board_page > li:nth-child(6) > a',
        '#board_page > li:nth-child(6) > a'
    ]

    while page_number <= len(next_page_selectors) + 1:
        print(f"페이지 {page_number} 수집 중...")
        # 음료 목록을 가져옴
        drink_buttons = driver.find_elements(By.XPATH, '//*[@id="menu_list"]/li/a/div/div[2]/div[1]/div[1]')
        print(len(drink_buttons))

        for i in range(len(drink_buttons)):
            # 각 음료 버튼을 클릭하여 상세 정보 확인
            try:
                drink_button_xpath = f'//*[@id="menu_list"]/li[{i + 1}]/a/div/div[2]/div[1]/div[1]'
                drink_button = driver.find_element(By.XPATH, drink_button_xpath)

                # 스크롤하여 요소를 화면에 표시
                driver.execute_script("arguments[0].scrollIntoView(true);", drink_button)
                
                # JavaScript 클릭
                WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, drink_button_xpath))
                )
                driver.execute_script("arguments[0].click();", drink_button)

                # 음료 이름
                name_xpath = f'//*[@id="menu_list"]/li[{i + 1}]/div/div[1]/div[1]/div[1]/b'
                name = WebDriverWait(driver, 10).until(
                    EC.visibility_of_element_located((By.XPATH, name_xpath))
                ).text
                
                # 용량
                volume_xpath = f'//*[@id="menu_list"]/li[{i + 1}]/div/div[1]/div[2]/div[1]'
                volume_text = driver.find_element(By.XPATH, volume_xpath).text
                volume = extract_last_number(volume_text)
                
                # 당류
                sugar_xpath = f'//*[@id="menu_list"]/li[{i + 1}]/div/div[2]/ul/li[2]'
                sugar_text = driver.find_element(By.XPATH, sugar_xpath).text
                sugar = extract_last_number(sugar_text)

                # 칼로리
                calories_xpath = f'//*[@id="menu_list"]/li[{i + 1}]/div/div[1]/div[2]/div[2]'
                calories_text = driver.find_element(By.XPATH, calories_xpath).text
                calories = extract_last_number(calories_text)

                # 이미지 URL
                image_xpath = f'//*[@id="menu_list"]/li[{i+1}]/a/div/div[1]/img'
                image_element = driver.find_element(By.XPATH, image_xpath)
                image_url = image_element.get_attribute('src')

                # 음료 정보 저장
                drinks.append({
                    "cafe_id": 1,
                    "drink_name": name,
                    "volume": volume*29.5,
                    "sugar_content": sugar,
                    "calories": calories,
                    "image_url": image_url
                })

                # 상세 정보 창 닫기 (필요에 따라 수정)
                driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.ESCAPE)
                time.sleep(0.2)  # 대기 시간 추가
                
            except ElementClickInterceptedException as e:
                print(f"Error collecting data for drink {i + 1}: {e}. Retrying...")
                time.sleep(1)
                driver.execute_script("arguments[0].scrollIntoView(true);", drink_button)
                driver.execute_script("arguments[0].click();", drink_button)
                continue

            except TimeoutException as e:
                print(f"Timeout collecting data for drink {i + 1}: {e}")
                continue

            except Exception as e:
                print(f"Error collecting data for drink {i + 1}: {e}")
                continue

        try:
            next_page_button = driver.find_element(By.CSS_SELECTOR, next_page_selectors[page_number - 1])
            driver.execute_script("arguments[0].scrollIntoView(true);", next_page_button)
            driver.execute_script("arguments[0].click();", next_page_button)
            time.sleep(2)  # 페이지 로딩 대기
            wait_until_page_loaded(driver)
            page_number += 1
        except Exception as e:
            print(f"오류 발생: {e}")
            break

    return drinks


options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

url = "https://mega-mgccoffee.com/menu/?menu_category1=1&menu_category2=1"
driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=options)
driver.get(url)

wait_until_page_loaded(driver)

drinks_data = crawl_and_save()

driver.quit()

# JSON 파일로 저장
with open('megaCoffee.json', 'w', encoding='utf-8') as f:
    json.dump(drinks_data, f, ensure_ascii=False, indent=4)

print("******데이터 저장 완료******")