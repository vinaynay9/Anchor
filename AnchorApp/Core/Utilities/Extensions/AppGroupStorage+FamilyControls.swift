import Foundation
import FamilyControls
import Shared

extension AppGroupStorage {
    func encodeApplicationTokens(_ tokens: Set<ApplicationToken>) -> [Data] {
        tokens.compactMap { try? JSONEncoder().encode($0) }
    }

    func decodeApplicationTokens(_ dataList: [Data]) -> Set<ApplicationToken> {
        Set(dataList.compactMap { try? JSONDecoder().decode(ApplicationToken.self, from: $0) })
    }

    func encodeCategoryTokens(_ tokens: Set<ActivityCategoryToken>) -> [Data] {
        tokens.compactMap { try? JSONEncoder().encode($0) }
    }

    func decodeCategoryTokens(_ dataList: [Data]) -> Set<ActivityCategoryToken> {
        Set(dataList.compactMap { try? JSONDecoder().decode(ActivityCategoryToken.self, from: $0) })
    }
}
