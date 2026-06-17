import re
import pandas as pd
import requests
import numpy as np
from bs4 import BeautifulSoup
import time
from datetime import datetime
import json
from typing import List, Dict, Any

# تكوين API
API_BASE_URL = "http://localhost/:8000"  # غير هذا حسب عنوان السيرفر الخاص بك
API_PROPERTIES_ENDPOINT = f"{API_BASE_URL}/real-estate/properties"
API_BATCH_ENDPOINT = f"{API_BASE_URL}/real-estate/properties/batch"

# Headers للـ API
API_HEADERS = {"Content-Type": "application/json", "Accept": "application/json"}


def send_to_api(property_data: Dict[str, Any]) -> bool:
    """إرسال عقار واحد إلى API"""
    try:
        response = requests.post(
            API_PROPERTIES_ENDPOINT, json=property_data, headers=API_HEADERS, timeout=10
        )

        if response.status_code == 200 or response.status_code == 201:
            print(f"✅ تم إرسال العقار: {property_data.get('title', 'N/A')[:50]}")
            return True
        else:
            print(
                f"❌ فشل إرسال العقار: {response.status_code} - {response.text[:100]}"
            )
            return False

    except Exception as e:
        print(f"❌ خطأ في الاتصال بالـ API: {e}")
        return False


def send_batch_to_api(
    properties: List[Dict[str, Any]], batch_size: int = 10
) -> Dict[str, int]:
    """إرسال مجموعة من العقارات إلى API دفعة واحدة"""
    results = {"success": 0, "failed": 0, "total": len(properties)}

    for i in range(0, len(properties), batch_size):
        batch = properties[i : i + batch_size]
        print(
            f"\n📤 إرسال دفعة {i//batch_size + 1}/{(len(properties)-1)//batch_size + 1} ({len(batch)} عقار)..."
        )

        try:
            response = requests.post(
                API_BATCH_ENDPOINT,
                json={"properties": batch},
                headers=API_HEADERS,
                timeout=30,
            )

            if response.status_code == 200 or response.status_code == 201:
                result = response.json()
                results["success"] += result.get("added", len(batch))
                print(f"✅ تم إرسال {result.get('added', len(batch))} عقار بنجاح")
            else:
                print(f"⚠️ فشل إرسال الدفعة، جاري إرسال كل عقار على حدة...")
                for prop in batch:
                    if send_to_api(prop):
                        results["success"] += 1
                    else:
                        results["failed"] += 1

        except Exception as e:
            print(f"❌ خطأ في إرسال الدفعة: {e}")
            for prop in batch:
                if send_to_api(prop):
                    results["success"] += 1
                else:
                    results["failed"] += 1

        time.sleep(1)

    return results


