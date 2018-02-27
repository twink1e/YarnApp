import PhysicsEngine

extension PhysicsEngine {
    // Return a tuple of the closest collided existing bubble to the projectile and the distance.
    // Return a nil if such bubble does not exist.
    func closestCollidedBubbleAndDistance(_ projectile: GameBubble) -> (GameBubble, CGFloat)? {
        var bubbleAndDistance: (GameBubble, CGFloat)?
        for bubble in adjList.keys {
            let distance = distanceBetween(bubble, with: projectile)
            if distance <= (bubbleAndDistance?.1 ?? 0) {
                bubbleAndDistance = (bubble, distance)
            }
        }
        return bubbleAndDistance
    }

    // Move the projectile in its reverse direction so that it just touches the collided bubble.
    func backtrackToTouching(_ projectile: ProjectileBubble, with collidedBubble: GameBubble) {
        print ("overlapping", collidedBubble)
        let xDiff = collidedBubble.centerX - projectile.centerX
        let yDiff = projectile.centerY - collidedBubble.centerY
        // Solve quadratic equation
        // diameter ^ 2 = (xDiff + cos * dist) ^ 2 + (yDiff - sin * dist) ^ 2
        // in the form ax^2 + bx + c = 0 where a = 1
        let b = projectile.cos * 2 * xDiff - projectile.sin * 2 * yDiff
        let c = pow(xDiff, 2) + pow(yDiff, 2) - pow(bubbleDiameter, 2)
        // Take the only positive answer
        let dist = (sqrt(pow(b, 2) - 4 * c) - b) / 2
        projectile.moveForDistance(-dist)
    }

    // Return a set of bursted bubbles due to power bubbles and their chain reactions.
    func bubblesBurstedByPower(_ startBubble: GameBubble) -> Set<GameBubble> {
        // A queue of special bubbles.
        var queue = Queue<GameBubble>()
        var allRemovedBubbles = bubblesBurstedByStar(startBubble)
        var usedPowerBubbles = Set<GameBubble>()
        adjList[startBubble]?.forEach { queue.enqueue($0) }
        while !queue.isEmpty {
            guard let bubble = queue.dequeue() else {
                break
            }
            usedPowerBubbles.insert(bubble)
            let removed = bubblesBurstedByLightningOrBomb(bubble)
            allRemovedBubbles = allRemovedBubbles.union(removed)
            removed
                .filter { ($0.power == .lightning || $0.power == .bomb) && !usedPowerBubbles.contains($0)}
                .forEach { queue.enqueue($0) }
        }
        return allRemovedBubbles
    }
    private func bubblesBurstedByStar(_ activatorBubble: GameBubble) -> Set<GameBubble> {
        guard let neighbors = adjList[activatorBubble] else {
            return []
        }
        let starBubbles = neighbors.filter { $0.power == .star }
        guard !starBubbles.isEmpty else {
            return []
        }
        let coloredBubbles = bubblesOfColor(activatorBubble.color)
        return coloredBubbles.union(starBubbles)
    }

    // Bubbles removed by the `powerBubble` which has the lightning or star power.
    private func bubblesBurstedByLightningOrBomb(_ powerBubble: GameBubble) -> Set<GameBubble> {
        switch powerBubble.power {
        case .bomb:
            var bubbles = Set(adjList[powerBubble] ?? [])
            bubbles.insert(powerBubble)
            return bubbles
        case .lightning:
            return bubblesOfSameRow(powerBubble)
        default:
            return []
        }
    }

    private func bubblesOfColor(_ color: BubbleColor) -> Set<GameBubble> {
        return Set(adjList.keys.filter { $0.color == color})
    }

    // Bubbles are considered of same row as `startBubble` if their centerY is within the topY and bottomY of `startBubble`.
    private func bubblesOfSameRow(_ startBubble: GameBubble) -> Set<GameBubble> {
        return Set(adjList.keys.filter {
            $0.centerY >= startBubble.topY && $0.centerY <= startBubble.topY + bubbleDiameter
        })
    }
}
