# Network Analyzer (Android & iOS Native Apps)

Ứng dụng phân tích và chẩn đoán mạng toàn diện mô phỏng theo **Network Analyzer: WiFi Scan** trên App Store, được xây dựng độc lập trên 2 nền tảng Native:
1. **Android**: Viết bằng **Kotlin** với **Jetpack Compose (Material 3)**, Coroutines & Flow (mở bằng **Android Studio**).
2. **iOS**: Viết bằng **Swift** với **SwiftUI**, `Network.framework` (mở bằng **Xcode**).

---

## 📱 Cấu trúc thư mục dự án

```
d:\abc\
├── android\                                  # Project Android (Kotlin & Jetpack Compose)
│   ├── app\
│   │   ├── build.gradle.kts
│   │   └── src\main\
│   │       ├── AndroidManifest.xml           # Quyền truy cập mạng, Wi-Fi & Location
│   │       └── java\com\networkanalyzer\app\
│   │           ├── MainActivity.kt           # Activity chính
│   │           ├── NetworkAnalyzerApp.kt     # Điều hướng Navigation & Tab Bar
│   │           ├── data\                     # Models & Database MAC Vendor OUI
│   │           ├── diagnostics\              # Bộ xử lý chẩn đoán (LAN Scan, Ping, Trace, Port, DNS, Whois, Wi-Fi)
│   │           ├── ui\screens\               # Giao diện Compose cho từng module
│   │           └── viewmodels\               # NetworkViewModel quản lý trạng thái
│   ├── build.gradle.kts
│   └── settings.gradle.kts
│
└── ios\                                      # Project iOS (Swift & SwiftUI)
    ├── NetworkAnalyzer.xcodeproj\            # File Project mở trực tiếp bằng Xcode
    │   └── project.pbxproj
    └── NetworkAnalyzer\
        ├── NetworkAnalyzerApp.swift          # App Entry point
        ├── Info.plist                        # Quyền Local Network, Location & ATS
        ├── Models\                           # Data Models
        ├── Services\                         # Core Services (LAN, Ping, Trace, Port, DNS/Whois, Vendor Lookup)
        ├── ViewModels\                       # NetworkViewModel
        └── Views\                            # Giao diện SwiftUI (Tabs, Cards, Monitors)
```

---

## 🚀 Hướng dẫn mở và chạy dự án

### 1. Chạy trên Android Studio (Dự án Android)
1. Mở **Android Studio**.
2. Chọn **File** > **Open...** và duyệt đến thư mục `d:\abc\android`.
3. Chờ Android Studio đồng bộ xong Gradle dependencies.
4. Chọn thiết bị giả lập (Android Emulator - khuyên dùng API 33+) hoặc thiết bị thật.
5. Nhấn nút **Run ▶** (Shift + F10) để khởi chạy ứng dụng.

### 2. Chạy trên Xcode (Dự án iOS)
1. Trên máy macOS, mở ứng dụng **Xcode**.
2. Chọn **File** > **Open...** và chọn file `d:\abc\ios\NetworkAnalyzer.xcodeproj`.
3. Chọn Simulator (ví dụ iPhone 15/16 Pro) hoặc thiết bị iPhone thực tế.
4. Nhấn nút **Run ▶** (Cmd + R) để biên dịch và trải nghiệm ứng dụng.

---

## 🛠️ Các tính năng cốt lõi

| Tính năng | Chi tiết tính năng | Android (Kotlin) | iOS (Swift) |
| :--- | :--- | :---: | :---: |
| **Network Info** | SSID, BSSID, Signal RSSI, Local IPv4/IPv6, Gateway, Broadcast, DNS, Public IP, ISP & Geo-location | ✅ | ✅ |
| **LAN Scanner** | Quét thiết bị cùng dải mạng subnet `/24`, nhận diện Vendor theo chuẩn MAC OUI, Hostname, tốc độ phản hồi ms | ✅ | ✅ |
| **Wi-Fi Scanner** | Phân tích sóng Wi-Fi xung quanh, đo dBm, biểu đồ kênh 2.4GHz / 5GHz / 6GHz, chuẩn bảo mật | ✅ | ✅ |
| **Ping Tool** | Bắn gói tin ICMP / Socket đo độ trễ mạng liên tục, tính Min/Avg/Max RTT, Std Dev và % Packet Loss | ✅ | ✅ |
| **Traceroute** | Dò từng bước nhảy (Hop) qua các router trung gian đến máy chủ đích | ✅ | ✅ |
| **Port Scanner** | Quét cổng TCP listening (Web, SSH, DB, Remote, Mail) và hiển thị Service Banner | ✅ | ✅ |
| **DNS & WHOIS** | Tra cứu các bản ghi DNS (A, AAAA, CNAME, MX, TXT, NS, SOA) & thông tin sở hữu tên miền/IP WHOIS | ✅ | ✅ |