def scrape_bayut_page(page_url):
    """دالة لجمع البيانات من صفحة واحدة"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    try:
        response = requests.get(page_url, headers=headers)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, "html.parser")
    except Exception as e:
        print(f"خطأ في تحميل الصفحة {page_url}: {e}")
        return []

    def text_or_none(selector, parent):
        el = parent.select_one(selector)
        return el.get_text(strip=True) if el else None

    def extract_area(text):
        if not text:
            return None
        s = text.replace(",", ".")
        m = re.search(
            r"(\d+(?:\.\d+)?)\s*(?:sqm|sq\s?m|m2|m²|م²|متر|\bm\b)",
            s,
            flags=re.I,
        )
        if m:
            return m.group(1)
        return None

    def extract_price(price_text):
        if not price_text:
            return None
        numbers = re.findall(r"[\d,]+", price_text)
        if numbers:
            return float(numbers[0].replace(",", ""))
        return None

    def extract_down_payment(d_text):
        if not d_text:
            return 0
        numbers = re.findall(r"[\d,]+", d_text)
        if numbers:
            return float(numbers[0].replace(",", ""))
        return 0

    property_cards = soup.select("ul._172b35d1 li")
    properties = []

    for card in property_cards:
        try:
            a = card.select_one("a._8969fafd")
            link = (
                f"https://www.bayut.eg{a.get('href')}" if a and a.get("href") else None
            )

            price_text = text_or_none(
                "h4.afdad5da._71366de7 span.eff033a6", card
            ) or text_or_none("span.eff033a6", card)
            price = extract_price(price_text)

            title = text_or_none("h2._34c51035", card)

            spans = card.select("span._3002c6fb")
            property_type = spans[0].get_text(strip=True) if len(spans) > 0 else None
            bedrooms_text = spans[1].get_text(strip=True) if len(spans) > 1 else None
            bathrooms_text = spans[2].get_text(strip=True) if len(spans) > 2 else None

            bedrooms = (
                int(re.findall(r"\d+", bedrooms_text)[0])
                if bedrooms_text and re.findall(r"\d+", bedrooms_text)
                else 2
            )
            bathrooms = (
                int(re.findall(r"\d+", bathrooms_text)[0])
                if bathrooms_text and re.findall(r"\d+", bathrooms_text)
                else 1
            )

            location = text_or_none("h3._51c6b1ca", card)
            d_text = text_or_none("span.fd7ade6e", card)
            down_payment = extract_down_payment(d_text)

            area_raw = text_or_none("h4._60820635._07b5f28e", card) or text_or_none(
                "h4", card
            )
            area_text = extract_area(area_raw)
            if not area_text:
                area_text = extract_area(title)
            if not area_text:
                area_text = extract_area(card.get_text(" ", strip=True))

            area = float(area_text) if area_text else None

            payment_method = "Installments" if down_payment > 0 else "Cash"
            scrape_date = datetime.now().isoformat()

            if price and area and location:
                properties.append(
                    {
                        "link": link,
                        "title": title or f"{property_type} in {location}",
                        "property_type": property_type or "Unknown",
                        "price": price,
                        "location": location,
                        "area": area,
                        "bedrooms": bedrooms,
                        "bathrooms": bathrooms,
                        "down_payment": down_payment,
                        "payment_method": payment_method,
                        "source": "bayut",
                        "scrape_date": scrape_date,
                        "state": None,
                        "description": None,
                        "features": None,
                    }
                )

        except Exception as e:
            print(f"خطأ في معالجة كارد: {e}")
            continue

    return properties


def scrape_all_pages(base_url, max_pages=20):
    """دالة لجمع البيانات من جميع الصفحات"""
    all_properties = []

    for page_num in range(1, max_pages + 1):
        if page_num == 1:
            page_url = base_url
        else:
            page_url = f"{base_url.rstrip('/')}/page-{page_num}/"

        print(f"جاري جمع البيانات من الصفحة {page_num}...")
        properties = scrape_bayut_page(page_url)

        if not properties:
            print(f"لم يتم العثور على عقارات في الصفحة {page_num}. التوقف...")
            break

        all_properties.extend(properties)
        print(
            f"✅ تم جمع {len(properties)} عقار من الصفحة {page_num} (الإجمالي: {len(all_properties)})"
        )

        time.sleep(2)

    return all_properties


def clean_data(df_clean):
    """تنظيف البيانات وتحضيرها للإرسال - نسخة مصححة"""
    # عمل نسخة لتجنب المشاكل
    df = df_clean.copy()

    # التأكد من وجود العمود
    if "location" not in df.columns:
        print("⚠️ عمود location غير موجود!")
        return df

    # تقسيم الموقع
    try:
        # تقسيم النص
        location_split = df["location"].str.split(",", expand=True)

        # إضافة الأعمدة الجديدة
        for i in range(location_split.shape[1]):
            df[f"Location_{i}"] = location_split[i]

        # حذف العمود الأصلي
        df = df.drop(columns=["location"])

        # إعادة تسمية الأعمدة
        if "Location_1" in df.columns:
            df = df.rename(columns={"Location_1": "state"})
        if "Location_0" in df.columns:
            df = df.rename(columns={"Location_0": "location"})

        # حذف الأعمدة الإضافية
        for col in ["Location_2", "Location_3", "Location_4"]:
            if col in df.columns:
                df = df.drop(columns=[col])

        # تنظيف النصوص - استخدم .astype(str) قبل .str
        if "state" in df.columns:
            df["state"] = (
                df["state"]
                .astype(str)
                .str.replace("Saba Pasha", "Saba Basha", case=False, regex=False)
            )
            df["state"] = (
                df["state"]
                .astype(str)
                .str.replace("Borg al-Arab", "Borg El Arab", case=False, regex=False)
            )
            df["state"] = (
                df["state"]
                .astype(str)
                .str.replace("Smoha", "Smouha", case=False, regex=False)
            )

        if "location" in df.columns:
            df["location"] = (
                df["location"]
                .astype(str)
                .str.replace("Smoha", "Smouha", case=False, regex=False)
            )

        # معالجة القيم المفقودة
        df["state"] = df["state"].fillna(df["location"])
        df["state"] = df["state"].astype(str).str.strip()

        # معالجة Alexandria
        mask = df["state"].astype(str).str.contains("Alexandria", case=False, na=False)
        df.loc[mask, "state"] = df.loc[mask, "location"]

        df["location"] = df["location"].astype(str).str.strip()

    except Exception as e:
        print(f"⚠️ خطأ في تنظيف البيانات: {e}")
        return df

    print(f"✅ تم تنظيف {len(df)} عقار")
    return df


def send_properties_to_api(properties_list):
    """إرسال قائمة العقارات إلى API"""
    if not properties_list:
        print("⚠️ لا توجد عقارات لإرسالها")
        return {"success": 0, "failed": 0}

    print(f"\n📤 بدء إرسال {len(properties_list)} عقار إلى API...")
    print(f"📍 API Endpoint: {API_PROPERTIES_ENDPOINT}")

    results = send_batch_to_api(properties_list, batch_size=10)

    return results


def main():
    """الدالة الرئيسية"""
    print("🚀 بدء جمع بيانات العقارات من Bayut")
    print("=" * 60)
    print(f"📅 التاريخ: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📍 API Endpoint: {API_BASE_URL}")
    print("=" * 60)

    # إعدادات
    base_url = "https://www.bayut.eg/en/alexandria/properties-for-sale/"
    max_pages = 40

    # جمع البيانات
    print(f"\n📥 جاري جمع البيانات من Bayut (حتى {max_pages} صفحات)...")
    all_properties = scrape_all_pages(base_url, max_pages=max_pages)

    if not all_properties:
        print("❌ لم يتم جمع أي عقارات!")
        return False

    print(f"\n📊 تم جمع {len(all_properties)} عقار")

    # تحويل إلى DataFrame للتنظيف
    df = pd.DataFrame(all_properties)

    # تنظيف البيانات
    print("\n🔄 بدء تنظيف البيانات...")
    df_clean = clean_data(df.copy())

    # تحويل DataFrame إلى قائمة Dictionaries
    cleaned_properties = df_clean.to_dict("records")

    print(f"✅ تم تنظيف {len(cleaned_properties)} عقار")

    # عرض عينة من البيانات
    print("\n🔍 عينة من البيانات بعد التنظيف:")
    sample = cleaned_properties[:3]
    for i, prop in enumerate(sample, 1):
        print(f"\n{i}. {prop.get('title', 'N/A')[:50]}...")
        print(
            f"   📍 الموقع: {prop.get('location', 'N/A')} - {prop.get('state', 'N/A')}"
        )
        print(f"   💰 السعر: {prop.get('price', 0):,.0f} EGP")
        print(f"   📐 المساحة: {prop.get('area', 0)} m²")
        print(f"   💳 طريقة الدفع: {prop.get('payment_method', 'N/A')}")

    # إرسال إلى API
    print("\n" + "=" * 60)
    results = send_properties_to_api(cleaned_properties)

    # عرض النتائج
    print("\n" + "=" * 60)
    print("📋 ملخص العملية:")
    print("=" * 60)
    print(f"✅ العقارات المجمعة: {len(all_properties)}")
    print(f"✅ العقارات بعد التنظيف: {len(cleaned_properties)}")
    print(f"✅ تم إرسال بنجاح: {results['success']}")
    print(f"❌ فشل الإرسال: {results['failed']}")
    print("=" * 60)

    if results["success"] > 0:
        print("✅ اكتملت عملية الجمع والإرسال بنجاح!")
    else:
        print("⚠️ لم يتم إرسال أي عقار. يرجى التحقق من اتصال API")

    return results["success"] > 0


if __name__ == "__main__":
    try:
        success = main()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⏹️ تم إيقاف العملية بواسطة المستخدم")
        exit(130)
    except Exception as e:
        print(f"\n❌ خطأ غير متوقع: {e}")
        import traceback

        traceback.print_exc()
        exit(1)