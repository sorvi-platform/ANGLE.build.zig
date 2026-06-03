const std = @import("std");

const not_std = struct {
    pub fn once(comptime f: fn () void) Once(f) {
        return Once(f){};
    }

    /// An object that executes the function `f` just once.
    /// It is undefined behavior if `f` re-enters the same Once instance.
    pub fn Once(comptime f: fn () void) type {
        return struct {
            done: bool = false,
            mutex: std.Io.Mutex = .init,

            /// Call the function `f`.
            /// If `call` is invoked multiple times `f` will be executed only the
            /// first time.
            /// The invocations are thread-safe.
            pub fn call(self: *@This()) void {
                if (@atomicLoad(bool, &self.done, .acquire))
                    return;

                return self.callSlow();
            }

            fn callSlow(self: *@This()) void {
                @branchHint(.cold);

                const io = std.Io.Threaded.global_single_threaded.io();
                self.mutex.lockUncancelable(io);
                defer self.mutex.unlock(io);

                // The first thread to acquire the mutex gets to run the initializer
                if (!self.done) {
                    f();
                    @atomicStore(bool, &self.done, true, .release);
                }
            }
        };
    }
};

fn SoWrapper(FNS: type, paths: []const [:0]const u8) type {
    return struct {
        var _impl: FNS = undefined;
        var _once = if (@hasDecl(std, "once")) std.once(once) else not_std.once(once);

        fn once() void {
            var so: ?*anyopaque = null;
            for (paths) |path| {
                so = std.c.dlopen(path.ptr, .{ .NOW = true, .GLOBAL = true });
                if (so != null) break;
            }
            if (so == null) std.debug.panic("failed to load {s}", .{paths[0]});
            inline for (std.meta.fields(FNS)) |field| {
                @field(_impl, field.name) = @ptrCast(std.c.dlsym(so, field.name) orelse std.debug.panic("could not resolve: {s}", .{field.name}));
            }
        }

        pub fn get() *const FNS {
            _once.call();
            return &_impl;
        }
    };
}

const X11 = SoWrapper(struct {
    XOpenDisplay: *const fn ([*:0]const u8) ?*anyopaque,
    XCloseDisplay: *const fn (?*anyopaque) c_int,
    XFree: *const fn (?*anyopaque) c_int,
    _XGetRequest: *const fn (?*anyopaque, u8, usize) ?*anyopaque,
    _XReply: *const fn (?*anyopaque, ?*anyopaque, c_int, c_int) c_int,
    _XRead: *const fn (?*anyopaque, ?[*]const u8, c_long) c_int,
    _XEatData: *const fn (?*anyopaque, c_ulong) void,
    _XSend: *const fn (?*anyopaque, ?[*]const u8, c_long) void,
    _XSetLastRequestRead: *const fn (?*anyopaque, ?*anyopaque) c_ulong,
}, &.{
    "libX11.so.6",
    "libX11.so",
});

export fn XOpenDisplay(display_name: [*:0]const u8) ?*anyopaque {
    return X11.get().XOpenDisplay(display_name);
}

export fn XCloseDisplay(dpy: ?*anyopaque) c_int {
    return X11.get().XCloseDisplay(dpy);
}

export fn XFree(data: ?*anyopaque) c_int {
    return X11.get().XFree(data);
}

export fn _XGetRequest(dpy: ?*anyopaque, kind: u8, len: usize) ?*anyopaque {
    return X11.get()._XGetRequest(dpy, kind, len);
}

export fn _XReply(dpy: ?*anyopaque, reply: ?*anyopaque, extra: c_int, discard: c_int) c_int {
    return X11.get()._XReply(dpy, reply, extra, discard);
}

export fn _XRead(dpy: ?*anyopaque, data: ?[*]const u8, size: c_long) c_int {
    return X11.get()._XRead(dpy, data, size);
}

export fn _XEatData(dpy: ?*anyopaque, size: c_ulong) void {
    return X11.get()._XEatData(dpy, size);
}

export fn _XSend(dpy: ?*anyopaque, data: ?[*]const u8, size: c_long) void {
    return X11.get()._XSend(dpy, data, size);
}

