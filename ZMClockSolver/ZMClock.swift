//
//  ZMClock.swift
//  ClockSolver
//
//  Created by Jason Kirchner on 4/8/16.
//  Copyright © 2016 Zen Motion LLC. All rights reserved.
//

import Foundation

/// Represents a clock with numbers around the face.

@available(iOS 7, *)
@available(OSX 10.10, *)
@available(watchOS 2, *)

struct ZMClock {

     /// The numbers on the 'Clock' face.
     /// The positions begin at the top of the clock face and rotate in a clockwise direction.
    let positions: [Int]

    /// The solution for the clock.
    /// * The solution will be calculated on whatever thread this variable is called on.
    ///
    /// - returns: The solution to the clock, i.e. the order of positions on the clock that will result in the clock being solved, or nil if the clock is impossible to solve
    var solution: [Int]? {
        return ZMClockSolver.solutionForClock(self)
    }

    /// The solution for the clock returned to a closure.
    /// * The solution is calculated on a background thread and will not block the main thread.
    /// * The closure is executed on the main thread.
    func calculateSolutionOnComplete( onComplete: ( [Int]?) -> Void ) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let solution = self.solution
            dispatch_async(dispatch_get_main_queue()) {
                onComplete(solution)
            }
        }
    }

    private var numberOfPositions: Int {
        return positions.count
    }

    private func possibleIndexesFromIndex(index: Int) -> [Int] {
        guard index < numberOfPositions else { return [Int]() }

        let movement = positions[index]

        let forwardIndex = abs((index + movement) % numberOfPositions)
        let reverseIndex = (((index - movement) % numberOfPositions) + numberOfPositions) % numberOfPositions

        var indexes = [forwardIndex]

        if reverseIndex != forwardIndex {
            indexes.append(reverseIndex)
        }

        return indexes
    }

    private struct ZMClockSolver {

        static func solutionForClock(clock: ZMClock) -> [Int]? {
            let numberOfPositions = clock.numberOfPositions
            guard numberOfPositions > 1 else { return nil }

            for startingIndex in 0..<numberOfPositions {
                let moves = [startingIndex]

                if clockMoves(moves, onClock: clock) == nil {
                    continue
                } else {
                    return clockMoves(moves, onClock: clock)
                }
            }
            return nil
        }

        static private func clockMoves(moves: [Int], onClock clock: ZMClock) -> [Int]? {
            guard moves.count <= clock.numberOfPositions else { return nil }
            guard let position = moves.last else { return nil }

            let possible = clock.possibleIndexesFromIndex(position)
            for finalPosition in possible {
                if moves.contains(finalPosition) {
                    continue
                } else {
                    var final = moves
                    final.append(finalPosition)

                    if final.count == clock.numberOfPositions {
                        return final
                    }

                    if clockMoves(final, onClock: clock) == nil {
                        continue
                    } else {
                        return clockMoves(final, onClock: clock)
                    }
                }
            }
            
            return nil
        }
    }
}
