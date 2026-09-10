import Foundation

enum ImportSource: String, Codable, CaseIterable {
    case files
    case appleMusic
    case web
    case share

    var label: String {
        switch self {
        case .files: return "文件"
        case .appleMusic: return "苹果音乐"
        case .web: return "网页"
        case .share: return "分享"
        }
    }
}