export fn _XSetLastRequestRead(dpy: ?*anyopaque, rep: ?*anyopaque) c_ulong {
    return X11.get()._XSetLastRequestRead(dpy, rep);
}

const Xext = SoWrapper(struct {
    XextFindDisplay: *const fn (?*anyopaque, ?*anyopaque) ?*anyopaque,
    XextAddDisplay: *const fn (?*anyopaque, ?*anyopaque, ?[*:0]const u8, ?*anyopaque, c_int, ?*anyopaque) ?*anyopaque,
    XextRemoveDisplay: *const fn (?*anyopaque, ?*anyopaque) c_int,
    XMissingExtension: *const fn (?*anyopaque, ?[*:0]const u8) c_int,
}, &.{
    "libXext.so.6",
    "libXext.so",
});

export fn XextFindDisplay(extinfo: ?*anyopaque, dpy: ?*anyopaque) ?*anyopaque {
    return Xext.get().XextFindDisplay(extinfo, dpy);
}

export fn XextAddDisplay(extinfo: ?*anyopaque, dpy: ?*anyopaque, ext_name: [*:0]const u8, hooks: ?*anyopaque, nevents: c_int, data: ?*anyopaque) ?*anyopaque {
    return Xext.get().XextAddDisplay(extinfo, dpy, ext_name, hooks, nevents, data);
}

export fn XextRemoveDisplay(extinfo: ?*anyopaque, dpy: ?*anyopaque) c_int {
    return Xext.get().XextRemoveDisplay(extinfo, dpy);
}

export fn XMissingExtension(dpy: ?*anyopaque, ext_name: [*:0]const u8) c_int {
    return Xext.get().XMissingExtension(dpy, ext_name);
}

// This stuff isn't really neccessary, but SDL is kinda L and does not support pure
// EGL window on X11, thus we expose GLX wrappers
//
// To actually use ANGLE with SDL on X11, set SDL_VIDEO_FORCE_EGL=1
// Wayland uses EGL properly, so don't have to do anything there
const GLX = SoWrapper(struct {
    glXQueryExtension: *const fn (?*anyopaque, *c_int, *c_int) c_int,
    glXChooseVisual: *const fn (?*anyopaque, c_int, *c_int) ?*anyopaque,
    glXCreateContext: *const fn (?*anyopaque, ?*anyopaque, ?*anyopaque, c_int) ?*anyopaque,
    glXDestroyContext: *const fn (?*anyopaque, ?*anyopaque) void,
    glXMakeCurrent: *const fn (?*anyopaque, ?*anyopaque, ?*anyopaque) c_int,
    glXSwapBuffers: *const fn (?*anyopaque, ?*anyopaque) void,
}, &.{
    "libGL.so.6",
    "libGL.so",
});

export fn glXQueryExtension(dpy: ?*anyopaque, error_base: *c_int, event_base: *c_int) c_int {
    return GLX.get().glXQueryExtension(dpy, error_base, event_base);
}

export fn glXChooseVisual(dpy: ?*anyopaque, screen: c_int, attrib_list: *c_int) ?*anyopaque {
    return GLX.get().glXChooseVisual(dpy, screen, attrib_list);
}

export fn glXCreateContext(dpy: ?*anyopaque, vis: ?*anyopaque, share_list: ?*anyopaque, direct: c_int) ?*anyopaque {
    return GLX.get().glXCreateContext(dpy, vis, share_list, direct);
}

export fn glXDestroyContext(dpy: ?*anyopaque, ctx: ?*anyopaque) void {
    return GLX.get().glXDestroyContext(dpy, ctx);
}

export fn glXMakeCurrent(dpy: ?*anyopaque, drawable: ?*anyopaque, ctx: ?*anyopaque) c_int {
    return GLX.get().glXMakeCurrent(dpy, drawable, ctx);
}

export fn glXSwapBuffers(dpy: ?*anyopaque, drawable: ?*anyopaque) void {
    return GLX.get().glXSwapBuffers(dpy, drawable);
}
