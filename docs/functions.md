# Paisley Standard Library Functions

## Arrays
- `all(list: array[any]) -> boolean`
  - Check if all elements in an array are truthy. This is identical to calling `reduce(..., and)`.
- `any(list: array[any]) -> boolean`
  - Check if any element in an array is truthy. This is identical to calling `reduce(..., or)`.
- `append(list: array[any], value: any) -> array[any]`
  - Append a value to an array.
- `chunk(list: array[any], chunk_size: number) -> array[array[any]]`
  - Split an array into chunks of a given size. The last chunk may be smaller than the given size if the array length is not a multiple of the chunk size.
- `delete(list: array[any], index: number) -> array[any]`
  - Delete an element from an array at the given index. If the index is out of bounds, the original array is returned.
- `flatten(list: array[any]) -> array[any]`
  - Flatten an array of any dimension into a 1D array. E.g. ((1, 2), (3, (4, 5))) -> (1, 2, 3, 4, 5).
- `insert(list: array[any], before_index: number, value: any) -> array[any]`
  - Insert an element in an array at the given index. If the index is out of bounds, then the value will either be added to the beginning or the end of the array.
- `interleave(list1: array[any], list2: array[any]) -> array[any]`
  - Interleave the values of two arrays. E.g. (1, 2, 3) and (4, 5, 6) -> (1, 4, 2, 5, 3, 6).
- `max(...: number|array[number]) -> number`
  - Find the maximum of a list of values.
- `merge(list1: array[any], list2: array[any]) -> array[any]`
  - Concatenate two arrays together.
- `min(...: number|array[number]) -> number`
  - Find the minimum of a list of values.
- `mult(...: number|array[number]) -> number`
  - Calculate the product of a list of values. This is identical to calling `reduce(..., *)`.
- `reduce(list: array[any], op: operator) -> any`
  - Reduce an array to a single element based on a repeated binary operation. Valid operators are: +, -, *, /, %, //, and, or, xor.
- `sort(list: array[any]) -> array[any]`
  - Sort an array in ascending order.
- `splice(list: array[any], start: number, end: number, replacement: array[any]) -> array[any]`
  - Remove or replace elements from an array.
- `sum(...: number|array[number]) -> number`
  - Calculate the sum of a list of values. This is identical to calling `reduce(..., +)`.
- `update(list: array[any], index: number, new_value: any) -> array[any]`
  - Replace an element in an array at the given index. If the index is out of bounds, the original array is returned.

### Sets
- `difference(set1: array[any], set2: array[any]) -> array[any]`
  - Get the difference of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.
- `intersection(set1: array[any], set2: array[any]) -> array[any]`
  - Get the intersection of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.
- `is_disjoint(set1: array[any], set2: array[any]) -> boolean`
  - Check if two sets are disjoint. Returns true if they have no elements in common.
- `is_subset(set1: array[any], set2: array[any]) -> boolean`
  - Check if the first set is a subset of the second. Returns true if all elements of the first set are in the second set.
- `is_superset(set1: array[any], set2: array[any]) -> boolean`
  - Check if the first set is a superset of the second. Returns true if all elements of the second set are in the first set.
- `symmetric_difference(set1: array[any], set2: array[any]) -> array[any]`
  - Get the symmetric difference of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.
- `union(set1: array[any], set2: array[any]) -> array[any]`
  - Get the union of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.
- `unique(list: array[any]) -> array[any]`
  - Remove duplicate values from an array. This function is most useful for creating a set, which can then be passed to other set operations.

### Vectors
- `dist(point1: number|array[number], point2: number|array[number]) -> number`
  - Get the euclidean distance between numbers or vectors of the same dimension
- `normalize(vector: array[number]) -> array[number]`
  - Normalize a vector to length 1. E.g. (3, 4) -> (0.6, 0.8).

## Characters
- `ascii(character: string) -> number`
  - Convert a character to its ASCII value. Only the first character is considered, all others are ignored.
- `bytes(value: number, b: number) -> array[number]`
  - Split a number into bytes. The number is interpreted as an unsigned 32-bit integer.
