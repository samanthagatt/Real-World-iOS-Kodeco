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

class AuthManager {
    private var task: PatientTask<String, NetworkError>
    private var currentToken: AuthToken?
    
    init(requestManager: RequestManager) {
        self.task = PatientTask {
            await Self.tokenRequest(requestManager)
        }
    }
    
    func getToken(refreshBeforeExpiry: Bool = false) async throws(NetworkError) -> String {
        guard let currentToken,
                currentToken.expiresAt <= Date(),
                !refreshBeforeExpiry else {
            // If no current token, current token has expired, or refreshBeforeExpiry is true
            return try await task.execute().get()
        }
        // If the current token has not expired and refreshBeforeExpiry == false
        return currentToken.token
    }
    
    private static func tokenRequest(_ requestManager: RequestManager) async -> Result<String, NetworkError> {
        // TODO: Typed throws in closures?
        // Why does trying to do exactly this inside the closure for `PatientTask { }` produce the error:
        // Cannot convert value of type 'any Error' to expected argument type 'NetworkError'
        do {
            let token = try await requestManager.load(AuthTokenRequest()).token
            return .success(token)
        } catch {
            return .failure(error)
        }
    }
}
