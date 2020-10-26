Stream<T> futureIntoStream<T>(Future<Stream<T>> streamFuture) {
  return Stream.fromFuture(streamFuture).asyncExpand((event) => event);
}

class Dimension extends Comparable<Dimension> {
  int width;
  int height;

  Dimension(this.width, this.height);

  int size() => width * height;

  @override
  String toString() {
    return "$width x $height";
  }

  @override
  int compareTo(Dimension other) {
    return size() - other.size();
  }
}

// Returns a sorted copy of a list instead of sorting the list itself
List<T> listSort<T>(List<T> list, int Function(T, T) compare) {
  list.sort(compare);
  return list;
}

Future<T> retry<T>(Future<T> Function() futureBuilder, int times) async {
  var error;
  for (; times > 0; times--) {
    try {
      return await futureBuilder();
    } catch (e) {
      error = e;
    }
  }
  throw error;
}

final _durationRegex = RegExp(
    "^([0-9]{1,2}):([0-9]{2}):([0-9]{2})\\.([0-9]{2})([0-9]{2})([0-9]{2})\$");

Duration parseDuration(String durationString) {
  var match = _durationRegex.firstMatch(durationString);
  if (match == null) {
    throw FormatException(
      "The date string was of invalid format",
      durationString,
    );
  }
  return Duration(
    days: int.parse(match.group(1)),
    hours: int.parse(match.group(2)),
    minutes: int.parse(match.group(3)),
    seconds: int.parse(match.group(4)),
    milliseconds: int.parse(match.group(5)),
    microseconds: int.parse(match.group(6)),
  );
}
