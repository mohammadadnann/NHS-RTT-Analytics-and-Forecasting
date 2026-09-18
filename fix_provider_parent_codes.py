"""
One off fix, refreshing dim_providers.provider_parent_code to the latest
known value.

The ETL only inserts a provider once, the first time it is seen, and never
updates it again. Since NHS England merged several ICBs in April 2026, a
provider loaded from an earlier month can be left holding a pre merger
parent code forever, even after later months report the new one. This
reads April, the most recent file, and updates every provider's parent
code and name to match it, so the region join lines up with the region
lookup, which is itself built on the post merger ICB structure.
"""

from src.etl import extract, transform
from src.etl.load import get_engine
from sqlalchemy import text

engine = get_engine()

april_blob = "20260430-RTT-April-2026-full-extract.csv"
print(f"Reading {april_blob} for the latest provider parent codes...")
raw_df = extract.read_csv_file(april_blob)
clean_df = transform.remove_total_rows(raw_df)
providers = transform.get_unique_providers(clean_df)
print(f"  {len(providers)} providers found in April")

print("Updating dim_providers with April's parent codes...")
updated = 0
with engine.begin() as conn:
    for _, row in providers.iterrows():
        result = conn.execute(
            text("""
                UPDATE dim_providers
                SET provider_parent_code = :parent_code,
                    provider_parent_name = :parent_name
                WHERE provider_code = :provider_code
            """),
            {
                "parent_code": row["provider_parent_code"],
                "parent_name": row["provider_parent_name"],
                "provider_code": row["provider_code"],
            }
        )
        updated += result.rowcount

print(f"Updated {updated} provider rows")

with engine.connect() as conn:
    match_check = conn.execute(text("""
        SELECT
            COUNT(DISTINCT p.provider_code) AS total_providers,
            COUNT(DISTINCT CASE WHEN m.icb_code IS NOT NULL THEN p.provider_code END) AS matched_providers
        FROM dim_providers p
        LEFT JOIN dim_icb_region_map m ON p.provider_parent_code = m.icb_code
    """)).fetchone()
    print(f"After the fix: {match_check[1]:,} of {match_check[0]:,} providers matched to a region")