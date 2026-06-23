#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Minimal probe: attempt ONE subscriptionPrices POST (USA base) on an existing
single-app yearly subscription and print the raw status + body. Tells us whether
ASC's subscription-pricing 409 has recovered without mutating anything else.

Usage: python3 tool/probe_sub_price.py [soccer]
"""
import jwt, time, requests, warnings, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
sport = (sys.argv[1] if len(sys.argv) > 1 else "soccer")
pid = f"{sport.lower()}_remove_ads_yearly"
USD = "2.99"


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def G(path):
    return requests.get(B + path, headers={"Authorization": f"Bearer {tok()}"}, verify=False, timeout=60)


# find app
aid = G(f"/v1/apps?filter[bundleId]=com.zach.{sport}Board").json()["data"][0]["id"]
# find subscription by productId across groups
sid = None
for g in G(f"/v1/apps/{aid}/subscriptionGroups?limit=20").json().get("data", []):
    su = G(f"/v1/subscriptionGroups/{g['id']}/subscriptions?filter[productId]={pid}&limit=1").json().get("data")
    if su:
        sid = su[0]["id"]; state = su[0]["attributes"]["state"]; break
if not sid:
    sys.exit(f"no yearly subscription found for {pid}")
print(f"{sport}: subscription {sid} state={state}")

# already priced?
if G(f"/v1/subscriptions/{sid}/prices?limit=1").json().get("data"):
    print("  already has a price set — nothing to probe"); sys.exit(0)

# find USA price point matching USD
base = next((p["id"] for p in G(f"/v1/subscriptions/{sid}/pricePoints?filter[territory]=USA&limit=200").json().get("data", [])
             if p["attributes"].get("customerPrice") == USD), None)
if not base:
    sys.exit("  no USA price point for $%s" % USD)
print(f"  USA price point {base} (${USD}); POSTing subscriptionPrices ...")

r = requests.post(B + "/v1/subscriptionPrices",
    headers={"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"},
    json={"data": {"type": "subscriptionPrices", "attributes": {"preserveCurrentPrice": False},
        "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}},
        "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": base}},
        "territory": {"data": {"type": "territories", "id": "USA"}}}}},
    verify=False, timeout=60)
print(f"  -> HTTP {r.status_code}")
print("  ", r.text[:600])
