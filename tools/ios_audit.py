"""تدقيق آلي لإعدادات iOS — بوابة قبل الدفع (Pre-flight audit).

يفحص ما لا يظهر خطؤه إلا على جهاز حقيقي أو بعد جولة بناء كاملة: ATS، أذونات المعرض والشبكة
المحلية، معرّف الحزمة، إصدار النظام الأدنى، ربط صلاحية Keychain، الأيقونات، ملف البناء السحابي،
واكتمال الدليل المرجعي.

الاستعمال (من جذر المشروع):
    python tools/ios_audit.py

مخرجات الإرجاع: 0 عند نجاح كل الفحوص، 1 عند وجود إخفاق.

Automated audit of the iOS configuration — the settings whose mistakes only surface on a
real device or after a full cloud build. Exit code: 0 when all checks pass, 1 otherwise.
"""

import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile

import yaml
from PIL import Image

results = []


def check(condition, label):
    """يسجّل نتيجة فحص ويطبعها. Records and prints one check result."""
    results.append(bool(condition))
    print(("[OK]   " if condition else "[FAIL] ") + label)


def main():
    # ── Info.plist ───────────────────────────────────────────
    info = plistlib.load(open("ios/Runner/Info.plist", "rb"))
    transport = info.get("NSAppTransportSecurity", {})
    check(transport.get("NSAllowsArbitraryLoads") and transport.get("NSAllowsLocalNetworking"),
          "Info.plist: ATS allows http + local networking")
    check(all(info.get(key) for key in [
        "NSPhotoLibraryUsageDescription",
        "NSLocalNetworkUsageDescription",
        "NSFaceIDUsageDescription",
    ]), "Info.plist: photos / local network / FaceID descriptions")
    check(info.get("CFBundleDisplayName") == "الكبودي", "Info.plist: display name الكبودي")
    check(info.get("CFBundleDevelopmentRegion") == "ar"
          and info.get("CFBundleLocalizations") == ["ar"]
          and info.get("CFBundleAllowMixedLocalizations") is True,
          "Info.plist: Arabic localization + share_plus key")

    # ── project.pbxproj ──────────────────────────────────────
    with open("ios/Runner.xcodeproj/project.pbxproj", "rb") as handle:
        raw = handle.read()
    project = raw.decode("utf-8")
    check(project.count("com.example") == 0 and project.count("com.alkaboudy.app") == 6,
          "pbxproj: bundle id com.alkaboudy.app x6, no com.example")
    check(project.count("IPHONEOS_DEPLOYMENT_TARGET = 13.0;") == 3
          and project.count("IPHONEOS_DEPLOYMENT_TARGET = 12.0;") == 0,
          "pbxproj: deployment target 13.0 x3")
    check(project.count("CODE_SIGN_ENTITLEMENTS") == 3, "pbxproj: CODE_SIGN_ENTITLEMENTS x3")
    check(project.count("{") == project.count("}") and project.count("(") == project.count(")"),
          "pbxproj: braces and parentheses balanced")
    check(raw.count(b"\r\n") == raw.count(b"\n"), "pbxproj: line endings consistent")

    # ── صلاحية سلسلة المفاتيح ─────────────────────────────────
    for path in ["ios/Runner/DebugProfile.entitlements", "ios/Runner/Release.entitlements"]:
        text = open(path, encoding="utf-8").read()
        data = plistlib.load(open(path, "rb"))
        groups = data.get("keychain-access-groups") or []
        check(len(groups) == 1
              and groups[0].endswith("com.alkaboudy.app")
              and "AppIdentifierPrefix" in text,
              os.path.basename(path) + ": keychain-access-groups")

    # ── بقية الملفات ─────────────────────────────────────────
    framework = plistlib.load(open("ios/Flutter/AppFrameworkInfo.plist", "rb"))
    check(framework["MinimumOSVersion"] == "13.0", "AppFrameworkInfo.plist: MinimumOSVersion 13.0")

    podfile = open("ios/Podfile", encoding="utf-8").read()
    check("platform :ios, '13.0'" in podfile and "post_install" in podfile,
          "Podfile: platform 13.0 + post_install")

    icon_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.load(open(os.path.join(icon_dir, "Contents.json"), encoding="utf-8"))
    icons_ok = all(
        os.path.exists(os.path.join(icon_dir, entry["filename"]))
        and Image.open(os.path.join(icon_dir, entry["filename"])).mode == "RGB"
        for entry in contents["images"]
    )
    check(icons_ok, "AppIcon: %d entries exist and are RGB" % len(contents["images"]))

    workflow = yaml.safe_load(open("codemagic.yaml", encoding="utf-8"))["workflows"]["ios-unsigned"]
    step_names = [step["name"] for step in workflow["scripts"]]
    check(len(step_names) == 8
          and workflow["environment"]["flutter"] == "3.29.3"
          and any("Encoding gate" in name for name in step_names)
          and any("Verify unsigned IPA" in name for name in step_names),
          "codemagic.yaml: %d steps incl. encoding gate + IPA verification" % len(step_names))

    guide = open("ios_release_guide.md", encoding="utf-8").read()
    check("keychain-access-groups" in guide and "sharePositionOrigin" in guide,
          "ios_release_guide.md: complete (%d chars)" % len(guide))

    # ── صحة أوامر الخطوات بـ`bash -n` (تحقق صرف، بلا تنفيذ) ──────────
    # يكشف خطأً نحوياً في خطوة CI كان سيستهلك جولة بناء كاملة لاكتشافه.
    # Catches a syntax error in a CI step that would otherwise cost a full build round.
    bash = shutil.which("bash")
    if not bash:
        # Git لم ويندوز يضع bash خارج PATH عادةً — نجرّب مساره المعتاد.
        # Git for Windows usually keeps bash off PATH; try the default install path.
        for candidate in (r"C:\Program Files\Git\bin\bash.exe",
                          r"C:\Program Files (x86)\Git\bin\bash.exe"):
            if os.path.exists(candidate):
                bash = candidate
                break
    if bash:
        broken = []
        for step in workflow["scripts"]:
            body = step["script"]
            if "\n" not in str(body):
                continue
            with tempfile.NamedTemporaryFile(
                "w", suffix=".sh", delete=False, encoding="utf-8", newline="\n"
            ) as handle:
                handle.write(body + "\n")
                temp_path = handle.name
            result = subprocess.run([bash, "-n", temp_path], capture_output=True, text=True)
            os.unlink(temp_path)
            if result.returncode != 0:
                first_line = (result.stderr or "").strip().splitlines()
                broken.append("%s (%s)" % (step["name"], first_line[0] if first_line else "syntax error"))
        check(not broken, "workflow scripts: bash -n clean%s" % ("" if not broken else " -> " + "; ".join(broken)))
    else:
        print("[SKIP] bash not available — CI script syntax not checked")

    passed = all(results)
    print("\n" + ("ALL %d CHECKS PASSED" % len(results) if passed else "FAILURES PRESENT"))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
