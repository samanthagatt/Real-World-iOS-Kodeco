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

enum NetworkError: CustomNSError, CustomStringConvertible, Equatable {
    case invalidUrl(scheme: String, host: String, path: String, queries: [String: String])
    /// Coding errors
    case encoding(EncodingError, url: String),
         decoding(DecodingError, data: Data?, url: String)
    /// Errors from parsing the `URLResponse`
    case unauthenticated(url: String),
         restricted(url: String),
         clientError(code: Int, data: Data, url: String),
         serverError(code: Int, data: Data, url: String)
    
    var path: String? {
        guard let url = URL(string: url) else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: true)?.path
    }
    
    var url: String {
        switch self {
        case let .invalidUrl(scheme, host, path, queries):
            return debugUrlFrom(scheme, host, path, queries)
        case .encoding(_, let url),
                .decoding(_, _, let url),
                .unauthenticated(let url),
                .restricted(let url),
                .clientError(_, _, let url),
                .serverError(_, _, let url):
            return url
        }
    }
}

// MARK: - CustomNSError
extension NetworkError {
    var errorCode: Int {
        switch self {
        case .invalidUrl: return 7000
        case .encoding: return 7100
        case .decoding: return 7200
        case .unauthenticated: return 7300
        case .restricted: return 7400
        case .clientError: return 7500
        case .serverError: return 7600
        }
    }
    // Not necessary. Just playing around
    var errorUserInfo: [String : Any] {
        switch self {
        case .invalidUrl, .unauthenticated, .restricted: return [:]
        case .encoding(let encodingError, _):
            return ["encodingError": encodingError]
        case .decoding(let decodingError, let data, _):
            return ["decodingError": decodingError, "data": data as Any]
        case .clientError(let code, let data, _),
                .serverError(let code, let data, _):
            return ["errorCode": code, "data": data]
        }
    }
}

// MARK: - CustomStringConvertable
extension NetworkError {
    var description: String {
        var result = "--- NETWORK ERROR ---\n"
        result += "Originating from request to url: \(url)\n"
        func responseErrorDesc(_ code: Int, _ response: String, _ url: String) {
            result += "Network request resulted in a \(code) status code."
            result += (response.isEmpty ? "" :
                        "\nBackend responded with the message: \(response)")
        }
        switch self {
        case let .invalidUrl(scheme, host, path, queries):
            result += "URLComponents failed to generate a url for\n"
            result += "scheme: " + scheme + "\n"
            result += "host: " + host + "\n"
            result += "path: " + path + "\n"
            result += "queries: \(queries)"
        case .encoding(let encodingError, _):
            result += "Encoding failed while adding the body to the request.\n"
            result += "Underlying error: \(encodingError)"
        case .decoding(let decodingError, let data, _):
            result += "Decoding error:\n"
            result += "\(decodingError)"
            var jsonString = "No data"
            if let data {
                jsonString = String(decoding: data, as: UTF8.self)
            }
            result += "Decoding failed while parsing the response from the backend.\n"
            result += "Underlying error: \(decodingError),\n"
            result += "JSON: \(jsonString)"
        case let .unauthenticated(url):
            responseErrorDesc(401, "", url)
        case let .restricted(url):
            responseErrorDesc(403, "", url)
        case let .clientError(code: code, data: data, url: url):
            responseErrorDesc(code, String(decoding: data, as: UTF8.self), url)
        case let .serverError(code, data, url):
            responseErrorDesc(code, String(decoding: data, as: UTF8.self), url)
        }
        return result
    }
}

// MARK: - Equatable
extension NetworkError {
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        // Bail out early
        guard lhs.url == rhs.url else { return false }
        switch lhs {
        case .invalidUrl(_, _, _, let lQueries):
            if case .invalidUrl(_, _, _, let rQueries) = rhs {
                return lQueries == rQueries
            }
        case let .encoding(lEncodingError, _):
            if case let .encoding(rEncodingError, _) = rhs {
                return "\(lEncodingError)" == "\(rEncodingError)"
            }
        case let .decoding(lDecodingError, lData, _):
            if case let .decoding(rDecodingError, rData, _) = rhs {
                return "\(lDecodingError)" == "\(rDecodingError)" && lData == rData
            }
        case .unauthenticated(_):
            if case .unauthenticated = rhs {
                return true
            }
        case .restricted(_):
            if case .restricted = rhs {
                return true
            }
        case let .clientError(lCode, lData, lUrl):
            if case let .clientError(rCode, rData, rUrl) = rhs {
                return lCode == rCode && lData == rData && lUrl == rUrl
            }
        case let .serverError(lCode, lData, lUrl):
            if case let .serverError(rCode, rData, rUrl) = rhs {
                return lCode == rCode && lData == rData && lUrl == rUrl
            }
        }
        return false
    }
}

/// Crude url construction just for debugging
private func debugUrlFrom(
    _ scheme: String,
    _ host: String,
    _ path: String,
    _ queries: [String: String]
) -> String {
    var host = host
    var path = path
    var intermediate = scheme
    if !scheme.hasSuffix("://") {
        intermediate += "://"
    }
    if host.hasPrefix("://") {
        host.removeFirst(3)
    }
    intermediate += host
    if intermediate.hasSuffix("/") && path.hasPrefix("/") {
        path.removeFirst(1)
    } else if !intermediate.hasPrefix("/") && !path.hasPrefix("/") {
        intermediate += "/"
    }
    intermediate += path
    if !queries.isEmpty {
        if !path.hasSuffix("?") {
            intermediate += "?"
        }
        intermediate += queries.reduce("") {
            $0.appending("\($1.key)=\($1.value)")
        }
    }
    return intermediate
}
