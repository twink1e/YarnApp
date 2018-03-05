import UIKit

/**
 Protocol for class that handles UI updates in the Game Play scene.
 */
protocol GamePlayDelegate: class {
    /// Add a UI view to the screen.
    func addViewToScreen(_: UIView)

    /// Pause the game by pausing the display link.
    func pauseGameLoop()

    /// Update the current projectile label to the given string.
    func updateCurrentBubbleLabel(_: String)

    /// Update the next projectile label to the given string.
    func updateNextBubbleLabel(_: String)

    /// Update the point string on screen to the given string.
    func updatePoints(_: String)

    /// Show screen updates for winning.
    func winGame(_: String)

    /// Show screen updates for losing.
    func loseGame()

    /// Return animator associated to the screen.
    var itemsAnimator: UIDynamicAnimator { get }
}
