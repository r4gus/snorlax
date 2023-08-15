//! CouchDB Error Status

const StatusCodes = @import("StatusCodes.zig").StatusCodes;

/// Error type
@"error": StatusCodes,
/// Error string with extended reason
reason: []const u8,
