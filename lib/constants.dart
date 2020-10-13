/// Seconds per microsecond
const SECONDS_PER_US = 1 / 1000000;

/// The size of the event buffer in the native backend
const BUFFER_SIZE = 1024;

/// Interval to "top off" each track's buffer, in milliseconds
const TOP_OFF_PERIOD_MS = 1000;

/// "Lead frames" account for the fact that it may take some time to build the
/// events and sync them with the native sequencer engine.
const LEAD_FRAMES = 1024;
