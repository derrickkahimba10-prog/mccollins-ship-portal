# Carousel, Language & Subscription Visibility — Focused Tests

## PHP lint

```cmd
cd /d C:\xampp\htdocs\mccollins-ship-portal
del php-lint-results.txt 2>nul
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" >> php-lint-results.txt 2>&1
findstr /I /C:"Parse error" /C:"Fatal error" /C:"Errors parsing" php-lint-results.txt
```

No output from the last command means lint passed.

## Focused tests

1. Log in on desktop and mobile; confirm **Kiswahili/English** is in the authenticated top-right corner and survives refresh.
2. Log in as Operations and Finance; open **Subscription plans** and confirm Gold, Premium and Platinum plus Carrier plan records are read-only.
3. Operations only: confirm **Review pending transfers** still opens the protected manual verification queue.
4. Confirm the portal does not request or store card number, expiry or CVC.
5. Open Audit Events; confirm **Search** is positioned beneath the search field.
6. Open About Platform; verify the carousel slowly advances about every 6.5 seconds.
7. Test previous/next arrows, dots, keyboard arrows, mouse drag and mobile swipe.
8. Hover or focus inside the carousel; confirm autoplay pauses and later resumes.
9. Enable reduced-motion in the browser/operating system; confirm autoplay is disabled.
10. Verify Available and Roadmap labels accurately separate implemented and future capabilities.
11. Recheck Fleet Eligibility and other wide tables for readable horizontal scrolling.
