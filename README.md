# 💰 Finly — Personal Finance & Daily Accounting App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.style=for-the-badge)](#)

> **Finly** คือแอปพลิเคชันบันทึกรายรับ-รายจ่ายส่วนบุคคล (Personal Finance & Daily Accounting) ที่พัฒนาด้วย **Flutter** ช่วยให้ผู้ใช้ติดตามการใช้จ่าย คำนวณอัตราการออม และวิเคราะห์พฤติกรรมทางการเงินประจำเดือนได้อย่างมีประสิทธิภาพ ผ่านอินเทอร์เฟซสไตล์ Modern Fintech ที่ใช้งานง่าย รวดเร็ว และปลอดภัย

---

## ⚡ Quick Start (วิธีเริ่มต้นใช้งานอย่างรวดเร็ว)

### ความต้องการของระบบ (Prerequisites)
- **Flutter SDK:** `^3.x` (Dart SDK `^3.12.2`)
- **IDE:** Android Studio / VS Code (พร้อม Flutter Extension)
- **Device:** Android Emulator / iOS Simulator หรือ อุปกรณ์จริง

### ขั้นตอนการรันแอปพลิเคชัน

```bash
# 1. โคลนคลังโค้ด (Clone Repository)
git clone https://github.com/Jirasak-Thongpila/finly.git
cd finly

# 2. ติดตั้ง Dependencies
flutter pub get

# 3. รันแอปพลิเคชัน (Default Production API)
flutter run
```

> **💡 การตั้งค่า API Base URL:**
> หากต้องการเปลี่ยนไปใช้ API Local หรือ Staging สามารถกำหนดผ่าน `--dart-define` ได้ทันที:
> ```bash
> flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
> ```

---

## 🌟 ฟีเจอร์หลัก (Key Features)

- 🔐 **ระบบยืนยันตัวตน (Authentication & Persistent Session):**
  - สมัครสมาชิก (Register) และ เข้าสู่ระบบ (Login) ด้วย Email / Password
  - บันทึก JWT Token อย่างปลอดภัยด้วย `flutter_secure_storage`
  - ตรวจสอบเซสชันอัตโนมัติเมื่อเปิดแอปผ่าน **SessionGate** (ไม่ต้องเข้าสู่ระบบซ้ำ)
- 📊 **แดชบอร์ดสรุปภาพรวม (Financial Dashboard):**
  - แสดงยอดเงินรวมคงเหลือ (Total Balance), ยอดรายรับ และ ยอดรายจ่าย
  - คำนวณอัตราการออมสุทธิ (Net Savings Rate) แบบเรียลไทม์
  - ปุ่มทางลัด (Quick Action) สำหรับเพิ่มรายการรายรับ/รายจ่ายได้อย่างรวดเร็ว
- 💸 **จัดการรายการรายรับ-รายจ่าย (Transaction Management):**
  - เพิ่ม แก้ไข และลบ รายการรายรับ-รายจ่าย (CRUD)
  - กรองข้อมูลตามประเภท (Income/Expense), หมวดหมู่ (Category) หรือ ช่วงเวลา (Date Range)
  - รองรับระบบตรวจจับหมวดหมู่อัตโนมัติทั้งภาษาไทยและอังกฤษ พร้อมจับคู่ Material Icons สวยงาม
- 📈 **สถิติและรายงานวิเคราะห์ (Statistics & Analytics):**
  - สรุปสถิติประจำเดือน (`YYYY-MM`)
  - แสดงสัดส่วนค่าใช้จ่ายแบ่งตามหมวดหมู่ คำนวณเป็นเปอร์เซ็นต์และกราฟเชิงเปรียบเทียบ
- 🎨 **ดีไซน์สไตล์ Modern Fintech (UI/UX):**
  - โทนสี Emerald Green ร่วมกับ Lime Accent เพิ่มความสดใสและเป็นกันเอง
  - ใช้ฟอนต์ **Inter** อ่านง่าย สบายตา ผ่าน `google_fonts`
  - ออกแบบบนมาตรฐาน Material Design 3

---

## 🛠️ เทคโนโลยีและแพ็กเกจที่ใช้ (Tech Stack & Dependencies)

