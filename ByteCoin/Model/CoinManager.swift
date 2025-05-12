import Foundation

protocol CoinManagerDelegate {
    func didUpdatePrice(price: String, currency: String)
    func didFailWithError(error: Error)
}

struct CoinManager {
    
    var delegate: CoinManagerDelegate?
    
    let baseURL = "https://api.coingecko.com/api/v3/simple/price"

    let currencyArray = ["AUD", "BRL", "CAD", "CNY", "EUR", "GBP", "HKD", "IDR", "ILS", "INR",
                         "JPY", "MXN", "NOK", "NZD", "PLN", "RON", "RUB", "SEK", "SGD", "USD", "ZAR"]
    
    func getCoinPrice(for currency: String) {
        
        let urlString = "\(baseURL)?ids=bitcoin&vs_currencies=\(currency.lowercased())"
        print("Request URL: \(urlString)")
        
        if let url = URL(string: urlString) {
            
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                
                if let safeData = data {
                    print("Response JSON: \(String(data: safeData, encoding: .utf8) ?? "")")
                    
                    if let price = self.parseJSON(safeData, currency: currency) {
                        let priceString = String(format: "%.2f", price)
                        self.delegate?.didUpdatePrice(price: priceString, currency: currency)
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(_ data: Data, currency: String) -> Double? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let error = json["status"] as? [String: Any],
                   let message = error["error_message"] as? String {
                    print("🚫 API Error: \(message)")
                    return nil
                }
                
                if let bitcoinData = json["bitcoin"] as? [String: Any],
                   let price = bitcoinData[currency.lowercased()] as? Double {
                    return price
                } else {
                    print("⚠️ Unexpected JSON structure.")
                    return nil
                }
            }
        } catch {
            delegate?.didFailWithError(error: error)
        }
        return nil
    }
}
