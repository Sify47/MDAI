"""
upload_csv_to_api.py
قراءة ملف Final1.csv وإرسال البيانات إلى API الدفعة (batch)
"""

import pandas as pd
import requests
import json
from datetime import datetime

# ========== Configuration ==========
API_BASE_URL = "http://65.75.201.173:8000"
API_BATCH_ENDPOINT = f"{API_BASE_URL}/real-estate/properties/batch"
API_HEADERS = {"Content-Type": "application/json", "Accept": "application/json"}
CSV_PATH = ".github/Final1.csv"
BATCH_SIZE = 50  # عدد العقارات في كل دفعة


def load_csv_data(csv_path: str) -> pd.DataFrame:
    """تحميل البيانات من ملف CSV"""
    print(f"📂 Loading CSV from: {csv_path}")
    df = pd.read_csv(csv_path)
    print(f"✅ Loaded {len(df):,} properties from CSV")
    print(f"📋 Columns: {', '.join(df.columns.tolist())}")
    return df


def convert_row_to_dict(row) -> dict:
    """تحويل صف DataFrame إلى قاموس متوافق مع API"""
    # Map CSV column names to API field names
    property_dict = {
        "title": str(row.get("Title", "")),
        "link": str(row.get("Link", "")),
        "property_type": str(row.get("PropertyType", "")),
        "price": float(row["Price"]) if pd.notna(row.get("Price")) else 0,
        "location": str(row.get("Location", "")),
        "state": str(row.get("State", "")),
        "bedrooms": int(row["Bedrooms"]) if pd.notna(row.get("Bedrooms")) else 2,
        "bathrooms": int(row["Bathrooms"]) if pd.notna(row.get("Bathrooms")) else 1,
        "area": float(row["Area"]) if pd.notna(row.get("Area")) else 0,
        "down_payment": float(row["Down_Payment"]) if pd.notna(row.get("Down_Payment")) else 0,
        "payment_method": str(row.get("Payment_Method", "Cash")),
        "price_per_m": float(row["Price_Per_M"]) if pd.notna(row.get("Price_Per_M")) else 0,
        "scrape_date": str(row.get("scrape_date", datetime.now().strftime("%Y-%m-%d"))),
        "source": "csv_upload",
    }
    return property_dict


def send_batch_to_api(properties: list, batch_size: int = BATCH_SIZE):
    """إرسال العقارات إلى API على دفعات"""
    total = len(properties)
    total_added = 0
    total_failed = 0
    total_skipped = 0

    print(f"\n{'='*60}")
    print(f"📤 Sending {total:,} properties to API in batches of {batch_size}")
    print(f"{'='*60}")

    for i in range(0, total, batch_size):
        batch = properties[i : i + batch_size]
        batch_num = i // batch_size + 1
        total_batches = (total + batch_size - 1) // batch_size

        print(f"\n--- Batch {batch_num}/{total_batches} ({len(batch)} properties) ---")

        try:
            response = requests.post(
                API_BATCH_ENDPOINT,
                json={"properties": batch},
                headers=API_HEADERS,
                timeout=60,
            )

            if response.status_code == 200:
                result = response.json()
                added = result.get("added", 0)
                failed = result.get("failed", 0)
                total_added += added
                total_failed += failed
                print(f"✅ Batch {batch_num}: Added {added}, Failed {failed}")

                if result.get("errors"):
                    for err in result["errors"][:3]:
                        print(f"   ⚠️ Error: {err.get('error', 'Unknown')[:100]}")
            else:
                print(f"❌ Batch {batch_num}: HTTP {response.status_code} - {response.text[:200]}")
                total_failed += len(batch)

        except requests.exceptions.ConnectionError:
            print(f"❌ Batch {batch_num}: Cannot connect to API at {API_BASE_URL}")
            print("   Make sure the backend server is running!")
            total_skipped += len(batch)

        except Exception as e:
            print(f"❌ Batch {batch_num}: Error - {str(e)[:200]}")
            total_failed += len(batch)

    return total_added, total_failed, total_skipped


def main():
    print("🏠 Real Estate CSV Uploader")
    print(f"🕐 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}")

    # 1. Load CSV
    df = load_csv_data(CSV_PATH)

    # 2. Convert to list of dicts
    print("\n🔄 Converting data format...")
    properties = []
    skipped = 0
    for idx, row in df.iterrows():
        try:
            prop_dict = convert_row_to_dict(row)
            # Skip entries without price or location
            if prop_dict["price"] <= 0 or not prop_dict["location"]:
                skipped += 1
                continue
            properties.append(prop_dict)
        except Exception as e:
            skipped += 1
            if skipped <= 5:
                print(f"   ⚠️ Row {idx}: {str(e)[:80]}")

    print(f"✅ Converted {len(properties):,} properties (skipped {skipped} invalid rows)")

    # 3. Send to API
    added, failed, skipped_api = send_batch_to_api(properties)

    # 4. Summary
    print(f"\n{'='*60}")
    print("📊 FINAL SUMMARY")
    print(f"{'='*60}")
    print(f"📂 Source: {CSV_PATH}")
    print(f"📦 Total in CSV: {len(df):,}")
    print(f"✅ Sent successfully: {added:,}")
    print(f"❌ Failed: {failed:,}")
    print(f"⏭️  Skipped: {skipped + skipped_api:,}")
    print(f"{'='*60}")

    if added > 0:
        print("\n🎉 Data uploaded successfully! Refresh the dashboard to see new properties.")
    else:
        print("\n⚠️ No properties were uploaded. Check the errors above.")


if __name__ == "__main__":
    main()
