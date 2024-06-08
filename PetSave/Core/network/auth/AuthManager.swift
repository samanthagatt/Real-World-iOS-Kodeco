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

protocol AuthTokenStorage<Token> {
    associatedtype Token
    func get(key: String) -> String
    func set(key: String, value: Token) -> String
    func delete(key: String) -> Bool
}

func thissss() {
    let tag = "com.example.keys.mykey"
    let key = "currentAuthToken"
    let addquery: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: Data(tag.utf8),
        kSecValueRef as String: key
    ]
}

class AuthManager<Token: AuthToken> {
    var task: PatientTask<Token, NetworkError>
    var currentToken: Token?
    var networkManager: NetworkManager
    
    init(networkManager: NetworkManager, authRequest: any NetworkRequest<Token>) {
        self.networkManager = networkManager
        self.task = PatientTask {
            await Self.tokenRequest(networkManager, authRequest)
        }
    }
    
    func getToken(fetchBeforeExpiry: Bool) async throws(NetworkError) -> Token {
        guard let currentToken,
                !currentToken.isExpired,
                !fetchBeforeExpiry else {
            // If no current token, current token has expired, or refreshBeforeExpiry is true
            let token = try await task.execute().get()
            currentToken = token
            return token
        }
        // If the current token has not expired and refreshBeforeExpiry == false
        return currentToken
    }
    
    func getToken() async throws(NetworkError) -> Token {
        try await getToken(fetchBeforeExpiry: false)
    }
    
    private static func tokenRequest(
        _ networkManager: NetworkManager,
        _ authRequest: any NetworkRequest<Token>
    ) async -> Result<Token, NetworkError> {
        // TODO: Typed throws in closures?
        // Why does trying to do exactly this inside the closure for `PatientTask { }` produce the error:
        // Cannot convert value of type 'any Error' to expected argument type 'NetworkError'
        do {
            let token = try await networkManager.load(authRequest)
            return .success(token)
        } catch {
            return .failure(error)
        }
    }
    
    func getTokenString() async throws(NetworkError) -> String {
        try await getToken().token
    }
    
    func getTokenString(fetchBeforeExpiry: Bool) async throws(NetworkError) -> String {
        try await getToken(fetchBeforeExpiry: fetchBeforeExpiry).token
    }
}

class PetFinderAuthManager: AuthManager<OAuthToken> { 
    convenience init(networkManager: NetworkManager) {
        self.init(networkManager: networkManager, authRequest: AuthTokenRequest())
    }
}
