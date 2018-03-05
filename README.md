CS3217 Problem Set 5
==

**Name:** Ashley Si Junke

**Matric No:** A0131496A

**Tutor:** Irvin Lim

## Tips

1. CS3217's Gitbook is at https://www.gitbook.com/book/cs3217/problem-sets/details. Do visit the Gitbook often, as it contains all things relevant to CS3217. You can also ask questions related to CS3217 there.
2. Take a look at `.gitignore`. It contains rules that ignores the changes in certain files when committing an Xcode project to revision control. (This is taken from https://github.com/github/gitignore/blob/master/Swift.gitignore).
3. A Swiftlint configuration file is provided for you. It is recommended for you to use Swiftlint and follow this configuration. Keep in mind that, ultimately, this tool is only a guideline; some exceptions may be made as long as code quality is not compromised.
4. Do not burn out. Have fun!

### Rules of Your Game

1. Game play

Game target: Remove all the bubbles given (including special bubbles) at the start of the game (thereafter called target bubbles, and can be identified as yarn balls without pins). No need to remove bubbles shot by player (thereafter called play bubbles and identified as yarn balls with pins).
Player has limited number of play bubbles.
Win: Clear all target bubbles before no more play bubbles.
Lose: Play bubbles exhausted but target still exists. Or anytime during the game that a bubble touches the cutting line (a dotted line with a scissors icon).
10 points for every target bubble bursted. 30 points for every target bubble dropped. No point for play bubbles bursted or dropped. 20 points for every unused play bubble at the end of the game.

2. Level design

To play a level, yarn limit must be given.
To save a level, yarn limit and level name must be given.
Level will be overwritten if it is updated after being selected form level selector.
Level designer entered through the "Design Level" button from menu will only create new levels.
Preloaded levels cannot be changed or deleted.

3. Magnetic bubble

Magnetic bubbles lose their effect if the path between its center and the center of the projectile is blocked. While the projectile is moving, magnetic bubbles that are blocked will dim out.

### Problem 1: Cannon Direction

User can select direction by tapping, and canon will fire in the direction towards that point.
User can also pan the screen. Canon will move to face the touching poing while user pans. Canon fires in the direction towards the point where pan ends.
However, canon can't fire if the angle canon has to turn from vertical position to face the touching point is greater than the angle has to turn from vertical position to face the ends of the cutting line. This is to avoid shooting bubble downwards, excessive bouncing and also that bubbles shouldn't land below cutting line.


### Problem 2: Upcoming Bubbles

First check what colors are in the target bubbles, and choose a random one from that set. If target bubbles are all special bubbles, randomly choose a color. This ensures that the game is winnable.
To determine non-snapping and snapping, the ratio is specified in Config, and every projectile is has a probability of being non-snapping while following the ratio.


### Problem 3: Integration

I need to calculate the real positions (closely packed without margin) in Level designer and pass them to game engine.
This is good since I don't have to change the structure I used for my hexGrid, also the level data is not display dependent. I don't need to store the bubbles in the level with their coordinated on the screen.
The down side is that I cannot bypass the level designer and just start the game.


### Problem 4.4

Set indestructible to have no color.

Loop through every bubble to find the bubbles in the same row or the target color with lightning and star.

Loop the neighbors only for bomb.

Put the special bubble in the queue if they are bursted for the chain effect.

The alternatives are to save the bubbles in the grid, or to save bubbles that are in the same row together, so I don't need to traverse all for lightning, but with non-snapping bubble this becomes complicated since they rows are not just grid rows anymore. Non-snapping bubbles can be part of 2 rows at the same time. This adds overhead when adding bubbles, not much better than my solution. And my solution is less bug-prone.

### Problem 7: Class Diagram
![digarm](https://github.com/cs3217/2018-ps5-twink1e/blob/master/class-diagram.png)
I added the delegates instead of closure passing. All variables are sored in Config for easy reference. There are 3 main parts: level selector, level designer and game play. They all have their main view controller, which conforms to the respective delegate. They own the view models directly, while view models have a weak reference to them via delegates.

For Game Play, the view model is `Game Enigne`, which has a `Physics Engine` to handle path computation and collision detection, and `Renderer` to handle animation and display.

The difference between `GameBubble` and `Bubble` is that `GameBubble` is for game play. It stores the position and movement behavior of the bubble. `Bubble` is just for identification in the hexGrid with its row and col index and bubble color and power.

### Problem 8: Testing
#### Black-box testing
##### Test normal colored bubbles
- When there is no path made up of bubbles connected to each other from certain bubbles to the ceiling (definition of unsupported bubbles), these bubbles fall off. Unsupported will only not fall off if they are made in the level designer. However, if any bubbles that are connected to them is removed, the falling will be triggered.

##### Test special bubbles
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
  - The magnetic force should not be too strong. Even when the entire design grid is filled with magnets, projectiles shouldn't move so fast that game logic breaks or bubbles become outside the screen. 
  - Magnets make projectile move towards them. The closer their distance, the faster the projectile move towards magnets.
  - Like indestructable, magnets can be removed by lightning, bomb and falling. They can't be removed by color-matching or star.

##### Test normal & special bubbles together
When normal and special bubbles are both present in the game, their behavior as mentioned above should not change.
This means that when a projectile lands connected to both special bubbles and normal bubbles, both special and normal bubbles will react accordingly.

##### Test canon
1. Can't fire any where below the cutting line.
2. touch legal areas to fire
3. Pan and release. If the final position is legal, fire.

##### Game play
1. I should see the exact same bubbles in the same locations as in the level designer when I enter game play, except that now they don't have any margin.
2. Anytime I tap on the back button I can go back to level designer.
3. I can see the current bubble and the next bubble at the right bottom corner. They are updated as I play. The bubbles I fire are the same color and type as those being indicated.
##### Test gameflow
1. In the menu screen, when I tap on 'Select Level' I should enter level selector and see a collection of all the preloaded levels and the levels I created.
2. Tapping on the back button in level selector will lead back to menu.
3. In the menu screen, tapping on 'Design Level' will lead to level designer.
##### Test level designer
1. After selecting a bubble from the palette, when I tap or pan the cells in the grid, the cells I touched should become that type of bubble, regardless of what the cell used to be.
2. After selecting the eraser, when I tap or pan the cells in the grid, the cells I touched should become empty, regardless of what the cell used to be.
3. Regardless of what I have selected or not selected, when I long press a cell, it should become empty regardless of what the cell used to be.
4. When I haven't selected any bubble nor eraser, when I tap on an existing bubble in the grid, it should change to the next bubble in the palette and the changing loops.
5. When I tap on reset, the grid becomes empty.
6. After I have entered valid yarn limit, I can start the game and enter game play.
7. After I have entered valid yarn limit and name, I can save the level.
8. After I tap on back button I go back to menu.

#### Glass-box testing
1. Add assert to check that there is no 2 bubbles overlapping after every projectile is fired. A calculation error margin of 0.1 is allowed since floating point is involved.
2. Add printing calls to see that the projectile is going towards the point user has touched.
3. Add printing calls to see that levels are saved with the right data.

### Problem 9: The Bells & Whistles

Graphics: Made by myself except backgrounds and cats silouette from vecteezy.

Music and sound effects: Files from sound bible. Background music, sound effects for bubble buttons in level designer, when canon fires and at end game screens.

Screenshot feature in level designer

Level selector in card views with details like overview image, created and updated time

Able to update and delete levels

Points system

Animation of canon firing and bubble bursting

Limited bubble

Win and lose game logic and corresponding screens.


### Problem 10: Final Reflection
I think MVVM is great especially now I use delegates. It makes the code easier to write and read with clean separation and great extendability.
I might consider storing the bubble's exact coordinated on the screen when I persist the level. This way, I can quickly build up the game for game engine.
Right now I use `GameEngine` for the execution of the game logic and keeps track of the projectile, which drives the game. `PhysicsEngine` does the path computation and collision detection and `Renderer` handles animation and display. This seems clear for now. However, when I add more special bubbles, I will need to add more code to `GameEngine` to handle the special behaviors, which makes it hard to maintain. It may be better if I make each special bubble a subclass and handle its own behavior. Then it becomes more extensible. However, this kind of design also means that each bubble needs to know all the bubbles. In my current design there's no such issue.
