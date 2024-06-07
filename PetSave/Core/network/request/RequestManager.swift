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

class RequestManager {
    private let session: NetworkSession
    
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    func load<T>(
        _ request: any NetworkRequest<T>,
        with authToken: String? = nil
    ) async throws(NetworkError) -> T {
        let (url, req) = try request.createURLRequest(authToken: authToken)
        let data = try await kickOff(req: req, at: url, with: authToken)
        // TODO: Implement retries
        return try request.responseDecoder.decode(data: data, origin: url)
    }
    
    // TODO: Private funcs with typed throws?
    // Why does using a private function with a typed throws in a function that's not private cause the build to fail?
    // Is it part of the functionality somehow or just because typed throws are still in beta? 🤔
    func kickOff(
        req request: URLRequest,
        at url: String,
        with authToken: String?
    ) async throws(NetworkError) -> Data  {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.errorCode {
            case URLError.Code.notConnectedToInternet.rawValue:
                throw .noNetwork(url: url)
            case URLError.Code.timedOut.rawValue:
                throw .timeout(url: url)
            default:
                throw .transportError(error, url: url)
            }
        } catch {
            throw .transportError(error, url: url)
        }
        guard let code = (response as? HTTPURLResponse)?.statusCode else {
            // Unlikely to occurr. If it's really an error, it'll show up later. Probably when trying to decode the data.
            return data
        }
        if code == 401 { throw .unauthenticated(url: "") }
        if code == 403 { throw .restricted(url: "") }
        if 400...499 ~= code {
            throw .clientError(code: code, data: data, url: "")
        }
        if 500...599 ~= code {
            throw .serverError(code: code, data: data, url: "")
        }
        return data
    }
}
