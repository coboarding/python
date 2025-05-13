import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

def test_chrome_starts():
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    driver = webdriver.Chrome(options=options)
    driver.get("https://www.example.com/")
    assert "Example Domain" in driver.title
    driver.quit()
