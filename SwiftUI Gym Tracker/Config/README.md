# Yapılandırma Dosyaları

Bu dizin, APIKeys.swift gibi gizli kalması gereken yapılandırma dosyalarını içerir.

## APIKeys.swift Örneği

APIKeys.swift dosyası aşağıdaki formatta oluşturulmalıdır:

```swift
import Foundation

enum APIKeys {
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
}
```

Not: APIKeys.swift dosyası .gitignore'a eklenmiştir ve GitHub'a push edilmez.
