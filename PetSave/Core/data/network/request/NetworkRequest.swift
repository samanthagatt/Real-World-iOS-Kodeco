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

protocol NetworkRequest {
    var method: RequestMethod { get }
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var queries: [String: String] { get }
    var headers: [String: String] { get }
    var body: RequestBody? { get }
}

extension NetworkRequest {
    var method: RequestMethod { .get }
    var scheme: String { "https" }
    var host: String { APIConstants.host }
    var queries: [String: String] { [:] }
    var headers: [String: String] { [:] }
    var body: RequestBody? { nil }
    
    func createURLRequest(authToken: String?) throws -> URLRequest {
        // URL construction
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        for query in queries {
            if components.queryItems == nil {
                components.queryItems = []
            }
            components.queryItems?
                .append(URLQueryItem(name: query.key, value: query.value))
        }
        guard let url = components.url else {
            throw NetworkError.invalidUrl(url: scheme + host + path, params: queries)
        }
        // Request construction
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.setValue(authToken, forHTTPHeaderField: "Authorization")
        urlRequest.setValue(body?.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try body?.asData()
        return urlRequest
    }
}
