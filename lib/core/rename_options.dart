enum RenameMode {
  replace,
  append,
  prepend,
  numbering,
  extension,
  upper,
  lower,
  capitalize,
  insert,
  deleteStart,
  deleteEnd,
  deleteFrom,
  deleteFrontTo,
  deleteBackTo,
  extensionRemove,
  extensionAdd,
  extensionUpper,
  extensionLower,
  formatProperCase,
  listRename,
  appendDate,
  convHalfToFull,
  convFullToHalf,
  convFullKataToHira,
  convHiraToFullKata,
  convFullAlphaToHalfAlpha,
  convNumToHalf,
  changeTimestamp,
  changeAttributes,
}

enum DatePosition { front, back }

enum NumberingMode {
  stringNumber,
  originalNumber,
  numberString,
  numberOriginal,
  baseStringNumber,
  baseStringOriginal,
  relativeStringNumber,
  relativeStringOriginal,
  numberStringBase,
  numberStringRelative,
}

enum CaseConversion { none, upper, lower, capitalize }

enum ValidationType { auto, windows, mac, linux, ios, android }
