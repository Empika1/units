const std = @import("std");
const result = @import("result.zig");

pub fn satisfiesInterface(comptime interface: type, comptime implementer: type) result.Result {
    comptime {
        const iInfo = @typeInfo(interface);
        switch (iInfo) {
            .@"struct" => {},
            else => return .{ .No = std.fmt.comptimePrint("interface is not a struct type (is a {}).", .{std.meta.activeTag(iInfo)}) },
        }

        const cInfo = @typeInfo(implementer);
        switch (cInfo) {
            .@"struct" => {},
            else => return .{ .No = std.fmt.comptimePrint("implementer is not a struct type (is a {}).", .{std.meta.activeTag(cInfo)}) },
        }

        const iStruct = iInfo.@"struct";
        const cStruct = cInfo.@"struct";

        for (iStruct.fields) |iField| {
            var childHasField: bool = false;
            for (cStruct.fields) |cField| {
                if (std.mem.eql(u8, iField.name, cField.name)) {
                    if (iField.type != cField.type) {
                        return .{ .No = std.fmt.comptimePrint("implementer has no field that matches {s} in interface. type mismatch ({} in interface vs {} in implementer)", .{ iField.name, iField.type, cField.type }) };
                    }
                    if (iField.is_comptime != cField.is_comptime) {
                        return .{ .No = std.fmt.comptimePrint("implementer has no field that matches {s} in interface. comptime-ness mismatch ({s} in interface vs {s} in implementer)", .{
                            iField.name,
                            (if (iField.is_comptime)
                                "comptime"
                            else
                                "not comptime"),
                            (if (cField.is_comptime)
                                "comptime"
                            else
                                "not comptime"),
                        }) };
                    }
                    childHasField = true;
                    break;
                }
            }
            if (!childHasField) {
                return .{ .No = std.fmt.comptimePrint("implementer has no field that matches {s} in interface", .{iField.name}) };
            }
        }

        for (iStruct.decls) |iDecl| {
            const iDeclType = @TypeOf(@field(interface, iDecl.name));
            const iDeclIsConst = @typeInfo(@TypeOf(&@field(interface, iDecl.name))).pointer.is_const;

            var childHasDecl: bool = false;
            for (cStruct.decls) |cDecl| {
                const cDeclType = @TypeOf(@field(implementer, cDecl.name));
                const cDeclIsConst = @typeInfo(@TypeOf(&@field(implementer, cDecl.name))).pointer.is_const;

                if (std.mem.eql(u8, iDecl.name, cDecl.name)) {
                    if (iDeclType != cDeclType) {
                        return .{ .No = std.fmt.comptimePrint("implementer has no decl that matches {s} in interface. type mismatch ({} in interface vs {} in implementer)", .{ iDecl.name, iDeclType, cDeclType }) };
                    }
                    if (iDeclIsConst != cDeclIsConst) {
                        return .{ .No = std.fmt.comptimePrint("implementer has no decl that matches {s} in interface. constness mismatch ({s} in interface vs {s} in implementer)", .{
                            iDecl.name,
                            (if (iDeclIsConst)
                                "const"
                            else
                                "var"),
                            (if (cDeclIsConst)
                                "const"
                            else
                                "var"),
                        }) };
                    }
                    childHasDecl = true;
                    break;
                }
            }

            if (!childHasDecl) {
                return .{ .No = std.fmt.comptimePrint("implementer has no decl that matches {s} in interface", .{iDecl.name}) };
            }
        }

        return .{ .Yes = {} };
    }
}

pub fn assertInterface(comptime interface: type, comptime child: type) void {
    comptime {
        const res = satisfiesInterface(interface, child);
        switch (res) {
            .No => @compileError(res.No),
        }
    }
}
