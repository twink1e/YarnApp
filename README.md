CS3217 Problem Set 5
==

**Name:** Your name

**Matric No:** Your matric no

**Tutor:** Your tutor's name

## Tips

1. CS3217's Gitbook is at https://www.gitbook.com/book/cs3217/problem-sets/details. Do visit the Gitbook often, as it contains all things relevant to CS3217. You can also ask questions related to CS3217 there.
2. Take a look at `.gitignore`. It contains rules that ignores the changes in certain files when committing an Xcode project to revision control. (This is taken from https://github.com/github/gitignore/blob/master/Swift.gitignore).
3. A Swiftlint configuration file is provided for you. It is recommended for you to use Swiftlint and follow this configuration. Keep in mind that, ultimately, this tool is only a guideline; some exceptions may be made as long as code quality is not compromised.
4. Do not burn out. Have fun!

### Rules of Your Game

Your answer here


### Problem 1: Cannon Direction

Your answer here


### Problem 2: Upcoming Bubbles

Your answer here


### Problem 3: Integration

Your answer here


### Problem 4.4

Your answer here


### Problem 7: Class Diagram

Please save your diagram as `class-diagram.png` in the root directory of the repository.

### Problem 8: Testing
#### Test normal colored bubbles
- When there is no path made up of bubbles connected to each other from certain bubbles to the ceiling (definition of unsupported bubbles), these bubbles fall off. Unsupported will only not fall off if they are made in the level designer. However, if any bubbles that are connected to them is removed, the falling will be triggered.

#### Test special bubbles
1. Indestructable
  - It cannot be removed by shooting any number of any normal colored bubbles around it.
  - It falls off when becoming unsupported like normal bubbles.
  - Bomb and lightning can remove indestructable, but not star.
2. Star
  - When any colored projectile lands next to it, all the bubbles of the projectile color (including the projectile itself) and the star bubble itself burst. So if the projectile is the only bubble of its color, only the projectile and the star bubble is removed.
  - It can be removed by bomb, lightning and falling without power being triggered.
3. Bomb
  - When a projectile lands next to it, all the bubbles connected to the bomb and bomb itself is removed.
  - When removed by lightning, its power is triggered.
  - When removed by falling, its power is not triggered.
4. Lightning
  - When a projectile lands next to it, all the bubbles in the same row as the lightning and lightning itself is removed. A bubble is considered being in the same row if its centerY is within (including) the top and the bottom of the lighning bubble.
  - When removed by bomb, its power is triggered.
  - When removed by falling, its power is not triggered.
5. Magnetic
  - The magnetic force should not be too strong. Even when the entire design grid is filled with magnets, projectiles shouldn't move so fast that game logic breaks or bubbles become outside the screen. Hence it is acceptable that a single magnet exerts very little attraction force. It takes about 4 magnets together for the projectile to be moving in a visible curve.
  - Magnets make projectile move towards them. The closer their distance, the faster the projectile move towards magnets.
  - Like indestructable, magnets can be removed by lightning, bomb and falling. They can't be removed by color-matching or star.

#### Test normal & special bubbles together
When normal and special bubbles are both present in the game, their behavior as mentioned above should not change.
This means that when a projectile lands connected to both special bubbles and normal bubbles, both special and normal bubbles will react accordingly.


### Problem 9: The Bells & Whistles

Your answer here


### Problem 10: Final Reflection

Your answer here
