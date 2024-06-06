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
  case invalidUrl(url: String, params: [String: String?])
  case decodingError(decodingError: DecodingError, url: String)
  
  var url: String {
    switch self {
    case .invalidUrl(let url, _), .decodingError(_, let url): return url
    }
  }
}

// MARK: - CustomNSError
extension NetworkError {
  var errorCode: Int {
    switch self {
    case .invalidUrl: return 7000
    case .decodingError: return 7100
    }
  }
  var errorUserInfo: [String : Any] {
    switch self {
    case .invalidUrl: return [:]
    case .decodingError(let decodingError, _):
      return ["decodingError": decodingError]
    }
  }
}

// MARK: - CustomStringConvertable
extension NetworkError {
  var description: String {
    var result = "--- NETWORK ERROR ---\n"
    result += "Originating from request to url: \(url)\n"
    switch self {
    case .invalidUrl: 
      result += "Invalid Url: An error occurred constructing the url for the network request"
    case .decodingError(let decodingError, _):
      result += "Decoding error:\n"
      result += "\(decodingError)"
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
    case .invalidUrl(_, let lParams):
      guard case .invalidUrl(_, let rParams) = rhs else { return false }
      return lParams == rParams
    case .decodingError(let lDecodingError, _):
      guard case .decodingError(let rDecodingError, _) = rhs else { return false }
      return "\(lDecodingError)" == "\(rDecodingError)"
    }
  }
}
