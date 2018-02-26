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

}