- `char(ascii_code: number) -> string`
  - Convert an ASCII number to a character. If outside of the range 0-255, an empty string is returned. Non-integers are rounded down.
- `frombytes(bytes: array[number]) -> number`
  - Convert a list of bytes into a number. The resultant number is constructed as an unsigned 32-bit integer.

## Encoding
- `b64_decode(text: string) -> string`
  - Convert base64 text to a string.
- `b64_encode(text: string) -> string`
  - Convert a string to base64.
- `json_decode(text: string) -> any`
  - Deserialize data from a JSON string.
- `json_encode(data: any [, b: boolean]) -> string`
  - Serialize data to a JSON string.
- `json_valid(text: any) -> boolean`
  - Check if a JSON string is formatted correctly.
- `xml_decode(text: string) -> array[object[any]]`
  - Deserialize data from an XML string.
- `xml_encode(data: array[object[any]]) -> string`
  - Serialize data to an XML string.

## Files
- `dir_create(dir_path: string [, create_parents: boolean]) -> boolean`
  - Create a directory. Returns true on success, or false if the directory could not be created. If create_parents is true, any missing parent directories will also be created.
- `dir_delete(dir_path: string [, recursive: boolean]) -> boolean`
  - Delete a directory. Returns true on success, or false if the directory could not be deleted. If recursive is true, all files and subdirectories will also be deleted.
- `dir_list(dir_path: string) -> array[string]`
  - List all files and directories in the given directory. If the directory does not exist, an empty array is returned.
- `file_append(file_path: string, data: string) -> boolean`
  - Append a string to the end of a file, creating it if it does not exist. Returns true on success, or false if the file could not be written.
- `file_copy(source_path: string, dest_path: string) -> boolean`
  - Copy a file from source_path to dest_path. If overwrite is true, any existing file at dest_path will be overwritten. Returns true on success, or false if the file could not be copied.
- `file_delete(file_path: string) -> boolean`
  - Delete a file. Returns true on success, or false if the file could not be deleted.
- `file_exists(file_path: string) -> boolean`
  - Check if a file exists at the given path.
- `file_glob(glob_pattern: string) -> array[string]`
  - List all files that match a glob pattern. E.g. `file_glob("*.txt")` -> ("file1.txt", "file2.txt"), depending on the files in your current directory.
- `file_move(source_path: string, dest_path: string) -> boolean`
  - Move a file from source_path to dest_path. If overwrite is true, any existing file at dest_path will be overwritten. Returns true on success, or false if the file could not be moved.
- `file_read(file_path: string) -> null|string`
  - Read the entire contents of a file as a string. If the file does not exist or cannot be read, null is returned.
- `file_size(file_path: string) -> number`
  - Get the size of a file in bytes. If the file does not exist, 0 is returned.
- `file_stat(file_path: string) -> null|object[any]`
  - Get information about a filesystem object. If the file does not exist, null is returned.
- `file_type(file_path: string) -> null|string`
  - Get the type of a file. Possible return values are "file", "directory", or "other". If the file does not exist, null is returned.
- `file_write(file_path: string, data: string) -> boolean`
  - Write a string to a file, overwriting it if it already exists. Returns true on success, or false if the file could not be written.

## Iterables
- `count(iter: array[any]|string, value: any|string) -> number`
  - Count the number of occurrences of a value in an array or string.
- `find(iterable: array[any]|string, value: any|string, occurrence: number) -> number`
  - Find the index of the nth occurrence of a value in an array or string.
- `index(iterable: array[any]|string, value: any|string) -> number`
  - Find the index of the first occurrence of a value in an array or string.
- `reverse(iter: array[any]|string) -> any`
  - Reverse an array or a string.

## Math
- `abs(x: number) -> number`
  - Get the absolute value of a number.
- `acos(x: number) -> number`
  - Calculate the arccosine of a number.
- `acot(x: number) -> number`
  - Calculate the arccotangent of a number.
- `acsc(x: number) -> number`
  - Calculate the arccosecant of a number.
- `asec(x: number) -> number`
  - Calculate the arcsecant of a number.
- `asin(x: number) -> number`
  - Calculate the arcsine of a number.
