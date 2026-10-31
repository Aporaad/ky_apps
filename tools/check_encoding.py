"""فحص ترميز ملفات المشروع — بوابة قبل الدفع (Pre-flight gate).

لماذا هذا السكربت؟ لأن أدوات Flutter تقرأ بعض الملفات بترميز UTF-8 **إلزامياً**، وأي ملف
بترميز قديم (Windows-1256 على ويندوز العربي مثلاً) يُسقط البناء برسالة مضلّلة لا تشير إلى
الترميز. حدث فعلاً: `flutter build ios` على Codemagic انهار بـ

    FileSystemException: Failed to decode data using encoding 'utf-8',
        path = '/Users/builder/clone/.gitignore'
        at SwiftPackageManagerGitignoreMigration.migrate

فأُضيف هذا الفحص ليكشف السبب محلياً في ثانية واحدة بدل جولة بناء كاملة.

الاستعمال:
    python tools/check_encoding.py           # فحص فقط
    python tools/check_encoding.py --fix     # يحوّل ما أمكن إلى UTF-8

مخرجات الإرجاع: 0 عند نجاح كل الملفات، 1 إذا بقي ملف غير UTF-8.

Why this script: Flutter tools read some files as strict UTF-8, and a legacy-encoded file
(Windows-1256) crashes `flutter build ios` with a message that never mentions encoding.
This gate surfaces the real cause locally instead of after a full cloud build.
Exit code: 0 when every checked file is UTF-8, 1 otherwise.
"""

import os
import subprocess
import sys

# الملفات التي تقرأها أدوات Flutter/البناء إلزاماً بترميز UTF-8 — أخطرها أوّلاً.
# Files that Flutter/the toolchain require to be UTF-8 — most critical first.
CRITICAL = [".gitignore", "ios/.gitignore", "android/.gitignore", "pubspec.yaml"]

# ملفات نصية إضافية تُفحص للاستزادة (توثيق وسكربتات) — تحذير لا إيقاف.
# Extra text files checked as a warning only (docs and scripts).
ADVISORY_EXTENSIONS = {
    ".md", ".yaml", ".yml", ".dart", ".plist", ".json", ".py", ".php",
    ".kts", ".gradle", ".xml", ".entitlements", ".xcconfig",
}

# ترميزات قديمة تُجرَّب بالترتيب عند فشل UTF-8.
LEGACY_ENCODINGS = ["cp1256", "cp1252", "latin-1"]


def tracked_text_files():
    """الملفات النصية المتتبعة في git، مع استثناء المستودع الفرعي."""
    result = subprocess.run(
        ["git", "ls-files"], capture_output=True, text=True, encoding="utf-8"
    )
    for line in result.stdout.splitlines():
        path = line.strip()
        if not path or path.startswith("kyApp_API/"):
            continue
        extension = os.path.splitext(path)[1].lower()
        if extension in ADVISORY_EXTENSIONS or os.path.basename(path).endswith(".gitignore"):
            yield path


def read_bytes(path):
    with open(path, "rb") as handle:
        return handle.read()


def detect_legacy_encoding(raw):
    for encoding in LEGACY_ENCODINGS:
        try:
            return encoding, raw.decode(encoding)
        except UnicodeDecodeError:
            continue
    return None, None


def main():
    fix = "--fix" in sys.argv

    critical_broken = []
    advisory_broken = []
    fixed = []

    critical_paths = [p for p in CRITICAL if os.path.exists(p)]
    advisory_paths = [
        p for p in tracked_text_files()
        if p not in critical_paths and os.path.exists(p)
    ]

    for paths, target_list in ((critical_paths, critical_broken), (advisory_paths, advisory_broken)):
        for path in paths:
            raw = read_bytes(path)
            try:
                raw.decode("utf-8")
                continue
            except UnicodeDecodeError:
                pass

            encoding, decoded = detect_legacy_encoding(raw)
            target_list.append((path, encoding or "undecodable"))

            if fix and decoded is not None:
                normalized = decoded.replace("\r\n", "\n").replace("\r", "\n")
                with open(path, "w", encoding="utf-8", newline="\n") as handle:
                    handle.write(normalized)
                fixed.append(path)

    print("== UTF-8 preflight ==")
    print("critical files checked: %d" % len(critical_paths))
    print("text files checked:     %d" % len(advisory_paths))

    for label, entries in (("CRITICAL", critical_broken), ("advisory", advisory_broken)):
        if entries:
            print("\n%s not in UTF-8: %d" % (label, len(entries)))
            for path, encoding in entries:
                print("  %-42s was %s" % (path, encoding))

    if fixed:
        print("\nconverted to UTF-8: %d" % len(fixed))
        for path in fixed:
            print("  " + path)

    if not critical_broken:
        print("\nRESULT: OK — every build-critical file is UTF-8")
        return 0

    if fix:
        print("\nRESULT: converted — re-run without --fix to confirm")
        return 0

    print("\nRESULT: FAILED — run with --fix (flutter build ios will crash on this file)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
