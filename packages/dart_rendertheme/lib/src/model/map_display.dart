/// The enum Display governs whether map elements should be displayed.
/// <p/>
/// The main choice is
/// between IFSPACE which means an element is displayed if there is space for it (also depends on
/// priority), while ALWAYS means that an element will always be displayed (so it will be overlapped by
/// others and will not be part of the element placing algorithm). NEVER is a convenience fallback, which
/// means that an element will never be displayed.
enum MapDisplay { NEVER, ALWAYS, IFSPACE }