- `atan(x: number) -> number`
  - Calculate the arctangent of a number.
- `atan2(x: number, y: number) -> number`
  - Calculate the signed arctangent of y/x.
- `ceil(x: number) -> number`
  - Round up to the nearest integer.
- `clamp(value: number, min: number, max: number) -> number`
  - Keep a value inside the given range.
- `cos(x: number) -> number`
  - Calculate the cosine of a number.
- `cosh(x: number) -> number`
  - Calculate the hyperbolic cosine of a number.
- `cot(x: number) -> number`
  - Calculate the cotangent of a number.
- `csc(x: number) -> number`
  - Calculate the cosecant of a number.
- `floor(x: number) -> number`
  - Round down to the nearest integer.
- `lerp(ratio: number, start: number, end: number) -> number`
  - Linearly interpolate between two numbers.
- `log(base: number [, value: number]) -> number`
  - Calculate the logarithm of a number with a given base, or the natural logarithm if no base is provided.
- `modf(x: number) -> array[number]`
  - Split a number into its integer and fractional parts. E.g. 3.14 -> (3, 0.14).
- `round(x: number) -> number`
  - Round to the nearest integer.
- `sec(x: number) -> number`
  - Calculate the secant of a number.
- `sign(x: number) -> number`
  - Get the signedness of a number. returns -1 if negative, 0 if zero, 1 if positive.
- `sin(x: number) -> number`
  - Calculate the sine of a number.
- `sinh(x: number) -> number`
  - Calculate the hyperbolic sine of a number.
- `smoothstep(value: number, min: number, max: number) -> number`
  - Smoothly transition from 0 to 1 in a given range.
- `sqrt(x: number) -> number`
  - Calculate the square root of a number.
- `tan(x: number) -> number`
  - Calculate the tangent of a number.
- `tanh(x: number) -> number`
  - Calculate the hyperbolic tangent of a number.

## Miscellaneous
- `hash(text: string) -> string`
  - Generate the SHA256 hash of a string.
- `uuid() -> string`
  - Generate a universally unique identifier (UUID). See https://en.wikipedia.org/wiki/Universally_unique_identifier for more information.

## Objects
- `array(obj: object[any]) -> array[any]`
  - Convert an object into an array. The array will be a list of key-value pairs, e.g. {key1: value1, key2: value2, ...} -> (key1, value1, key2, value2, ...).
- `keys(obj: object[any]) -> array[string]`
  - List an object's keys.
- `object(list: array[any]) -> object[any]`
  - Convert an array into an object. The array is assumed to be a list of ordered key-value pairs, e.g. (key1, value1, key2, value2, ...) -> { key1: value1, key2: value2, ... }
- `pairs(data: object[any]|array[any]) -> array[any]`
  - Get a list of key-value pairs for an object or array. The output will be a list of 2-element lists, e.g. {key1: value1, key2: value2, ...} -> ((key1, value1), (key2, value2), ...).
- `values(obj: object[any]) -> array[any]`
  - List an object's values.

## Randomization
- `random_element(list: array[any]) -> any`
  - Select a random element from a list with uniform distribution.
- `random_elements(list: array[any], count: number) -> any`
  - Select non-repeating random elements from a list. If count is greater than the number of elements in the list, all elements will be returned in random order.
- `random_float(min: number, max: number) -> number`
  - Generate a random real number from min to max (inclusive) with uniform distribution.
- `random_int(min: number, max: number) -> number`
  - Generate a random integer from min to max (inclusive) with uniform distribution.
- `random_weighted(list: array[any], weights: array[number]) -> any`
  - Select a random element from a list according to a weight distribution. Weights will be normalized to sum to 1, so weights like (1, 2, 3) are fine and will be treated as (0.166, 0.333, 0.5); that is, the third element will be three times more likely to be selected than the first element.
- `shuffle(list: array[any]) -> array[any]`
  - Shuffle an array's elements into a random order. This is identical to calling random_elements with count set to the length of the array.

## Strings
- `beginswith(search: string, substring: string) -> boolean`
  - Check if the search string begins with the given substring.
