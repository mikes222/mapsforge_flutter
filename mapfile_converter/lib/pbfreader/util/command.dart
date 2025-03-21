/// Representation for commands used to encode/decode geometry coordinates
class CommandID {
  static final int MoveTo = 1;
  static final int LineTo = 2;
  static final int ClosePath = 7;
}

/// Command and its utils
class Command {
  int id;
  int count;

  Command({required this.id, required this.count});

  factory Command.CommandInteger({required int command}) {
    return Command(
      id: command & 0x7,
      count: command >> 3,
    );
  }

  static int zigZagEncode(int val) {
    return (val << 1) ^ (val >> 31);
  }

  static int zigZagDecode(int parameterInteger) {
    return ((parameterInteger >> 1) ^ (-(parameterInteger & 1)));
  }
}
