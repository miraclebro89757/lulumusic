import CoreGraphics

/// Player Tab geometry: header lives in the top safe-area inset, and the stacked
/// cover's rear peek is reserved *inside* the cover stack so it cannot paint over
/// 「Live Memory」.
enum PlayerStageLayout {
    static let headerMinHeight: CGFloat = 44
    static let headerHorizontalPadding: CGFloat = 20
    /// Spec Spacer ~12–16pt between HeaderBar and CoverStack.
    static let headerToCoverSpacing: CGFloat = 16
    static let rearPeekX: CGFloat = 16
    static let rearPeekY: CGFloat = 10
    static let rearOversize: CGFloat = 4
    static let coverWidthFraction: CGFloat = 0.76

    static func coverSide(containerWidth: CGFloat, maxSide: CGFloat = 304) -> CGFloat {
        min(maxSide, containerWidth * coverWidthFraction)
    }

    static func coverStackSize(side: CGFloat) -> CGSize {
        CGSize(width: side + rearPeekX, height: side + rearPeekY)
    }

    static func coverFrames(side: CGFloat) -> (stack: CGRect, rear: CGRect, main: CGRect) {
        let stack = CGRect(origin: .zero, size: coverStackSize(side: side))
        let rear = CGRect(
            x: rearPeekX,
            y: 0,
            width: side + rearOversize,
            height: side + rearOversize
        )
        let main = CGRect(
            x: 0,
            y: rearPeekY,
            width: side,
            height: side
        )
        return (stack, rear, main)
    }

    static func rearOverflowAboveStack(side: CGFloat) -> CGFloat {
        let frames = coverFrames(side: side)
        return max(0, frames.stack.minY - frames.rear.minY)
    }

    static func headerCoverClearance(side: CGFloat) -> CGFloat {
        headerToCoverSpacing - rearOverflowAboveStack(side: side)
    }
}
