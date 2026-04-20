#!/usr/bin/env python3
"""Submit tennisBoard + tableTennisBoard only (Apple finished processing their builds now)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import submit_all  # reuses helpers

ONLY = [
    ("com.zach.tennisBoard", "Tennis Board"),
    ("com.zach.tableTennisBoard", "Table Tennis Board"),
]

for bundle_id, name in ONLY:
    print(f"\n{name}...")
    r = submit_all.api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]
    app_key = submit_all.APP_KEY[bundle_id]

    r_ver = submit_all.api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not r_ver["data"]:
        r_new = submit_all.api("POST", "/v1/appStoreVersions", {
            "data": {"type": "appStoreVersions",
                     "attributes": {"platform": "IOS", "versionString": "1.1.3"},
                     "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
        })
        if r_new.get("_error"):
            errs = r_new["_body"].get("errors", [])
            print(f"  ❌ create version: {errs[0].get('detail','?') if errs else '?'}")
            continue
        version_id = r_new["data"]["id"]
        r_builds = submit_all.api("GET", f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]=1.1.3&sort=-uploadedDate&limit=1")
        if not r_builds.get("data"):
            print(f"  ❌ no 1.1.3 build found yet")
            continue
        build_id = r_builds["data"][0]["id"]
        submit_all.api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build", {
            "data": {"type": "builds", "id": build_id}
        })
        import time; time.sleep(2)
    else:
        version_id = r_ver["data"][0]["id"]

    submit_all.prepare_version(version_id, app_key)
    import time; time.sleep(1)

    r_subs = submit_all.api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
    for sub in r_subs.get("data", []):
        if sub["attributes"]["state"] == "READY_FOR_REVIEW":
            submit_all.api("DELETE", f"/v1/reviewSubmissions/{sub['id']}")

    time.sleep(2)

    r1 = submit_all.api("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
    })
    if r1.get("_error"):
        errs = r1["_body"].get("errors", [])
        meta = errs[0].get("meta", {}).get("associatedErrors", {}) if errs else {}
        reasons = []
        for p, ae_list in meta.items():
            for ae in ae_list:
                reasons.append(ae.get('detail','?'))
        if reasons:
            print(f"  ❌ {'; '.join(set(reasons))}")
        else:
            print(f"  ❌ {errs[0].get('detail','?') if errs else '?'}")
        continue

    sub_id = r1["data"]["id"]

    r2 = submit_all.api("POST", "/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
        }}
    })
    if r2.get("_error"):
        errs2 = r2["_body"].get("errors", [])
        print(f"  ❌ item: {errs2[0].get('detail','?') if errs2 else '?'}")
        continue

    r3 = submit_all.api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}
    })
    if r3.get("_error"):
        print(f"  ❌ {r3['_body'].get('errors',[{}])[0].get('detail','?')}")
    else:
        print(f"  ✅ {r3['data']['attributes']['state']}")
