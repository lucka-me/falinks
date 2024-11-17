//
//  ConstrainedTaskGroup.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 10/10/2024.
//

import Foundation

actor ConstrainedTaskGroup<ContinuationResult: Sendable> {
    private let maxTasks: Int
    
    private var currentTaskCount = 0
    private var pendingTaskContinuations: [ CheckedContinuation<ContinuationResult?, Never> ] = [ ]
    
    init(maxTasks: Int) {
        self.maxTasks = maxTasks
    }
}

extension ConstrainedTaskGroup {
    func addTask<Result: Sendable>(
        operation: @escaping (ContinuationResult?) async throws -> (Result, ContinuationResult?)
    ) async rethrows -> Result {
        let previousContinuationResult: ContinuationResult?
        if currentTaskCount < maxTasks {
            previousContinuationResult = nil
        } else {
            previousContinuationResult = await withCheckedContinuation {
                self.pendingTaskContinuations.insert($0, at: 0)
            }
        }
        
        currentTaskCount += 1
        
        var currentContinuationResult: ContinuationResult? = nil
        defer {
            currentTaskCount -= 1
            if currentTaskCount < maxTasks, let continuation = pendingTaskContinuations.popLast() {
                continuation.resume(returning: currentContinuationResult)
            }
        }
        
        let results = try await operation(previousContinuationResult)
        currentContinuationResult = results.1
        return results.0
    }

    func addTask<Result: Sendable>(
        operation: @escaping () async throws -> Result
    ) async rethrows -> Result {
        if currentTaskCount >= maxTasks {
            let _ = await withCheckedContinuation {
                self.pendingTaskContinuations.insert($0, at: 0)
            }
        }
        
        currentTaskCount += 1
        
        defer {
            currentTaskCount -= 1
            if currentTaskCount < maxTasks, let continuation = pendingTaskContinuations.popLast() {
                continuation.resume(returning: nil)
            }
        }
        
        return try await operation()
    }
}
