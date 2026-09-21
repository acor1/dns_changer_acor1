<div align="center">

# 🚀 DNS Changer

**Interactive, multi-distro DNS changer for Linux**

[![Version](https://img.shields.io/badge/version-3.5.0-blue?style=for-the-badge)](https://github.com/acor1/dns_changer_acor1)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-orange?style=for-the-badge&logo=linux)](https://github.com/acor1/dns_changer_acor1)

تغییر سریع و امن DNS روی سرورهای Linux — با یک منوی رنگی و ساده

[🚀 نصب سریع](#-نصب-سریع) • [✨ قابلیت‌ها](#-قابلیتها) • [📸 اسکرین‌شات](#-اسکرینشات) • [💻 سازگاری](#-سازگاری) • [🖥 CLI](#-دستورات-cli)

</div>

---

## 🎯 معرفی

**DNS Changer** یک اسکریپت Bash تعاملی برای تغییر سریع و امن DNS روی سرورهای Linux است. با یک منوی رنگی و ساده، می‌ 🎯تونی در چند ثانیه DNS Split سرورت رو DNS عوض کنی، سرعتش رو اندازه‌گیری کنی، و حتی رمزنگاری‌ش کنی.

طراحی شده برای:

- 🔒 کاربرانی که می‌خوان DNS خودشون رو **رمزنگاری** کنن (DoT)
- ⚡ کسانی که می‌خوان **سریع‌ترین DNS** خودکار پیدا بشه
- 🇮🇷 کاربران ایرانی که از **Shecan** و **403** استفاده می‌کنن
- 🛠 مدیران سروری که روی **Ubuntu, Debian, CentOS, Alpine, Arch** کار می‌کنن

---

## ✨ قابلیت‌ها

### 🔒 رمزنگاری DNS (DoT)

ارسال درخواست‌های DNS به‌صورت رمزنگاری‌شده — ISP نمی‌تونه ببینه چه سایت‌هایی باز می‌کنی.

پشتیبانی از:
- Cloudflare
- Google
- Quad9
- AdGuard

---

### ⚡ بنچمارک هوشمند

سرعت **واقعی resolve** هر DNS روی ۵ دامنه مختلف اندازه‌گیری می‌شه. سریع‌ترین گزینه خودکار اعمال می‌شه.

---

###

برای یک دامنه خاص از DNS متفاوت استفاده کن. تنظیمات **دائمی** — بعد از ری‌استارت پاک نمی‌شه.

---

### 🔍 تست نشت DNS

چک کن که DNS سیستم واقعاً عوض شده یا نه.

---

### 📊 آمار Cache

نمایش real-time از systemd-resolved — hits، misses، و اندازه cache.

---

### 🕒 تاریخچه تغییرات

هر بار DNS عوض می‌کنی، ذخیره می‌شه. می‌تونی ببینی قبلاً چی اعمال کردی.

---

### ♻️ بکاپ خودکار

قبل از هر تغییر، بکاپ گرفته می‌شه. با یک کلیک همه چیز برمی‌گرده.

---

### 🌍 Multi-distro

خودکار تشخیص می‌ده — از `apt`, `dnf`, `yum`, `apk`, `pacman`.

---

## 📸 اسکرین‌شات

```
   ██████╗ ███╗   ██╗███████╗
   ██╔══██╗████╗  ██║██╔════╝
   ██║  ██║██╔██╗ ██║███████╗
   ██║  ██║██║╚██╗██║╚════██║
   ██████╔╝██║ ╚████║███████║
   ╚═════╝ ╚═╝  ╚═══╝╚══════╝
      🚀  DNS Changer v3.5.0 by acor1  ☄️
      ────────────────────────────────────

  ══════════════════════════════════════════
                 🧭  DNS OPTIONS
  ══════════════════════════════════════════

    [1]   Quick Apply — Google DNS
    [2]   Quick Apply — Cloudflare DNS
    [3]   Quick Apply — Quad9 DNS
    [4]   Quick Apply — Shecan DNS   (IR)
    [5]   Quick Apply — 403 DNS      (IR)
    [6]   Custom DNS
    [7]   ⚡ Smart Benchmark (real resolve)
    [8]   🔒 Encrypted DNS (DoT)
    [9]   🎯 Split DNS (domain-specific)
    [10]  🔍 DNS Leak Test
    [11]  📊 Cache Statistics
    [12]  🕒 Change History
    [13]  🔎 Show Current DNS
    [14]  ♻️  Restore Backup
    [0]   Exit

  ══════════════════════════════════════════

  ➤ Select an option:
```

---

## 🚀 نصب سریع

### روش ۱ — یک خطی (توصیه‌شده)

```bash
curl -L -o dns.sh https://raw.githubusercontent.com/acor1/dns_changer_acor1/main/dns.sh && chmod +x dns.sh && sudo ./dns.sh
```

### روش ۲ — نصب در مسیر سیستم

```bash
curl -L -o dns.sh https://raw.githubusercontent.com/acor1/dns_changer_acor1/main/dns.sh
chmod +x dns.sh
sudo mv dns.sh /usr/local/bin/dns-changer
```

از این به بعد از هر جایی:

```bash
sudo dns-changer
```

### روش ۳ — کلون و اجرا

```bash
git clone https://github.com/acor1/dns_changer_acor1.git
cd dns_changer_acor1
chmod +x dns.sh
sudo ./dns.sh
```

---

## 🎮 نحوه استفاده

بعد از اجرا، منوی رنگی می‌بینی. با وارد کردن شماره گزینه، عملیات انجام می‌شه.

### مثال ۱ — تغییر سریع به Cloudflare

```
➤ Select an option: 2
```

### مثال ۲ — پیدا کردن سریع‌ترین DNS

```
➤ Select an option: 7
```

همه DNSها بنچمارک می‌شن و سریع‌ترین خودکار اعمال می‌شه.

### مثال ۳ — فعال‌سازی DoT

```
➤ Select an option: 8
➤ Select: 1
```

### مثال ۴ — برگشت به حالت قبل

```
➤ Select an option: 14
```

---

## 🖥 دستورات CLI

```bash
sudo ./dns.sh              # منوی تعاملی
sudo ./dns.sh --help       # راهنما
sudo ./dns.sh --version    # نمایش نسخه
sudo ./dns.sh --restore    # برگشت به DNS قبلی
sudo ./dns.sh --no-deps    # رد کردن نصب پیش‌نیازها
```

اگه به‌عنوان دستور سیستم نصب کردی:

```bash
sudo dns-changer              # منوی تعاملی
sudo dns-changer --help       # راهنما
sudo dns-changer --version    # نسخه
sudo dns-changer --restore    # برگشت
sudo dns-changer --no-deps    # بدون پیش‌نیاز
```

---

## 🌐 DNSهای پشتیبانی‌شده

| Provider | Primary | Secondary | Region |
|:---|:---:|:---:|:---:|
| Google | `8.8.8.8` | `8.8.4.4` | 🌍 Global |
| Cloudflare | `1.1.1.1` | `1.0.0.1` | 🌍 Global |
| Quad9 | `9.9.9.9` | `149.112.112.112` | 🌍 Global |
| OpenDNS | `208.67.222.222` | `208.67.220.220` | 🌍 Global |
| Yandex | `77.88.8.8` | `77.88.8.1` | 🌍 Global |
| Shecan | `178.22.122.100` | `185.51.200.2` | 🇮🇷 Iran |
| 403 | `10.202.10.202` | `10.202.10.102` | 🇮🇷 Iran |

### DoT Providers

| Provider | Endpoint |
|:---|:---|
| Cloudflare | `1.1.1.1#cloudflare-dns.com` |
| Google | `8.8.8.8#dns.google` |
| Quad9 | `9.9.9.9#dns.quad9.net` |
| AdGuard | `94.140.14.14#dns.adguard-dns.com` |

---

## 🔒 DNS-over-TLS

**DoT** درخواست‌های DNS رو رمزنگاری می‌کنه تا ISP نتونه محتوای درخواست‌ها رو ببینه.

### پیش‌نیاز

- `systemd-resolved` نسخه **240+**
- Ubuntu **20.04+**
- پورت **853** باز

### فعال‌سازی

```
➤ Select an option: 8
➤ Select: 1  (Cloudflare)
```

### بررسی فعال بودن

```
➤ Select an option: 13
```

باید ببینی:

```
Resolved:    yes (systemd v249)
DoT support: yes
```

---

## 🎯 Split DNS

Split DNS بهت اجازه می‌ده برای یه دامنه خاص از DNS متفاوت استفاده کنی.

### مثال: استفاده از Shecan فقط برای `example.com`

```
➤ Select an option: 9
Domain: example.com
DNS for this domain: 178.22.122.100
```

### ذخیره‌سازی دائمی

تنظیمات در `/etc/systemd/resolved.conf.d/acor1-split-*.conf` ذخیره می‌شه و بعد از ری‌استارت باقی می‌مونه.

---

## 💻 سازگاری

| Distribution | Version | Status |
|:---|:---|:---:|
| Ubuntu | 18.04, 20.04, 22.04, 24.04 | ✅ |
| Debian | 10, 11, 12 | ✅ |
| CentOS | 7, 8 | ✅ |
| Rocky Linux | 8, 9 | ✅ |
| AlmaLinux | 8, 9 | ✅ |
| Fedora | 38+ | ✅ |
| Alpine | 3.18+ | ✅ بدون DoT |
| Arch Linux | Latest | ✅ |

### پیش‌نیازهای خودکار

اسکریپت این‌ها رو خودکار نصب می‌کنه:

- `curl` — برای دانلود
- `jq` — پارس JSON
- `bc` — محاسبات
- `iputils-ping` — تست پینگ
- `dnsutils` — تست resolve (dig)

روی هر distro اسم پکیج متفاوته — اسکریپت خودش تشخیص می‌ده.

---

## 📁 فایل‌های جانبی

| فایل | کاربرد |
|:---|:---|
| `/etc/resolv.conf.acor1.bak` | بکاپ DNS اصلی |
| `/etc/systemd/resolved.conf.acor1.bak` | بکاپ config systemd |
| `/var/log/acor1-dns.log` | تاریخچه تغییرات |
| `/etc/acor1-dns.last` | آخرین DNS اعمال‌شده |
| `/etc/systemd/resolved.conf.d/acor1-split-*.conf` | Split DNS configs |

### پاک‌سازی کامل

```bash
sudo rm -f /etc/resolv.conf.acor1.bak
sudo rm -f /etc/systemd/resolved.conf.acor1.bak
sudo rm -f /var/log/acor1-dns.log
sudo rm -f /etc/acor1-dns.last
sudo rm -f /etc/systemd/resolved.conf.d/acor1-split-*.conf
```

---

## 🔧 رفع اشکال

### ❌ DoT support: no

نسخه `systemd-resolved` قدیمیه. Ubuntu 20.04+ لازمه.

```bash
systemctl --version | head -1
# باید v240+ باشه
```

### ❌ Split DNS کار نمی‌کنه

چک کن `systemd-resolved` فعال باشه:

```bash
systemctl status systemd-resolved
```

### ❌ اینترنت قطع شد بعد از تغییر DNS

از بکاپ برگردون:

```bash
sudo ./dns.sh --restore
```

یا دستی:

```bash
sudo cp /etc/resolv.conf.acor1.bak /etc/resolv.conf
sudo systemctl restart systemd-resolved
```

### ❌ apt-get روی سرور کند می‌مونه

مرحله Dependencies رو رد کن:

```bash
sudo ./dns.sh --no-deps
```

### ❌ پکیج‌ها نصب نمی‌شن

مخازن رو عوض کن:

```bash
sudo sed -i 's|http://archive.ubuntu.com|https://mirror.arvancloud.ir|g' /etc/apt/sources.list
sudo apt-get update
```

### ❌ Permission denied

با `sudo` اجرا کن:

```bash
sudo bash dns.sh
```

---

## 📄 لایسنس

این پروژه تحت لایسنس **MIT** منتشر شده. برای جزئیات فایل [LICENSE](LICENSE) رو ببین.

---

<div align="center">

## 👨‍💻 سازنده

**acor1**

[![GitHub](https://img.shields.io/badge/GitHub-acor1-black?style=for-the-badge&logo=github)](https://github.com/acor1)
[![Repository](https://img.shields.io/badge/Repo-dns__changer__acor1-blue?style=for-the-badge&logo=git)](https://github.com/acor1/dns_changer_acor1)

---

**⭐ اگه این پروژه مفید بود، یه ستاره بده! ⭐**

Made with ❤️ by acor1

</div>
