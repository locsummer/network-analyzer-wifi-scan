import Foundation

struct MacVendorLookup {
    private static let vendors: [String: String] = [
        "00:03:93": "Apple, Inc.",
        "00:05:02": "Apple, Inc.",
        "00:0A:27": "Apple, Inc.",
        "00:0A:95": "Apple, Inc.",
        "00:10:FA": "Apple, Inc.",
        "00:11:24": "Apple, Inc.",
        "00:14:51": "Apple, Inc.",
        "00:16:CB": "Apple, Inc.",
        "00:17:F2": "Apple, Inc.",
        "00:1B:63": "Apple, Inc.",
        "00:1C:B3": "Apple, Inc.",
        "3C:22:FB": "Apple, Inc.",
        "40:6C:8F": "Apple, Inc.",
        "50:BC:96": "Apple, Inc.",
        "70:EE:50": "Apple, Inc.",
        "78:4F:43": "Apple, Inc.",
        "88:66:5A": "Apple, Inc.",
        "BC:D0:74": "Apple, Inc.",
        "F4:F5:DB": "Apple, Inc.",
        
        // Samsung
        "00:00:F0": "Samsung Electronics",
        "00:07:AB": "Samsung Electronics",
        "00:12:47": "Samsung Electronics",
        "00:16:32": "Samsung Electronics",
        "18:1E:78": "Samsung Electronics",
        "24:4B:03": "Samsung Electronics",
        "30:07:4D": "Samsung Electronics",
        "84:25:DB": "Samsung Electronics",
        "AC:5F:3E": "Samsung Electronics",
        
        // Google
        "00:1A:11": "Google LLC",
        "3C:5A:B4": "Google LLC",
        "54:60:09": "Google LLC",
        "74:C6:3B": "Google LLC",
        "94:EB:CD": "Google LLC",
        "D8:3C:69": "Google LLC",
        
        // TP-Link
        "00:14:78": "TP-Link",
        "00:19:E0": "TP-Link",
        "14:EB:B6": "TP-Link",
        "30:B5:C2": "TP-Link",
        "50:C7:BF": "TP-Link",
        "AC:84:C6": "TP-Link",
        
        // Cisco & Linksys
        "00:00:0C": "Cisco Systems",
        "00:01:42": "Cisco Systems",
        "00:0E:D7": "Cisco-Linksys",
        
        // Intel
        "00:02:B3": "Intel",
        "00:04:23": "Intel",
        "00:13:02": "Intel",
        "34:13:E8": "Intel",
        
        // Amazon
        "00:FC:8B": "Amazon Technologies",
        "38:F7:3D": "Amazon Technologies",
        "44:65:0D": "Amazon Technologies",
        "50:DC:E7": "Amazon Technologies",
        
        // Sony
        "00:01:4A": "Sony",
        "70:9E:29": "Sony Interactive"
    ]
    
    static func lookup(mac: String?) -> String {
        guard let mac = mac, mac.count >= 8 else { return "Unknown Vendor" }
        let prefix = String(mac.uppercased().replacingOccurrences(of: "-", with: ":").prefix(8))
        return vendors[prefix] ?? "Network Device"
    }
}
