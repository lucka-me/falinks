//
//  ConstrainedTaskGroup+Cooldown.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 10/10/2024.
//

import Foundation

extension ConstrainedTaskGroup where ContinuationResult == Duration {
    @inlinable func addTask<Result: Sendable>(
        cooldown: Duration,
        operation: @escaping @isolated(any) () async throws -> (Result)
    ) async rethrows -> Result {
        try await self.addTask { cooldownRemaining in
            if let cooldownRemaining, cooldownRemaining > .zero {
                try await Task.sleep(for: cooldownRemaining)
            }
            
            let startTime = ContinuousClock.now
            
            let result = try await operation()
            
            let duration = ContinuousClock.now - startTime
            
            return (result, cooldown > duration ? (cooldown - duration) : .zero)
        }
    }
}
