//
//  TwilioVerifyDemoClient.swift
//  Vika
//
//  Local dev only: calls twilio-verify-demo/server.js (npm start).
//  Simulator: set baseURL to http://127.0.0.1:8787
//  Device: same Wi‑Fi as Mac, use Mac IP e.g. http://192.168.1.12:8787
//

import Foundation

enum TwilioVerifyDemoClient {
    /// Change for physical device testing (must match `npm start` host).
    static var baseURL: URL = URL(string: "http://127.0.0.1:8787")!

    struct SendResponse: Decodable {
        let ok: Bool
        let status: String?
        let sid: String?
        let to: String?
        let error: String?
    }

    struct CheckResponse: Decodable {
        let ok: Bool
        let status: String?
        let valid: Bool?
        let error: String?
    }

    static func sendCode(phone: String) async throws -> SendResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("verify/send"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["phone": phone])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(SendResponse.self, from: data)
        if http.statusCode >= 400 || !decoded.ok {
            throw NSError(domain: "TwilioVerifyDemo", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: decoded.error ?? "Request failed"])
        }
        return decoded
    }

    static func checkCode(phone: String, code: String) async throws -> CheckResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("verify/check"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["phone": phone, "code": code])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(CheckResponse.self, from: data)
        if http.statusCode >= 400 || !decoded.ok {
            throw NSError(domain: "TwilioVerifyDemo", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: decoded.error ?? "Verify failed"])
        }
        return decoded
    }
}
