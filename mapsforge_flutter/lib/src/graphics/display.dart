/**
 * The enum Display governs whether map elements should be displayed.
 * <p/>
 * The main choice is
 * between IFSPACE which means an element is displayed if there is space for it (also depends on
 * priority), while ALWAYS means that an element will always be displayed (so it will be overlapped by
 * others and will not be part of the element placing algorithm). NEVER is a convenience fallback, which
 * means that an element will never be displayed.
 */

enum Display {
  NEVER,
  ALWAYS,
  IFSPACE,
}

// static Display fromString(String value) {
//  if ("never".equals(value)) {
//    return NEVER;
//  } else if (("always").equals(value)) {
//    return ALWAYS;
//  } else if (("ifspace").equals(value)) {
//    return IFSPACE;
//  }
//  throw new IllegalArgumentException("Invalid value for Display: " + value);
//}
