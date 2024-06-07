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

/// Task that will wait to be manually executed, and will only be kicked off once(*) while inflight (subsequent calls will wait for current task to finish executing). Task will start executing again (upon call to `execute()`) if previous executions have been completed.
struct PatientTask<Success, Failure: Error> {
    private var task: Task<Result<Success, Failure>, Never>?
    private let executable: () async -> Result<Success, Failure>
    
    init(executable: @escaping () async -> Result<Success, Failure>) {
        self.executable = executable
    }
    
    mutating func execute() async throws(Failure) -> Result<Success, Failure> {
        if let task {
            // Task is already running
            return await task.value
        } else {
            let newTask = Task { [executable] in
                await executable()
            }
            // (*) Assigning the newTask in two steps allows for a very small window of time where the executable is running but ThreadSafeTask ins't aware
            // The alternative is to directly assign the new `Task { }` to `task` but then you'd have to use a force unwrap to return `await task!.value`
            task = newTask
            let value = await newTask.value
            task = nil
            return value
        }
    }
}
