/// Status Codes
pub const StatusCodes = enum(u16) {
    /// Request completed successfully.
    ok = 200,
    /// Document created successfully.
    created = 201,
    /// Request has been accepted, but the corresponding operation may not have completed.
    /// This is used for background operations, such as database compaction.
    accepted = 202,
    /// The additional content requested has not been modified. This is used with the ETag
    /// system to identify the version of information returned.
    not_modified = 304,
    /// Bad request structure. The error can indicate an error with the request URL, path
    /// or headers. Differences in the supplied MD5 hash and content also trigger this error,
    /// as this may indicate message corruption.
    bad_request = 400,
    /// The item requested was not available using the supplied authorization, or authorization
    /// was not supplied.
    unauthorized = 401,
    /// The requested item or operation is forbidden.
    forbidden = 403,
    /// The requested content could not be found.
    not_found = 404,
    /// A request was made using an invalid HTTP request type for the URL requested. For example,
    /// you have requested a `PUT` when a `POST` is required. Errors of this type can also triggered
    /// by invalid URL strings.
    method_not_allowed = 405,
    /// The requested content type is not supported by the server.
    not_acceptable = 406,
    /// Request resulted in an update conflict.
    conflict = 409,
    /// The request headers from the client and the capabilities of the server do not match.
    precondition_failed = 412,
    /// A document exceeds the configured `couchdb/max_document_size` value or the entire
    /// request exceeds the `chttpd/max_http_request_size` value.
    request_entity_too_large = 413,
    /// The content types supported, and the content type of the information being requested
    /// or submitted indicate that the content type is not supported.
    unsupported_media_type = 415,
    /// The range specified in the request header cannot be satisfied by the server.
    requested_range_not_satisfiable = 416,
    /// When sending documents in bulk, the bulk load operation failed.
    expectation_failed = 417,
    /// The request was invalid, either because the supplied JSON was invalid, or invalid
    /// information was supplied as part of the request.
    internal_server_error = 500,
    /// The request can’t be serviced at this time, either because the cluster is overloaded,
    /// maintenance is underway, or some other reason. The request may be retried without
    /// changes, perhaps in a couple of minutes.
    service_unavailable = 503,
};
