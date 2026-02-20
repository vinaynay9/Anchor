import Foundation

public enum Validation {
    public static func isValidBirthDate(month: Int, day: Int) -> Bool {
        switch month {
        case 4, 6, 9, 11:
            return day >= 1 && day <= 30
        case 2:
            return day >= 1 && day <= 29
        default:
            return day >= 1 && day <= 31
        }
    }

    public static func isValidDayString(_ value: String) -> Bool {
            let regex = /^\d{4}-\d{2}-\d{2}$/
            return value.wholeMatch(of: regex) != nil
        }

    public static func isValidTimeOfDay(_ value: String) -> Bool {
            let regex = /^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d$/
            return value.wholeMatch(of: regex) != nil
        }
}
