CS3217 Problem Set 4
==

**Name:** Ashley Si Junke

**Matric No:** A0131496A

**Tutor:** Irvin Lim

## Tips

1. CS3217's Gitbook is at https://www.gitbook.com/book/cs3217/problem-sets/details. Do visit the Gitbook often, as it contains all things relevant to CS3217. You can also ask questions related to CS3217 there.
2. Take a look at `.gitignore`. It contains rules that ignores the changes in certain files when committing an Xcode project to revision control. (This is taken from https://github.com/github/gitignore/blob/master/Swift.gitignore).
3. A SwiftLint configuration file is provided for you. It is recommended for you to use SwiftLint and follow this configuration. Keep in mind that, ultimately, this tool is only a guideline; some exceptions may be made as long as code quality is not compromised.
    - Unlike previous problem sets, you are creating the Xcode project this time, which means you will need to copy the config into the folder created by Xcode and [configure Xcode](https://github.com/realm/SwiftLint#xcode) yourself if you want to use SwiftLint. 
4. Do not burn out. Have fun!

## Problem 1: Design

## Problem 1.1

![image](https://github.com/cs3217/2018-ps4-twink1e/blob/master/class-diagram.png)

Since I used PS3's level designer, and also `Queue`from PS1, I moved all the new files relevant to this PS into the folder `New Files`.
`GameBubble` is an object that encapsulates everything about the bubble, including its position, size, color, and its `UIImageView`. They make up the game graph. `ProjectileBubble` is a subclass of it. Additionally, it can be launched, moved, and stopped.

`GameEngine` is core of the game play. It handles the game logic, including adding a new projectile, moving it, and removing bursted and fallen bubbles. It contains a `Renderer` that takes care of the graphics and animation, and a `PhysicsEngine` that records all the bubbles in an adjacency list, handles path computation and collision detection.

`GamePlayViewController` is where the game loop is.

## Problem 1.2

- Since I'm using an adjacency list for the bubble graph, I can add bubbles that don't snap to position easily. Just by not calling the snap function for special bubble.

- For special effects bubble like removing all colors, or an entire row, I can trigger the effect after projectile is stopped, detect the special bubble connected to it, and loop through all the existing bubbles for that special effect.

- For magnet bubble, in the function `closestDistanceFromExistingBubble` in `PhysicsEngine` I check the distance between existing bubbles and the projectile. If the projectile is close enough, I can set the projectile's vector so that it changes direction.

- Clear separation of `Renderer` and `PhysicsEngine` makes implementing visual effects and special bubble features easier.


## Problem 2.1
![image](https://github.com/cs3217/2018-ps4-twink1e/blob/master/2.1.png)

In `GamePlayViewController` I override `touchesBegan` to get the position that user touches. If the projectile is not launched, I will launch the projectile in that direction.
Direction is a ray from the starting point of the projectile (the center of its resting position) to the point of touch. I then calculate the `sin` and `cos` of angle `θ`, and set the vector of the bubble in the x direction to `cos * speed` and in the y direction to `sin * speed`. If the touching point has a lower y value than the projectile center, then it is not launched. Just wait for the next touch.


## Problem 3: Testing
- When I press start in level designer, I should enter the game play screen where the bubbles are the same as those designed (or none if you didn't design any'. But the control area is removed. A canon with a resting projectile bubble shows up. A back button shows up.

- It is allowed to start with bubbles that are not attached to ceiling, or more than 3 connected bubbles come in the same colors. User can design the stage anyway they want.

- When I press back button, I go back to designer.

- When I touch any point below the center of the resting projectile, no change.

- When I touch any point above the center of the resting projectile, projectile moves in that direction smoothly until collision.


- If projectile hits side walls, it bounces off, i.e. reverse the x vector, but contines travelling up (no change in y vector).

- If projectile hits ceiling, it should snap into grid position and stay.

- If projectile hits another existing bubble, it should stop and snap to the nearest grid position.

- When projectile stops, a new resting projectile should show up on top of canon.

- When the stopped projectile and bubbles touching it forms a group of >= 3 bubbles of the same color, they should burst. Subsequent projectiles can occupy the same positions.

- When the bursted bubbles cause bubbles that they used to be touching to become unsupported, i.e. not touching any bubble that is touching the ceiling, these bubbles will fall off due to gravity, turn semi-transparent and bounce a bit on the floor. They disappear after they become motionless. Subsequent projectiles can occupy the same positions.
