import PhysicsEngine

extension PhysicsEngine {
    // Return the closest collided existing bubble to the projectile.
    // Return a nil if such bubble does not exist.
    func closestCollidedBubble(_ projectile: GameBubble) -> GameBubble? {
        var collidedBubble: GameBubble?
        var closestDistance: CGFloat?
        for bubble in adjList.keys {
            let distance = distanceBetween(bubble, with: projectile)
            if distance <= closestDistance ?? 0 {
                collidedBubble = bubble
                closestDistance = distance
            }
        }
        return collidedBubble
    }

    // Move the projectile in its reverse direction so that it just touches the collided bubble.
    func backtrackToTouching(_ projectile: ProjectileBubble, with collidedBubble: GameBubble) {
        let xDiff = projectile.centerX - collidedBubble.centerX
        let yDiff = abs(projectile.centerY - collidedBubble.centerY)
        // Solve quadratic equation
        // diameter ^ 2 = (xDiff - |cos * dist|) ^ 2 + (yDiff + sin * dist|) ^ 2
        // in the form ax^2 + bx + c = 0 where a = 1
        let b1 = abs(projectile.sin) * 2 * yDiff - projectile.cos * 2 * xDiff
        let b2 = abs(projectile.sin) * 2 * yDiff - abs(projectile.cos) * 2 * xDiff
        let c = pow(xDiff, 2) + pow(yDiff, 2) - pow(bubbleDiameter, 2)
        // Take the only positive answer
        let dist1 = (sqrt(pow(b1, 2) - 4 * c) - b1) / 2
        let dist2 = (sqrt(pow(b2, 2) - 4 * c) - b2) / 2
        print(dist1, dist2)
        projectile.moveForDistance(-dist1)
    }

}
