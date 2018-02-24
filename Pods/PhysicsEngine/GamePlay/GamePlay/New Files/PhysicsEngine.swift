import UIKit

/**
 A class that handles path computation and collision detection for the game.
 Bubble graph is represented as an adjacency list.
 */
public class PhysicsEngine {
    var adjList: [GameBubble: [GameBubble]] = [:]
    let screenHeight: CGFloat
    let bubbleDiameter: CGFloat

    public init(screenHeight: CGFloat, bubbleDiameter: CGFloat) {
        self.screenHeight = screenHeight
        self.bubbleDiameter = bubbleDiameter
    }

    public func clear() {
        adjList = [:]
    }

    // Build up `adjList` with the starting bubbles.
    public func buildGraph(_ bubbles: [GameBubble]) {
        for bubble in bubbles {
            adjList[bubble] = []
        }
        guard bubbles.count > 1 else {
            return
        }
        for i in 0 ..< bubbles.count - 1 {
            for j in i + 1 ..< bubbles.count {
                if connected(bubbles[i], with: bubbles[j]) {
                    addConnection(bubbles[i], bubbles[j])
                }
            }
        }
    }

    // Return the shortest distance between any bubble and `projectile`.
    public func closestDistanceFromExistingBubble(_ projectile: GameBubble) -> CGFloat {
        var closestDistance = screenHeight
        for bubble in adjList.keys {
            let distance = distanceBetween(bubble, with: projectile)
            if distance <= 0 {
                closestDistance = min(distance, closestDistance)
            }
        }
        return closestDistance
    }

    // A BFS to get all the same-color bubbles that are connected to `startBubble`.
    // Return the set of the same-color bubbles if their number >= `minBurstNum`,
    // otherwise return empty set.
    public func getBurstedBubbles(_ startBubble: GameBubble) -> Set<GameBubble> {
        var queue = Queue<GameBubble>()
        var sameColorBubbles = Set<GameBubble>()
        queue.enqueue(startBubble)
        sameColorBubbles.insert(startBubble)
        while !queue.isEmpty {
            guard let bubble = queue.dequeue() else {
                break
            }
            guard let neighbors = adjList[bubble] else {
                break
            }
            neighbors
                .filter { $0.color == bubble.color && !sameColorBubbles.contains($0) }
                .forEach { queue.enqueue($0); sameColorBubbles.insert($0) }
        }
        return sameColorBubbles.count >= Config.minBurstNum ? sameColorBubbles : []
    }

    // Use each neighbor of the bursted bubbles as a starting node to get fallen bubbles.
    // Return all combined fallen bubbles.
    public func getFellBubbles(_ burstedBubbles: Set<GameBubble>) -> Set<GameBubble> {
        var removedBubbles = burstedBubbles
        var fellBubbles = Set<GameBubble>()
        var neighborsOfRemovedBubbles = Set<GameBubble>()
        burstedBubbles
            .map { adjList[$0] ?? [] }
            .flatMap { $0 }
            .filter { !removedBubbles.contains($0) }
            .forEach { neighborsOfRemovedBubbles.insert($0) }
        for bubble in neighborsOfRemovedBubbles {
            let unsupported = unsupportedBubbles(from: bubble, removedBubbles: removedBubbles)
            fellBubbles = fellBubbles.union(unsupported)
            removedBubbles = removedBubbles.union(unsupported)
        }
        return fellBubbles
    }

    // Use BFS to get the connected group of bubbles starting from `startBubble`.
    // Return them if none of them is touching the ceiling,
    // otherwise return empty.
    private func unsupportedBubbles(from startBubble: GameBubble,
                                    removedBubbles: Set<GameBubble>) -> Set<GameBubble> {
        var queue = Queue<GameBubble>()
        var connected = Set<GameBubble>()
        queue.enqueue(startBubble)
        if !startBubble.touchingCeiling {
            connected.insert(startBubble)
        }
        while !queue.isEmpty {
            guard let bubble = queue.dequeue() else {
                break
            }
            guard let neighbors = adjList[bubble] else {
                break
            }
            for neighbor in neighbors {
                guard !removedBubbles.contains(neighbor) && !connected.contains(neighbor) else {
                    continue
                }
                guard !neighbor.touchingCeiling else {
                    return []
                }
                queue.enqueue(neighbor)
                connected.insert(neighbor)
            }
        }
        return connected
    }

    public func removeBubbleFromGraph(_ bubble: GameBubble) {
        guard let neighbors = adjList[bubble] else {
            return
        }
        neighbors.forEach { removeConnection($0, bubble) }
        adjList[bubble] = nil
    }

    public func addToGraph(_ newBubble: GameBubble) {
        adjList[newBubble] = []
        adjList.keys
            .filter { $0 != newBubble && self.connected($0, with: newBubble) }
            .forEach { addConnection($0, newBubble) }
    }

    // Return true if the 2 bubbles are overlapping, or touching (leeway given to account for calculation error)
    private func connected(_ bubble1: GameBubble, with bubble2: GameBubble) -> Bool {
        return distanceBetween(bubble1, with: bubble2) <= Config.bubbleConnectErrorMargin
    }

    // Return the minimum distance between 2 bubbles.
    // Distance is negative they are overlapping.
    private func distanceBetween(_ bubble1: GameBubble, with bubble2: GameBubble) -> CGFloat {
        let xDiff = bubble1.centerX - bubble2.centerX
        let yDiff = bubble1.centerY - bubble2.centerY
        let distance = sqrt(pow(xDiff, 2) + pow(yDiff, 2))
        return distance - bubbleDiameter
    }

    // - MARK: Graph connection modifiers.
    private func addConnection(_ bubble1: GameBubble, _ bubble2: GameBubble) {
        appendInAdjList(bubble1, to: bubble2)
        appendInAdjList(bubble2, to: bubble1)
    }
    private func appendInAdjList(_ bubble1: GameBubble, to bubble2: GameBubble) {
        guard var temp = adjList[bubble2] else {
            return
        }
        temp.append(bubble1)
        adjList[bubble2] = temp
    }
    private func removeConnection(_ bubble1: GameBubble, _ bubble2: GameBubble) {
        removeInAdjList(bubble1, from: bubble2)
        removeInAdjList(bubble2, from: bubble1)
    }
    private func removeInAdjList(_ bubble1: GameBubble, from bubble2: GameBubble) {
        guard var temp = adjList[bubble2], let index = temp.index(of: bubble1) else {
            return
        }
        temp.remove(at: index)
        adjList[bubble2] = temp
    }
}
