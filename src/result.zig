pub const Result = union(enum) {
    Yes: void,
    No: []const u8,
};
