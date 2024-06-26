/// Copyright (c) 2024 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

protocol AuthToken: Decodable {
    var token: String { get }
    var isExpired: Bool { get }
}

struct OAuthToken: AuthToken {
    let accessToken: String
    let tokenType: String
    /// Non-optional because it's recommended even though it's technically not required
    let expiresIn: Int
    var refreshToken: String?
    var scope: String?
    let requestedAt: Date
    let expiresAt: Date
    var isExpired: Bool { Date() >= expiresAt }
    /// Full token string. Includes token type and access token. Ex. "Bearer sampleAccessTokenHere"
    var token: String { "\(tokenType) \(accessToken)" }
    
    enum CodingKeys: String, CodingKey {
        case accessToken
        case tokenType
        case expiresIn
        case refreshToken
        case scope
    }
    
    init(from decoder: any Decoder) throws {
        let now = Date()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.expiresIn = expiresIn
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        self.scope = try container.decodeIfPresent(String.self, forKey: .scope)
        self.requestedAt = now
        self.expiresAt = Calendar.current.date(byAdding: .second, value: expiresIn, to: now) ?? now
    }
}


