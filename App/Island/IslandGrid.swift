import CoreGraphics

struct GridCell: Hashable {
    let col: Int
    let row: Int
}

/// Square grid from economy.json `island` (cell size + unlocked home plot).
/// Buildings use a 2x2 footprint; every cell must sit on the island's grass oval.
struct IslandGrid {
    static let footprintSize = 2

    let cell: CGFloat
    let minCol: Int
    let maxCol: Int
    let minRow: Int
    let maxRow: Int
    /// Grass top of island_base.png as drawn by IslandBuilder (world units).
    let grassRadii: CGSize

    init(island: Economy.Island) {
        cell = CGFloat(island.cell)
        let home = island.plots.first(where: { $0.startsUnlocked == true }) ?? island.plots.first
        minCol = home?.minCol ?? -6
        maxCol = home?.maxCol ?? 6
        minRow = home?.minRow ?? -5
        maxRow = home?.maxRow ?? 5
        grassRadii = CGSize(width: cell * 8.1, height: cell * 4.3)
    }

    func cellCenter(_ c: GridCell) -> CGPoint {
        CGPoint(x: CGFloat(c.col) * cell, y: CGFloat(c.row) * cell)
    }

    /// Cells covered by a building whose bottom-left cell is (col, row).
    func footprint(col: Int, row: Int) -> [GridCell] {
        var cells: [GridCell] = []
        for dc in 0..<IslandGrid.footprintSize {
            for dr in 0..<IslandGrid.footprintSize {
                cells.append(GridCell(col: col + dc, row: row + dr))
            }
        }
        return cells
    }

    /// World position of a building's center.
    func center(col: Int, row: Int) -> CGPoint {
        let half = CGFloat(IslandGrid.footprintSize - 1) / 2
        return CGPoint(x: (CGFloat(col) + half) * cell, y: (CGFloat(row) + half) * cell)
    }

    /// Bottom-left cell of the footprint whose center is nearest `p`.
    func origin(near p: CGPoint) -> (col: Int, row: Int) {
        let half = CGFloat(IslandGrid.footprintSize - 1) / 2
        var col = Int((p.x / cell - half).rounded())
        var row = Int((p.y / cell - half).rounded())
        col = min(maxCol - IslandGrid.footprintSize + 1, max(minCol, col))
        row = min(maxRow - IslandGrid.footprintSize + 1, max(minRow, row))
        return (col, row)
    }

    func isOnGrass(_ c: GridCell) -> Bool {
        guard c.col >= minCol, c.col <= maxCol, c.row >= minRow, c.row <= maxRow else { return false }
        let p = cellCenter(c)
        let nx = p.x / grassRadii.width
        let ny = p.y / grassRadii.height
        return nx * nx + ny * ny <= 1
    }

    func canPlace(col: Int, row: Int, occupied: Set<GridCell>) -> Bool {
        footprint(col: col, row: row).allSatisfy { isOnGrass($0) && !occupied.contains($0) }
    }

    func nearestFree(to p: CGPoint, occupied: Set<GridCell>) -> (col: Int, row: Int)? {
        let start = origin(near: p)
        var best: (col: Int, row: Int)?
        var bestDistance = Int.max
        for c in minCol...maxCol {
            for r in minRow...maxRow where canPlace(col: c, row: r, occupied: occupied) {
                let d = (c - start.col) * (c - start.col) + (r - start.row) * (r - start.row)
                if d < bestDistance {
                    bestDistance = d
                    best = (c, r)
                }
            }
        }
        return best
    }

    /// Outline of every buildable cell, shown during placement.
    func overlayPath() -> CGPath {
        let path = CGMutablePath()
        for c in minCol...maxCol {
            for r in minRow...maxRow {
                let gc = GridCell(col: c, row: r)
                guard isOnGrass(gc) else { continue }
                let p = cellCenter(gc)
                path.addRect(CGRect(x: p.x - cell / 2 + 3, y: p.y - cell / 2 + 3,
                                    width: cell - 6, height: cell - 6))
            }
        }
        return path
    }
}
