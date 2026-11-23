package com.networkanalyzer.app.data

object MacVendorLookup {
    private val vendors = mapOf(
        // Apple
        "00:03:93" to "Apple, Inc.",
        "00:05:02" to "Apple, Inc.",
        "00:0A:27" to "Apple, Inc.",
        "00:0A:95" to "Apple, Inc.",
        "00:10:FA" to "Apple, Inc.",
        "00:11:24" to "Apple, Inc.",
        "00:14:51" to "Apple, Inc.",
        "00:16:CB" to "Apple, Inc.",
        "00:17:F2" to "Apple, Inc.",
        "00:1B:63" to "Apple, Inc.",
        "00:1C:B3" to "Apple, Inc.",
        "3C:22:FB" to "Apple, Inc.",
        "40:6C:8F" to "Apple, Inc.",
        "50:BC:96" to "Apple, Inc.",
        "70:EE:50" to "Apple, Inc.",
        "78:4F:43" to "Apple, Inc.",
        "88:66:5A" to "Apple, Inc.",
        "BC:D0:74" to "Apple, Inc.",
        "F4:F5:DB" to "Apple, Inc.",

        // Samsung
        "00:00:F0" to "Samsung Electronics",
        "00:07:AB" to "Samsung Electronics",
        "00:12:47" to "Samsung Electronics",
        "00:16:32" to "Samsung Electronics",
        "18:1E:78" to "Samsung Electronics",
        "24:4B:03" to "Samsung Electronics",
        "30:07:4D" to "Samsung Electronics",
        "84:25:DB" to "Samsung Electronics",
        "AC:5F:3E" to "Samsung Electronics",

        // Google
        "00:1A:11" to "Google LLC",
        "3C:5A:B4" to "Google LLC",
        "54:60:09" to "Google LLC",
        "74:C6:3B" to "Google LLC",
        "94:EB:CD" to "Google LLC",
        "D8:3C:69" to "Google LLC",

        // TP-Link
        "00:14:78" to "TP-Link",
        "00:19:E0" to "TP-Link",
        "14:EB:B6" to "TP-Link",
        "30:B5:C2" to "TP-Link",
        "50:C7:BF" to "TP-Link",
        "AC:84:C6" to "TP-Link",

        // Xiaomi
        "00:9E:C8" to "Xiaomi Communications",
        "18:59:36" to "Xiaomi Communications",
        "28:6C:07" to "Xiaomi Communications",
        "34:80:0D" to "Xiaomi Communications",
        "50:64:2B" to "Xiaomi Communications",
        "64:09:80" to "Xiaomi Communications",
        "78:11:DC" to "Xiaomi Communications",

        // Huawei
        "00:18:82" to "Huawei Technologies",
        "00:25:9E" to "Huawei Technologies",
        "00:E0:FC" to "Huawei Technologies",
        "08:19:A6" to "Huawei Technologies",
        "10:1B:54" to "Huawei Technologies",

        // Cisco & Linksys
        "00:00:0C" to "Cisco Systems",
        "00:01:42" to "Cisco Systems",
        "00:0E:D7" to "Cisco-Linksys",

        // Intel
        "00:02:B3" to "Intel",
        "00:04:23" to "Intel",
        "00:13:02" to "Intel",
        "34:13:E8" to "Intel",

        // Amazon
        "00:FC:8B" to "Amazon Technologies",
        "38:F7:3D" to "Amazon Technologies",
        "44:65:0D" to "Amazon Technologies",
        "50:DC:E7" to "Amazon Technologies",

        // Sony
        "00:01:4A" to "Sony",
        "70:9E:29" to "Sony Interactive",

        // Realme / Oppo / Vivo
        "1C:77:F6" to "OPPO Mobile",
        "28:FF:3E" to "OPPO Mobile",
        "70:8A:09" to "vivo Mobile",
        "84:DB:AC" to "vivo Mobile"
    )

    fun lookup(mac: String?): String {
        if (mac.isNullOrBlank() || mac.length < 8) return "Unknown Vendor"
        val clean = mac.trim().uppercase().replace('-', ':')
        val prefix = if (clean.length >= 8) clean.substring(0, 8) else clean
        return vendors[prefix] ?: "Network Device"
    }
}
