<div align="center">

# 🚀 DNS Changer

**Interactive, multi-distro DNS changer for Linux**

[![Version](https://img.shields.io/badge/version-3.5.0-blue?style=for-the-badge)](https://github.com/acor1/dns_changer_acor1)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-orange?style=for-the-badge&logo=linux)](https://github.com/acor1/dns_changer_acor1)
[![Shell](https://img.shields.io/badge/shell-bash-yellow?style=for-the-badge&logo=gnu-bash)](https://github.com/acor1/dns_changer_acor1)

تغییر سریع و امن DNS روی سرورهای Linux — با یک منوی رنگی و ساده

[🚀 نصب سریع](#-نصب-سریع) • [✨ قابلیت‌ها](#-قابلیتها) • [📸 اسکرین‌شات](#-اسکرینشات) • [💻 سازگاری](#-سازگاری) • [🖥 CLI](#-دستورات-cli)

</div>

---

## 🎯 معرفی

**DNS Changer** یک اسکریپت Bash تعاملی برای تغییر سریع و امن DNS روی سرورهای Linux است. با یک منوی رنگی و ساده، می‌تونی در چند ثانیه DNS سرورت رو عوض کنی، سرعتش رو اندازه‌گیری کنی، و حتی رمزنگاری‌ش کنی.

طراحی شده برای:

- 🔒 کاربرانی که می‌خوان DNS خودشون رو **رمزنگاری** کنن (DoT)
- ⚡ کسانی که می‌خوان **سریع‌ترین DNS** خودکار پیدا بشه
- 🇮🇷 کاربران ایرانی که از **Shecan** و **403** استفاده می‌کنن
- 🛠 مدیران سروری که روی **Ubuntu, Debian, CentOS, Alpine, Arch** کار می‌کنن

---

## ✨ قابلیت‌ها

<table>
<tr>
<td width="50%">

### 🔒 رمزنگاری DNS (DoT)
ارسال درخواست‌های DNS به‌صورت رمزنگاری‌شده — ISP نمی‌تونه ببینه چه سایت‌هایی باز می‌کنی.

پشتیبانی از:
- Cloudflare
- Google
- Quad9
- AdGuard

### ⚡ بنچمارک هوشمند
سرعت **واقعی resolve** هر DNS روی ۵ دامنه مختلف اندازه‌گیری می‌شه. سریع‌ترین گزینه خودکار اعمال می‌شه.

### 🎯 Split DNS
برای یک دامنه خاص از DNS متفاوت استفاده کن. تنظیمات **دائمی** — بعد از ری‌استارت پاک نمی‌شه.

</td>
<td width="50%">

### 🔍 تست نشت DNS
چک کن که DNS سیستم واقعاً عوض شده یا نه.

### 📊 آمار Cache
نمایش real-time از systemd-resolved — hits، misses، و اندازه cache.

### 🕒 تاریخچه تغییرات
هر بار DNS عوض می‌کنی، ذخیره می‌شه. می‌تونی ببینی قبلاً چی اعمال کردی.

### ♻️ بکاپ خودکار
قبل از هر تغییر، بکاپ گرفته می‌شه. با یک کلیک همه چیز برمی‌گرده.

### 🌍 Multi-distro
خودکار تشخیص می‌ده — از `apt`, `dnf`, `yum`, `apk`, `pacman`.

</td>
</tr>
</table>

---

## 📸 اسکرین‌شات