- `camel(text: string) -> string`
  - Capitalize the first letter of every word.
- `endswith(search: string, substring: string) -> boolean`
  - Check if the search string ends with the given substring.
- `filter(text: string, valid_chars: string) -> string`
  - Remove all characters that do not match the given pattern.
- `from_base(text: string, base: number) -> number`
  - Convert a numeric string of any base from 2 to 36 into a number. E.g. "2A" in base 16 would be 42. If the string contains invalid characters, 0 is returned.
- `glob(...: string) -> array[string]`
  - Convert a glob pattern into a list of strings. E.g. `glob("a?*", "b", "c")` or `glob("a?*", ("b", "c"))` -> ("a?b", "a?c").
- `hex(value: number) -> string`
  - Convert a number to a hexadecimal string. This is identical to `to_base(value, 16, 0)`.
- `join(list: array[any], delim: string) -> string`
  - Join an array into a single string with a delimiter between elements.
- `lower(text: string) -> string`
  - Convert a string to lowercase.
- `lpad(text: string, pad_char: string, width: number) -> string`
  - Left-pad a string with a given character.
- `match(text: string, pattern: string) -> null|string`
  - Get the first substring that matches the given pattern. If no match is found, null is returned.
- `matches(text: string, pattern: string) -> array[string]`
  - Get all substrings that match the given pattern.
- `replace(text: string, search: string, replace: string) -> string`
  - Replace all occurrences of a substring.
- `rpad(text: string, pad_char: string, width: number) -> string`
  - Right-pad a string with a given character.
- `split(text: string, delim: string) -> array[string]`
  - Split a string into an array based on a delimiter. If the delimiter is an empty string, the string is split into individual characters.
- `to_base(number: number, base: number, pad_width: number) -> string`
  - Convert a number to a numeric string of any base from 2 to 36. Optionally pad the string with leading zeros to a given width. E.g. 42 in base 16 with padding of 4 would be "002A".
- `trim(text: string [, chars: string]) -> string`
  - Remove any of the given characters from the beginning and end of a string. If chars is not provided, any whitespace will be removed.
- `upper(text: string) -> string`
  - Convert a string to uppercase.
- `word_diff(word1: string, word2: string) -> number`
  - Get the levenshtein difference between two strings. See https://en.wikipedia.org/wiki/Levenshtein_distance for more information.

## Time
- `clocktime(timestamp: number) -> array[number]`
  - Convert a "seconds since midnight" timestamp into (hour, min, sec, milli).
- `date(date_array: array[number]) -> string`
  - Convert an array representation of a date (day, month, year) into an ISO compliant date string.
- `epochnow() -> number`
  - Get the current epoch time (seconds since Jan 1, 1970).
- `fromepoch(timestamp: number) -> object[any]`
  - Convert epoch time (seconds since Jan 1, 1970) to a datetime object. The datetime object will have the following form: { date: (day, month, year), time: (hour, min, sec) }.
- `time(timestamp: number|array[number]) -> string`
  - Convert a number or array representation of a time (timestamp OR [hour, min, sec, milli]) into an ISO compliant time string.
- `toepoch(datetime: object[any]) -> number`
  - Convert a datetime object to epoch time (seconds since Jan 1, 1970). The datetime object is expected to have the following form: { date: (day, month, year), time: (hour, min, sec) }.

## Types
- `bool(data: any) -> boolean`
  - Convert a value to a boolean. Returns false for null, 0, empty strings, empty arrays, and empty objects. All other values return true.
- `int(data: any) -> number`
  - Convert a value to an integer. Converts a value to a number, then floors it.
- `num(data: any) -> number`
  - Convert a value to a number. Returns 1 for true, and if a string is numeric, returns the number. All other non-number values return 0.
- `str(data: any) -> string`
  - Convert a value to a string. Null is converted to an empty string, and booleans are converted to a 1 or 0. Arrays are joined into a space-separated list like "value1 value2 etc", and objects are joined in a similar fashion e.g. "key1 value1 key2 value2 etc".
- `type(data: any) -> string`
  - Get the data type of a value. Possible return values are "number", "string", "boolean", "null", "array" or "object".