| Component | Technology / Package | Description |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) | SDK พัฒนา Cross-platform Mobile Application |
| **Language** | [Dart](https://dart.dev) | ภาษาหลักของโครงการ (SDK `^3.12.2`) |
| **State Management** | [`provider`](https://pub.dev/packages/provider) | จัดการ Application State และ Session Status |
| **Secure Storage** | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | เข้ารหัสและจัดเก็บ JWT Token บนเครื่องอย่างปลอดภัย |
| **HTTP Client** | [`http`](https://pub.dev/packages/http) | เชื่อมต่อ Daily Accounting REST API พร้อมระบบ Auth Header |
| **Typography & Formatting** | [`google_fonts`](https://pub.dev/packages/google_fonts), [`intl`](https://pub.dev/packages/intl) | ใช้ฟอนต์ Inter และฟอร์แมตตัวเลขทางการเงิน/วันที่ |

---

## 📁 โครงสร้างโปรเจกต์ (Project Structure)

```text
lib/
├── main.dart             # จุดเริ่มต้นแอปพลิเคชัน & SessionGate Switcher
├── models/               # Data Models (User, Transaction, Category, Summary)
│   ├── category.dart
│   ├── summary.dart
│   ├── transaction.dart
│   └── user.dart
├── screens/              # หน้าจอ UI หลักของแอป
│   ├── welcome_screen.dart       # หน้าต้อนรับ (Unauthenticated)
│   ├── login_screen.dart         # หน้าเข้าสู่ระบบ
│   ├── register_screen.dart      # หน้าลงทะเบียน
│   ├── home_screen.dart          # หน้าแดชบอร์ดหลัก
│   ├── transactions_screen.dart  # รายการธุรกรรมทั้งหมด & Filter
│   ├── add_transaction_screen.dart # ฟอร์มเพิ่ม/แก้ไข รายการ
│   ├── statistics_screen.dart    # หน้าสถิติและรายงานประจำเดือน
│   └── settings_screen.dart      # หน้าตั้งค่าโปรไฟล์ & ออกจากระบบ
├── services/             # Service Layer เชื่อมต่อ Backend API & Storage
│   ├── api_client.dart           # HTTP Client Wrapper
│   ├── auth_service.dart         # Auth API Endpoints (Login/Register/Me)
│   ├── transaction_service.dart  # Transaction & Report API Endpoints
│   └── session_manager.dart      # จัดการ Session State & Token Cache
├── state/                # Form submit state helper
├── utils/                # Constants, App Theme, Palette & Category Icons Mapping
│   └── constants.dart
└── widgets/              # Reusable Component Widgets
```

---

## 🌐 รายการ REST API Endpoints

แอปพลิเคชัน Finly เชื่อมต่อกับ Daily Accounting REST API:

| Category | Endpoint | Method | Description |
| :--- | :--- | :---: | :--- |
| **Auth** | `/api/auth/register` | `POST` | ลงทะเบียนผู้ใช้งานใหม่ |
| **Auth** | `/api/auth/login` | `POST` | เข้าสู่ระบบเพื่อรับ JWT Token |
| **Auth** | `/api/auth/me` | `GET` | ดึงข้อมูลโปรไฟล์ผู้ใช้งานปัจจุบัน |
| **Auth** | `/api/auth/logout` | `POST` | ออกจากระบบ |
| **Transactions** | `/api/transactions` | `GET` | ดึงรายการธุรกรรม (รองรับ type, startDate, endDate, category, page, limit) |
| **Transactions** | `/api/transactions` | `POST` | สร้างรายการธุรกรรมใหม่ (รายรับ/รายจ่าย) |
| **Transactions** | `/api/transactions/:id` | `PUT` | แก้ไขรายการธุรกรรมตาม ID |
| **Transactions** | `/api/transactions/:id` | `DELETE` | ลบรายการธุรกรรมตาม ID |
| **Categories** | `/api/categories` | `GET` | ดึงรายการหมวดหมู่ทั้งหมด |
| **Reports** | `/api/reports/summary` | `GET` | ดึงสรุปสถิติประจำเดือน (`?month=YYYY-MM`) |

---

## 👥 ทีมผู้จัดทำ

<div align="center">

| ชื่อ-นามสกุล | รหัสนักศึกษา |
| :--- | :---: |
| นาย จิรศักดิ์ ทองพิละ | 6712732103 |
| นาย ฐิติพงศ์ อิงสันเทียะ | 6712732104 |
| นางสาว จีรนันท์ เกิดกล้า | 6712732121 |

<br/>

### 🎓 สถาบันการศึกษา

**สาขาวิชาวิศวกรรมคอมพิวเตอร์**<br/>
**คณะศิลปศาสตร์และวิทยาศาสตร์**<br/>
**มหาวิทยาลัยราชภัฏศรีสะเกษ**

</div>

---

## 📄 ลิขสิทธิ์ (License)

โปรเจกต์นี้จัดทำขึ้นเพื่อการศึกษาและการใช้งานส่วนบุคคล
Developed with ❤️ by **Finly Team**
