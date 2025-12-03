//
//  APIClient.swift
//  InsulinDeliveryApp
//
//  Secure API communication layer
//  IEC 62304 §5.6 - Network communication and security
//

import Foundation

/// Handles all API communication with backend services
/// @safety_critical: Secure and reliable communication is essential
class APIClient {
    
    static let shared = APIClient()
    
    private let baseURL: URL
    private let session: URLSession
    
    private init() {
        // Configure base URL from environment or config
        self.baseURL = URL(string: "https://api.insulindelivery.example.com")!
        
        // Configure secure URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = SafetyLimits.apiTimeout
        config.timeoutIntervalForResource = SafetyLimits.apiTimeout * 2
        config.waitsForConnectivity = true
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication
    
    struct AuthResponse: Codable {
        let sessionToken: String
        let expiresAt: Date
        let userId: String
    }
    
    func authenticate(username: String, passwordHash: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("/api/v1/auth/login")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "passwordHash": passwordHash
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        performRequest(request, completion: completion)
    }
    
    func refreshSession(token: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("/api/v1/auth/refresh")
        var request = createAuthenticatedRequest(url: endpoint, method: "POST", token: token)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newToken = json["sessionToken"] as? String else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            completion(.success(newToken))
        }.resume()
    }
    
    func invalidateSession(token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("/api/v1/auth/logout")
        let request = createAuthenticatedRequest(url: endpoint, method: "POST", token: token)
        
        session.dataTask(with: request) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }.resume()
    }
    
    // MARK: - User Profile
    
    func fetchUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let token = AuthenticationService.shared.getSessionToken() else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let endpoint = baseURL.appendingPathComponent("/api/v1/user/profile")
        let request = createAuthenticatedRequest(url: endpoint, method: "GET", token: token)
        
        performRequest(request, completion: completion)
    }
    
    // MARK: - Glucose Monitoring
    
    func fetchLatestGlucoseReading(completion: @escaping (Result<GlucoseReading, Error>) -> Void) {
        guard let token = AuthenticationService.shared.getSessionToken() else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let endpoint = baseURL.appendingPathComponent("/api/v1/glucose/latest")
        let request = createAuthenticatedRequest(url: endpoint, method: "GET", token: token)
        
        performRequest(request, completion: completion)
    }
    
    func fetchGlucoseHistory(hours: Int, completion: @escaping (Result<[GlucoseReading], Error>) -> Void) {
        guard let token = AuthenticationService.shared.getSessionToken() else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let endpoint = baseURL.appendingPathComponent("/api/v1/glucose/history?hours=\(hours)")
        let request = createAuthenticatedRequest(url: endpoint, method: "GET", token: token)
        
        performRequest(request, completion: completion)
    }
    
    // MARK: - Insulin Delivery
    
    func deliverInsulin(dose: InsulinDose, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = AuthenticationService.shared.getSessionToken() else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let endpoint = baseURL.appendingPathComponent("/api/v1/insulin/deliver")
        var request = createAuthenticatedRequest(url: endpoint, method: "POST", token: token)
        
        request.httpBody = try? JSONEncoder().encode(dose)
        
        session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(APIError.deliveryFailed))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
    
    func cancelInsulinDelivery(doseId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = AuthenticationService.shared.getSessionToken() else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let endpoint = baseURL.appendingPathComponent("/api/v1/insulin/cancel/\(doseId.uuidString)")
        let request = createAuthenticatedRequest(url: endpoint, method: "POST", token: token)
        
        session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(APIError.cancellationFailed))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    private func createAuthenticatedRequest(url: URL, method: String, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decoded = try decoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case noData
    case deliveryFailed
    case cancellationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in."
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .deliveryFailed:
            return "Insulin delivery failed"
        case .cancellationFailed:
            return "Failed to cancel delivery"
        }
    }
}