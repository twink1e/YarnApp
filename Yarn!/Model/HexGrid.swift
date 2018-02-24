//  Copyright © 2018 nus.cs3217. All rights reserved.
import PhysicsEngine
/**
 Errors encountered by `HexGrid` that requires actions from callers.
 */
enum GridError: Error {
    case decodeError(String)
}

/**
 A 2-D hexagonal grid of spaces that can be filled with bubbles.
 Size is fixed during initialisation and cannot be changed.
 Number of rows is at least 1, number of cols for even row number is at least 2,
 and number of cols for odd row number is always 1 less than that for even row number.
 This ensures the grid can fit in a rectangle.

 The representation invariant is that `bubbles` do not violate the above mentioned size constraints.
*/
class HexGrid {

    // Read only to prevent change in the grid structure.
    private(set) var bubbles: [[Bubble?]] = []
    let row: Int
    let colEvenRow: Int
    var colOddRow: Int {
        return colEvenRow - 1
    }

    /// Constructs a grid of empty spaces.
    /// - Parameters:
    ///     - row: the number of rows, at least 1
    ///     - col: the number of columns for even rows, at least 2
    init?(row: Int, col: Int) {
        guard row > 0 && col > 1 else {
            return nil
        }
        self.row = row
        self.colEvenRow = col
        _fillEmptyBubbles()
        assert(_checkRep())
    }

    /// Constructs a grid from decoded data.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.row = try container.decode(Int.self, forKey: .row)
        self.colEvenRow = try container.decode(Int.self, forKey: .colEvenRow)
        self.bubbles = try container.decode([[CodableBubble?]].self, forKey: .bubbles).map { $0.map { $0?.bubble } }
        guard _checkRep() else {
            throw GridError.decodeError("Invalid representation of grid.")
        }
    }

    private func _isEvenRow(_ rowIndex: Int) -> Bool {
        return rowIndex % 2 == 0
    }

    /// Add a `ColoredBubble` at the position specified.
    /// Overwrite any existing bubble at the position.
    /// Do nothing if position is out of grid.
    func setColoredBubble(rowIndex: Int, colIndex: Int, color: BubbleColor) {
        guard _positionValid(rowIndex: rowIndex, colIndex: colIndex) else {
            return
        }
        bubbles[rowIndex][colIndex] = ColoredBubble(color)
        assert(_checkRep())
    }

    private func _positionValid(rowIndex: Int, colIndex: Int) -> Bool {
        guard rowIndex >= 0 && rowIndex < row else {
            return false
        }
        guard colIndex >= 0 && colIndex < (_isEvenRow(rowIndex) ? colEvenRow : colOddRow) else {
            return false
        }
        return true
    }

    /// Remove the bubble at the specified position.
    /// Do nothing if position is out of grid.
    func removeBubble(rowIndex: Int, colIndex: Int) {
        guard _positionValid(rowIndex: rowIndex, colIndex: colIndex) else {
            return
        }
        bubbles[rowIndex][colIndex] = nil
        assert(_checkRep())
    }

    /// A helper function to save caller the need to check if the indices are valid.
    func getBubble(rowIndex: Int, colIndex: Int) -> Bubble? {
        guard _positionValid(rowIndex: rowIndex, colIndex: colIndex) else {
            return nil
        }
        return bubbles[rowIndex][colIndex]
    }

    private func _fillEmptyBubbles() {
        bubbles = (0..<row).map { [Bubble?](repeating: nil, count: _isEvenRow($0) ? colEvenRow : colOddRow) }
    }

    /// Remove all the bubbles inside the grid.
    func clearBubbles() {
        _fillEmptyBubbles()
        assert(_checkRep())
    }

    /// Returns true if there is no bubble inside the grid.
    var isEmpty: Bool {
        return bubbles.flatMap { $0 }
            .reduce(true) { $0 && $1 == nil }
    }

    private func _checkRep() -> Bool {
        print(bubbles)
        if bubbles.count != row {
            return false
        }
        for i in 0..<row {
            if bubbles[i].count != (_isEvenRow(i) ? colEvenRow : colOddRow) {
                return false
            }
        }
        return true
    }
}

extension HexGrid: Codable {
    private enum CodingKeys: CodingKey {
        case row, colEvenRow, bubbles
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bubbles.map { $0.map { CodableBubble($0) } }, forKey: .bubbles)
        try container.encode(row, forKey: .row)
        try container.encode(colEvenRow, forKey: .colEvenRow)
    }
}
