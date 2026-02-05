const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link mode for library artifacts") orelse .static;

    const angle_dep = b.dependency("angle", .{});

    const zlib_dep = b.dependency("zlib", .{
        .target = target,
        .optimize = optimize,
    });

    const astc_dep = b.dependency("astc-encoder", .{});
    const glslang_dep = b.dependency("glslang", .{});

    var angle_def: std.ArrayListUnmanaged([]const u8) = .empty;
    var angle_src: std.ArrayListUnmanaged([]const u8) = .empty;
    var angle_csrc: std.ArrayListUnmanaged([]const u8) = .empty;
    var angle_objc: std.ArrayListUnmanaged([]const u8) = .empty;
    var angle_frameworks: std.ArrayListUnmanaged([]const u8) = .empty;
    var angle_libs: std.ArrayListUnmanaged([]const u8) = .empty;
    var angle_incl: std.ArrayListUnmanaged(std.Build.LazyPath) = .empty;
    var glslang_def: std.ArrayListUnmanaged([]const u8) = .empty;
    var glslang_src: std.ArrayListUnmanaged([]const u8) = .empty;
    switch (target.result.os.tag) {
        .linux => {
            if (b.lazyDependency("vulkan-headers", .{})) |dep| {
                try angle_incl.append(b.allocator, dep.path("include"));
            }
            if (b.lazyDependency("spirv-headers", .{})) |dep| {
                try angle_incl.append(b.allocator, dep.path("include"));
            }
            if (b.lazyDependency("spirv-tools", .{})) |dep| {
                try angle_incl.append(b.allocator, dep.path("include"));
            }
            if (b.lazyDependency("vulkan-memory-allocator", .{})) |dep| {
                try angle_incl.append(b.allocator, dep.path("include"));
            }
            try angle_incl.append(b.allocator, angle_dep.path("src/third_party/volk"));
            switch (target.result.abi) {
                .android, .androideabi => {
                    // NOTE: I haven't actually tested android
                    try angle_def.appendSlice(b.allocator, &.{
                        "-DANDROID",
                        "-DANGLE_USE_ANDROID_TLS_SLOT=1",
                        "-DVK_USE_PLATFORM_ANDROID_KHR",
                    });
                    try angle_src.appendSlice(b.allocator, &.{
                        "src/common/backtrace_utils_noop.cpp",
                        "src/gpu_info_util/SystemInfo_android.cpp",
                        "src/libANGLE/renderer/vulkan/android/AHBFunctions.cpp",
                        "src/libANGLE/renderer/vulkan/android/DisplayVkAndroid.cpp",
                        "src/libANGLE/renderer/vulkan/android/HardwareBufferImageSiblingVkAndroid.cpp",
                        "src/libANGLE/renderer/vulkan/android/WindowSurfaceVkAndroid.cpp",
                        "src/libANGLE/renderer/gl/egl/android/DisplayAndroid.cpp",
                        "src/libANGLE/renderer/gl/egl/android/NativeBufferImageSiblingAndroid.cpp",
                    });
                },
                else => {
                    try angle_incl.append(b.allocator, b.path("src/linux/include"));
                    try angle_def.appendSlice(b.allocator, &.{
                        "-D__linux__",
                        "-DGPU_INFO_USE_LIBPCI",
                        "-DGPU_INFO_USE_X11",
                        "-DVK_USE_PLATFORM_WAYLAND_KHR",
                        "-DVK_USE_PLATFORM_XCB_KHR",
                    });
                    try angle_csrc.appendSlice(b.allocator, &.{
                        "src/third_party/libXNVCtrl/NVCtrl.c",
                    });
                    try angle_src.appendSlice(b.allocator, &.{
                        "src/gpu_info_util/SystemInfo_linux.cpp",
                        "src/gpu_info_util/SystemInfo_libpci.cpp",
                        "src/gpu_info_util/SystemInfo_x11.cpp",
                        "src/common/linux/dma_buf_utils.cpp",
                        "src/libANGLE/renderer/vulkan/linux/DeviceVkLinux.cpp",
                        "src/libANGLE/renderer/vulkan/linux/DisplayVkLinux.cpp",
                        "src/libANGLE/renderer/vulkan/linux/DisplayVkOffscreen.cpp",
                        "src/libANGLE/renderer/vulkan/linux/DmaBufImageSiblingVkLinux.cpp",
                        "src/libANGLE/renderer/vulkan/linux/display/DisplayVkSimple.cpp",
                        "src/libANGLE/renderer/vulkan/linux/display/WindowSurfaceVkSimple.cpp",
                        "src/libANGLE/renderer/vulkan/linux/headless/DisplayVkHeadless.cpp",
                        "src/libANGLE/renderer/vulkan/linux/headless/WindowSurfaceVkHeadless.cpp",
                        "src/libANGLE/renderer/vulkan/linux/xcb/DisplayVkXcb.cpp",
                        "src/libANGLE/renderer/vulkan/linux/xcb/WindowSurfaceVkXcb.cpp",
                        "src/libANGLE/renderer/vulkan/linux/wayland/DisplayVkWayland.cpp",
                        "src/libANGLE/renderer/vulkan/linux/wayland/WindowSurfaceVkWayland.cpp",
                        "src/libANGLE/renderer/vulkan/linux/gbm/DisplayVkGbm.cpp",
                        "src/libANGLE/renderer/gl/glx/DisplayGLX.cpp",
                        "src/libANGLE/renderer/gl/glx/FunctionsGLX.cpp",
                        "src/libANGLE/renderer/gl/glx/PbufferSurfaceGLX.cpp",
                        "src/libANGLE/renderer/gl/glx/PixmapSurfaceGLX.cpp",
                        "src/libANGLE/renderer/gl/glx/WindowSurfaceGLX.cpp",
                        "src/libANGLE/renderer/gl/glx/glx_utils.cpp",
                    });
                },
            }
            try angle_def.appendSlice(b.allocator, &.{
                "-DVMA_IMPLEMENTATION",
                "-DANGLE_SHARED_LIBVULKAN",
                "-DANGLE_ENABLE_VULKAN",
                "-DANGLE_ENABLE_OPENGL",
                "-DANGLE_USE_VULKAN_SYSTEM_INFO",
                "-DANGLE_VK_MOCK_ICD_JSON=\"\"",
            });
            try angle_csrc.appendSlice(b.allocator, &.{
                "src/third_party/volk/volk.c",
            });
            try angle_src.appendSlice(b.allocator, &.{
                "src/gpu_info_util/SystemInfo_vulkan.cpp",
                "src/common/system_utils_linux.cpp",
                "src/common/system_utils_posix.cpp",
                "src/libANGLE/renderer/gl/BlitGL.cpp",
                "src/libANGLE/renderer/gl/BufferGL.cpp",
                "src/libANGLE/renderer/gl/ClearMultiviewGL.cpp",
                "src/libANGLE/renderer/gl/CompilerGL.cpp",
                "src/libANGLE/renderer/gl/ContextGL.cpp",
                "src/libANGLE/renderer/gl/DispatchTableGL_autogen.cpp",
                "src/libANGLE/renderer/gl/DisplayGL.cpp",
                "src/libANGLE/renderer/gl/FenceNVGL.cpp",
                "src/libANGLE/renderer/gl/FramebufferGL.cpp",
                "src/libANGLE/renderer/gl/FunctionsGL.cpp",
                "src/libANGLE/renderer/gl/ImageGL.cpp",
                "src/libANGLE/renderer/gl/MemoryObjectGL.cpp",
                "src/libANGLE/renderer/gl/ProgramExecutableGL.cpp",
                "src/libANGLE/renderer/gl/ProgramGL.cpp",
                "src/libANGLE/renderer/gl/ProgramPipelineGL.cpp",
                "src/libANGLE/renderer/gl/QueryGL.cpp",
                "src/libANGLE/renderer/gl/RenderbufferGL.cpp",
                "src/libANGLE/renderer/gl/RendererGL.cpp",
                "src/libANGLE/renderer/gl/SamplerGL.cpp",
                "src/libANGLE/renderer/gl/SemaphoreGL.cpp",
                "src/libANGLE/renderer/gl/ShaderGL.cpp",
                "src/libANGLE/renderer/gl/StateManagerGL.cpp",
                "src/libANGLE/renderer/gl/SurfaceGL.cpp",
                "src/libANGLE/renderer/gl/SyncGL.cpp",
                "src/libANGLE/renderer/gl/TextureGL.cpp",
                "src/libANGLE/renderer/gl/TransformFeedbackGL.cpp",
                "src/libANGLE/renderer/gl/VertexArrayGL.cpp",
                "src/libANGLE/renderer/gl/formatutilsgl.cpp",
                "src/libANGLE/renderer/gl/renderergl_utils.cpp",
                "src/libANGLE/renderer/gl/egl/ContextEGL.cpp",
                "src/libANGLE/renderer/gl/egl/DeviceEGL.cpp",
                "src/libANGLE/renderer/gl/egl/DisplayEGL.cpp",
                "src/libANGLE/renderer/gl/egl/DmaBufImageSiblingEGL.cpp",
                "src/libANGLE/renderer/gl/egl/FunctionsEGL.cpp",
                "src/libANGLE/renderer/gl/egl/FunctionsEGLDL.cpp",
                "src/libANGLE/renderer/gl/egl/ImageEGL.cpp",
                "src/libANGLE/renderer/gl/egl/PbufferSurfaceEGL.cpp",
                "src/libANGLE/renderer/gl/egl/RendererEGL.cpp",
                "src/libANGLE/renderer/gl/egl/SurfaceEGL.cpp",
                "src/libANGLE/renderer/gl/egl/SyncEGL.cpp",
                "src/libANGLE/renderer/gl/egl/WindowSurfaceEGL.cpp",
                "src/libANGLE/renderer/gl/egl/egl_utils.cpp",
                "src/common/vulkan/libvulkan_loader.cpp",
                "src/common/vulkan/vulkan_icd.cpp",
                "src/common/spirv/angle_spirv_utils.cpp",
                "src/common/spirv/spirv_instruction_builder_autogen.cpp",
                "src/common/spirv/spirv_instruction_parser_autogen.cpp",
                "src/libANGLE/renderer/vulkan/vk_mem_alloc_wrapper.cpp",
                "src/libANGLE/renderer/vulkan/AllocatorHelperPool.cpp",
                "src/libANGLE/renderer/vulkan/BufferVk.cpp",
                "src/libANGLE/renderer/vulkan/CommandQueue.cpp",
                "src/libANGLE/renderer/vulkan/CompilerVk.cpp",
                "src/libANGLE/renderer/vulkan/ContextVk.cpp",
                "src/libANGLE/renderer/vulkan/DebugAnnotatorVk.cpp",
                "src/libANGLE/renderer/vulkan/DeviceVk.cpp",
                "src/libANGLE/renderer/vulkan/DisplayVk.cpp",
                "src/libANGLE/renderer/vulkan/FenceNVVk.cpp",
                "src/libANGLE/renderer/vulkan/FramebufferVk.cpp",
                "src/libANGLE/renderer/vulkan/ImageVk.cpp",
                "src/libANGLE/renderer/vulkan/MemoryObjectVk.cpp",
                "src/libANGLE/renderer/vulkan/MemoryTracking.cpp",
                "src/libANGLE/renderer/vulkan/OverlayVk.cpp",
                "src/libANGLE/renderer/vulkan/PersistentCommandPool.cpp",
                "src/libANGLE/renderer/vulkan/ProgramExecutableVk.cpp",
                "src/libANGLE/renderer/vulkan/ProgramPipelineVk.cpp",
                "src/libANGLE/renderer/vulkan/ProgramVk.cpp",
                "src/libANGLE/renderer/vulkan/QueryVk.cpp",
                "src/libANGLE/renderer/vulkan/RenderTargetVk.cpp",
                "src/libANGLE/renderer/vulkan/RenderbufferVk.cpp",
                "src/libANGLE/renderer/vulkan/SamplerVk.cpp",
                "src/libANGLE/renderer/vulkan/SecondaryCommandBuffer.cpp",
                "src/libANGLE/renderer/vulkan/SecondaryCommandPool.cpp",
                "src/libANGLE/renderer/vulkan/SemaphoreVk.cpp",
                "src/libANGLE/renderer/vulkan/ShaderInterfaceVariableInfoMap.cpp",
                "src/libANGLE/renderer/vulkan/ShaderVk.cpp",
                "src/libANGLE/renderer/vulkan/ShareGroupVk.cpp",
                "src/libANGLE/renderer/vulkan/Suballocation.cpp",
                "src/libANGLE/renderer/vulkan/SurfaceVk.cpp",
                "src/libANGLE/renderer/vulkan/SyncVk.cpp",
                "src/libANGLE/renderer/vulkan/TextureVk.cpp",
                "src/libANGLE/renderer/vulkan/TransformFeedbackVk.cpp",
                "src/libANGLE/renderer/vulkan/UtilsVk.cpp",
                "src/libANGLE/renderer/vulkan/VertexArrayVk.cpp",
                "src/libANGLE/renderer/vulkan/VkImageImageSiblingVk.cpp",
                "src/libANGLE/renderer/vulkan/VulkanSecondaryCommandBuffer.cpp",
                "src/libANGLE/renderer/vulkan/android/vk_android_utils.cpp",
                "src/libANGLE/renderer/vulkan/spv_utils.cpp",
                "src/libANGLE/renderer/vulkan/vk_barrier_data.cpp",
                "src/libANGLE/renderer/vulkan/vk_cache_utils.cpp",
                "src/libANGLE/renderer/vulkan/vk_caps_utils.cpp",
                "src/libANGLE/renderer/vulkan/vk_command_buffer_utils.h",
                "src/libANGLE/renderer/vulkan/vk_format_table_autogen.cpp",
                "src/libANGLE/renderer/vulkan/vk_format_utils.cpp",
                "src/libANGLE/renderer/vulkan/vk_helpers.cpp",
                "src/libANGLE/renderer/vulkan/vk_internal_shaders_autogen.cpp",
                "src/libANGLE/renderer/vulkan/vk_mandatory_format_support_table_autogen.cpp",
                "src/libANGLE/renderer/vulkan/vk_ref_counted_event.cpp",
                "src/libANGLE/renderer/vulkan/vk_renderer.cpp",
                "src/libANGLE/renderer/vulkan/vk_resource.cpp",
                "src/libANGLE/renderer/vulkan/vk_utils.cpp",
                "src/compiler/translator/spirv/BuildSPIRV.cpp",
                "src/compiler/translator/spirv/BuiltinsWorkaround.cpp",
                "src/compiler/translator/spirv/OutputSPIRV.cpp",
                "src/compiler/translator/spirv/TranslatorSPIRV.cpp",
                "src/compiler/translator/tree_ops/spirv/ClampGLLayer.cpp",
                "src/compiler/translator/tree_ops/spirv/EmulateAdvancedBlendEquations.cpp",
                "src/compiler/translator/tree_ops/spirv/EmulateDithering.cpp",
                "src/compiler/translator/tree_ops/spirv/EmulateFragColorData.cpp",
                "src/compiler/translator/tree_ops/spirv/EmulateFramebufferFetch.cpp",
                "src/compiler/translator/tree_ops/spirv/EmulateYUVBuiltIns.cpp",
                "src/compiler/translator/tree_ops/spirv/FlagSamplersWithTexelFetch.cpp",
                "src/compiler/translator/tree_ops/spirv/ReswizzleYUVOps.cpp",
                "src/compiler/translator/tree_ops/spirv/RewriteInterpolateAtOffset.cpp",
                "src/compiler/translator/tree_ops/spirv/RewriteR32fImages.cpp",
                "src/compiler/translator/tree_ops/spirv/RewriteSamplerExternalTexelFetch.cpp",
            });
            try glslang_def.appendSlice(b.allocator, &.{
                "-DGLSLANG_OSINCLUDE_UNIX",
            });
            try glslang_src.appendSlice(b.allocator, &.{
                "glslang/OSDependent/Unix/ossource.cpp",
            });
        },
        .macos, .ios, .tvos, .watchos, .visionos => |os| {
            try angle_def.appendSlice(b.allocator, &.{
                "-D__APPLE__",
                "-DANGLE_ENABLE_METAL",
            });
            try angle_objc.appendSlice(b.allocator, &.{
                "src/common/apple_platform_utils.mm",
                "src/libANGLE/renderer/metal/BufferMtl.mm",
                "src/libANGLE/renderer/metal/CompilerMtl.mm",
                "src/libANGLE/renderer/metal/ContextMtl.mm",
                "src/libANGLE/renderer/metal/DeviceMtl.mm",
                "src/libANGLE/renderer/metal/DisplayMtl.mm",
                "src/libANGLE/renderer/metal/FrameBufferMtl.mm",
                "src/libANGLE/renderer/metal/IOSurfaceSurfaceMtl.mm",
                "src/libANGLE/renderer/metal/ImageMtl.mm",
                "src/libANGLE/renderer/metal/ProgramExecutableMtl.mm",
                "src/libANGLE/renderer/metal/ProgramMtl.mm",
                "src/libANGLE/renderer/metal/ProvokingVertexHelper.mm",
                "src/libANGLE/renderer/metal/QueryMtl.mm",
                "src/libANGLE/renderer/metal/RenderBufferMtl.mm",
                "src/libANGLE/renderer/metal/RenderTargetMtl.mm",
                "src/libANGLE/renderer/metal/SamplerMtl.mm",
                "src/libANGLE/renderer/metal/ShaderMtl.mm",
                "src/libANGLE/renderer/metal/SurfaceMtl.mm",
                "src/libANGLE/renderer/metal/SyncMtl.mm",
                "src/libANGLE/renderer/metal/TextureMtl.mm",
                "src/libANGLE/renderer/metal/TransformFeedbackMtl.mm",
                "src/libANGLE/renderer/metal/VertexArrayMtl.mm",
                "src/libANGLE/renderer/metal/mtl_buffer_manager.mm",
                "src/libANGLE/renderer/metal/mtl_buffer_pool.mm",
                "src/libANGLE/renderer/metal/mtl_command_buffer.mm",
                "src/libANGLE/renderer/metal/mtl_common.mm",
                "src/libANGLE/renderer/metal/mtl_context_device.mm",
                "src/libANGLE/renderer/metal/mtl_format_table_autogen.mm",
                "src/libANGLE/renderer/metal/mtl_format_utils.mm",
                "src/libANGLE/renderer/metal/mtl_library_cache.mm",
                "src/libANGLE/renderer/metal/mtl_msl_utils.mm",
                "src/libANGLE/renderer/metal/mtl_occlusion_query_pool.mm",
                "src/libANGLE/renderer/metal/mtl_pipeline_cache.mm",
                "src/libANGLE/renderer/metal/mtl_render_utils.mm",
                "src/libANGLE/renderer/metal/mtl_resources.mm",
                "src/libANGLE/renderer/metal/mtl_state_cache.mm",
                "src/libANGLE/renderer/metal/mtl_utils.mm",
            });
            try angle_src.appendSlice(b.allocator, &.{
                "src/common/system_utils_apple.cpp",
                "src/common/system_utils_posix.cpp",
                "src/compiler/translator/tree_ops/glsl/apple/AddAndTrueToLoopCondition.cpp",
                "src/compiler/translator/tree_ops/glsl/apple/RewriteRowMajorMatrices.cpp",
                "src/compiler/translator/tree_ops/glsl/apple/UnfoldShortCircuitAST.cpp",
                "src/compiler/translator/msl/AstHelpers.cpp",
                "src/compiler/translator/msl/ConstantNames.cpp",
                "src/compiler/translator/msl/DiscoverDependentFunctions.cpp",
                "src/compiler/translator/msl/DiscoverEnclosingFunctionTraverser.cpp",
                "src/compiler/translator/msl/DriverUniformMetal.cpp",
                "src/compiler/translator/msl/EmitMetal.cpp",
                "src/compiler/translator/msl/IdGen.cpp",
                "src/compiler/translator/msl/Layout.cpp",
                "src/compiler/translator/msl/MapFunctionsToDefinitions.cpp",
                "src/compiler/translator/msl/MapSymbols.cpp",
                "src/compiler/translator/msl/ModifyStruct.cpp",
                "src/compiler/translator/msl/Pipeline.cpp",
                "src/compiler/translator/msl/ProgramPrelude.cpp",
                "src/compiler/translator/msl/RewritePipelines.cpp",
                "src/compiler/translator/msl/SymbolEnv.cpp",
                "src/compiler/translator/msl/ToposortStructs.cpp",
                "src/compiler/translator/msl/TranslatorMSL.cpp",
                "src/compiler/translator/msl/UtilsMSL.cpp",
                "src/compiler/translator/tree_ops/msl/AddExplicitTypeCasts.cpp",
                "src/compiler/translator/tree_ops/msl/ConvertUnsupportedConstructorsToFunctionCalls.cpp",
                "src/compiler/translator/tree_ops/msl/EnsureLoopForwardProgress.cpp",
                "src/compiler/translator/tree_ops/msl/FixTypeConstructors.cpp",
                "src/compiler/translator/tree_ops/msl/GuardFragDepthWrite.cpp",
                "src/compiler/translator/tree_ops/msl/HoistConstants.cpp",
                "src/compiler/translator/tree_ops/msl/IntroduceVertexIndexID.cpp",
                "src/compiler/translator/tree_ops/msl/RewriteCaseDeclarations.cpp",
                "src/compiler/translator/tree_ops/msl/RewriteInterpolants.cpp",
                "src/compiler/translator/tree_ops/msl/RewriteOutArgs.cpp",
                "src/compiler/translator/tree_ops/msl/RewriteUnaddressableReferences.cpp",
                "src/compiler/translator/tree_ops/msl/SeparateCompoundExpressions.cpp",
                "src/compiler/translator/tree_ops/msl/TransposeRowMajorMatrices.cpp",
                "src/compiler/translator/tree_ops/msl/WrapMain.cpp",
                "src/libANGLE/renderer/metal/renderermtl_utils.cpp",
                "src/libANGLE/renderer/metal/blocklayoutMetal.cpp",
            });
            switch (os) {
                .macos => {
                    try angle_src.appendSlice(b.allocator, &.{
                        "src/common/gl/cgl/FunctionsCGL.cpp",
                        "src/common/system_utils_mac.cpp",
                    });
                    try angle_objc.appendSlice(b.allocator, &.{
                        "src/gpu_info_util/SystemInfo_apple.mm",
                        "src/gpu_info_util/SystemInfo_macos.mm",
                        "src/libANGLE/renderer/driver_utils_mac.mm",
                    });
                    try angle_frameworks.appendSlice(b.allocator, &.{
                        "IOKit",
                    });
                },
                else => {
                    try angle_src.appendSlice(b.allocator, &.{
                        "src/common/system_utils_ios.cpp",
                        "src/gpu_info_util/SystemInfo_ios.cpp",
                    });
                    try angle_objc.appendSlice(b.allocator, &.{
                        "src/gpu_info_util/SystemInfo_apple.mm",
                        "src/libANGLE/renderer/driver_utils_ios.mm",
                    });
                },
            }
            try angle_frameworks.appendSlice(b.allocator, &.{
                "Foundation",
                "CoreFoundation",
                "CoreGraphics",
                "QuartzCore",
                "Metal",
                "IOSurface",
            });
            try glslang_def.appendSlice(b.allocator, &.{
                "-DGLSLANG_OSINCLUDE_UNIX",
            });
            try glslang_src.appendSlice(b.allocator, &.{
                "glslang/OSDependent/Unix/ossource.cpp",
            });
        },
        .windows => {
            try angle_def.appendSlice(b.allocator, &.{
                "-D_WIN32",
                "-DANGLE_ENABLE_D3D11",
                "-DANGLE_ENABLE_D3D9",
                "-DANGLE_ENABLE_HLSL",
            });
            try angle_src.appendSlice(b.allocator, &.{
                "src/common/system_utils_win.cpp",
                "src/common/system_utils_win32.cpp",
                "src/gpu_info_util/SystemInfo_win.cpp",
                "src/libANGLE/renderer/dxgi_format_map_autogen.cpp",
                "src/libANGLE/renderer/dxgi_support_table_autogen.cpp",
                "src/libANGLE/renderer/d3d_format.cpp",
                "src/compiler/translator/hlsl/ASTMetadataHLSL.cpp",
                "src/compiler/translator/hlsl/BuiltInFunctionEmulatorHLSL.cpp",
                "src/compiler/translator/hlsl/ImageFunctionHLSL.cpp",
                "src/compiler/translator/hlsl/OutputHLSL.cpp",
                "src/compiler/translator/hlsl/ResourcesHLSL.cpp",
                "src/compiler/translator/hlsl/StructureHLSL.cpp",
                "src/compiler/translator/hlsl/TextureFunctionHLSL.cpp",
                "src/compiler/translator/hlsl/TranslatorHLSL.cpp",
                "src/compiler/translator/hlsl/UtilsHLSL.cpp",
                "src/compiler/translator/hlsl/blocklayoutHLSL.cpp",
                "src/compiler/translator/hlsl/emulated_builtin_functions_hlsl_autogen.cpp",
                "src/compiler/translator/tree_ops/hlsl/AddDefaultReturnStatements.cpp",
                "src/compiler/translator/tree_ops/hlsl/ArrayReturnValueToOutParameter.cpp",
                "src/compiler/translator/tree_ops/hlsl/BreakVariableAliasingInInnerLoops.cpp",
                "src/compiler/translator/tree_ops/hlsl/ExpandIntegerPowExpressions.cpp",
                "src/compiler/translator/tree_ops/hlsl/RecordUniformBlocksWithLargeArrayMember.cpp",
                "src/compiler/translator/tree_ops/hlsl/RemoveSwitchFallThrough.cpp",
                "src/compiler/translator/tree_ops/hlsl/RewriteElseBlocks.cpp",
                "src/compiler/translator/tree_ops/hlsl/RewriteUnaryMinusOperatorInt.cpp",
                "src/compiler/translator/tree_ops/hlsl/SeparateArrayConstructorStatements.cpp",
                "src/compiler/translator/tree_ops/hlsl/SeparateArrayInitialization.cpp",
                "src/compiler/translator/tree_ops/hlsl/SeparateExpressionsReturningArrays.cpp",
                "src/compiler/translator/tree_ops/hlsl/UnfoldShortCircuitToIf.cpp",
                "src/compiler/translator/tree_ops/hlsl/WrapSwitchStatementsInBlocks.cpp",
                "src/libANGLE/renderer/d3d/BufferD3D.cpp",
                "src/libANGLE/renderer/d3d/CompilerD3D.cpp",
                "src/libANGLE/renderer/d3d/DisplayD3D.cpp",
                "src/libANGLE/renderer/d3d/DynamicHLSL.cpp",
                "src/libANGLE/renderer/d3d/DynamicImage2DHLSL.cpp",
                "src/libANGLE/renderer/d3d/EGLImageD3D.cpp",
                "src/libANGLE/renderer/d3d/FramebufferD3D.cpp",
                "src/libANGLE/renderer/d3d/HLSLCompiler.cpp",
                "src/libANGLE/renderer/d3d/ImageD3D.cpp",
                "src/libANGLE/renderer/d3d/IndexBuffer.cpp",
                "src/libANGLE/renderer/d3d/IndexDataManager.cpp",
                "src/libANGLE/renderer/d3d/NativeWindowD3D.cpp",
                "src/libANGLE/renderer/d3d/ProgramD3D.cpp",
                "src/libANGLE/renderer/d3d/ProgramExecutableD3D.cpp",
                "src/libANGLE/renderer/d3d/RenderTargetD3D.cpp",
                "src/libANGLE/renderer/d3d/RenderbufferD3D.cpp",
                "src/libANGLE/renderer/d3d/RendererD3D.cpp",
                "src/libANGLE/renderer/d3d/ShaderD3D.cpp",
                "src/libANGLE/renderer/d3d/ShaderExecutableD3D.cpp",
                "src/libANGLE/renderer/d3d/SurfaceD3D.cpp",
                "src/libANGLE/renderer/d3d/SwapChainD3D.cpp",
                "src/libANGLE/renderer/d3d/TextureD3D.cpp",
                "src/libANGLE/renderer/d3d/VertexBuffer.cpp",
                "src/libANGLE/renderer/d3d/VertexDataManager.cpp",
                "src/libANGLE/renderer/d3d/driver_utils_d3d.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Blit9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Buffer9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Context9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/DebugAnnotator9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Device9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Fence9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Framebuffer9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Image9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/IndexBuffer9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/NativeWindow9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Query9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/RenderTarget9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/Renderer9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/ShaderExecutable9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/StateManager9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/SwapChain9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/TextureStorage9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/VertexBuffer9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/VertexDeclarationCache.cpp",
                "src/libANGLE/renderer/d3d/d3d9/formatutils9.cpp",
                "src/libANGLE/renderer/d3d/d3d9/renderer9_utils.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Blit11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Buffer11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Clear11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Context11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/DebugAnnotator11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Device11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/ExternalImageSiblingImpl11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Fence11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Framebuffer11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Image11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/IndexBuffer11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/InputLayoutCache.cpp",
                "src/libANGLE/renderer/d3d/d3d11/MappedSubresourceVerifier11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/PixelTransfer11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Program11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/ProgramPipeline11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Query11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/RenderStateCache.cpp",
                "src/libANGLE/renderer/d3d/d3d11/RenderTarget11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Renderer11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/ResourceManager11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/ShaderExecutable11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/StateManager11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/StreamProducerD3DTexture.cpp",
                "src/libANGLE/renderer/d3d/d3d11/SwapChain11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/TextureStorage11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/TransformFeedback11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/Trim11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/VertexArray11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/VertexBuffer11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/formatutils11.cpp",
                "src/libANGLE/renderer/d3d/d3d11/renderer11_utils.cpp",
                "src/libANGLE/renderer/d3d/d3d11/texture_format_table.cpp",
                "src/libANGLE/renderer/d3d/d3d11/texture_format_table_autogen.cpp",
                "src/libANGLE/renderer/d3d/d3d11/win32/NativeWindow11Win32.cpp",
                "src/libANGLE/renderer/d3d/d3d11/win32/NativeWindow11Win32.h",
            });
            try angle_libs.appendSlice(b.allocator, &.{
                "api-ms-win-core-synch-l1-2-0",
                "dxgi",
                "d3d9",
                "d3d11",
            });
            try glslang_def.appendSlice(b.allocator, &.{
                "-DGLSLANG_OSINCLUDE_WIN32",
                "-DENABLE_HLSL",
            });
            try glslang_src.appendSlice(b.allocator, &.{
                "glslang/OSDependent/Windows/ossource.cpp",
                "glslang/HLSL/hlslAttributes.cpp",
                "glslang/HLSL/hlslGrammar.cpp",
                "glslang/HLSL/hlslOpMap.cpp",
                "glslang/HLSL/hlslParseHelper.cpp",
                "glslang/HLSL/hlslParseables.cpp",
                "glslang/HLSL/hlslScanContext.cpp",
                "glslang/HLSL/hlslTokenStream.cpp",
            });
        },
        else => |os| std.log.warn("building ANGLE on untested os: {s}", .{@tagName(os)}),
    }

    const linux_support = b.addLibrary(.{
        .linkage = .static,
        .name = "angle-linux-support",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/linux/impl.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const astc = b.addLibrary(.{
        .linkage = .static,
        .name = "astc",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    astc.root_module.addIncludePath(astc_dep.path("Source"));
    astc.root_module.addCSourceFiles(.{
        .flags = &.{"-fvisibility=hidden"},
        .files = &.{
            "astcenc_averages_and_directions.cpp",
            "astcenc_block_sizes.cpp",
            "astcenc_color_quantize.cpp",
            "astcenc_color_unquantize.cpp",
            "astcenc_compress_symbolic.cpp",
            "astcenc_compute_variance.cpp",
            "astcenc_decompress_symbolic.cpp",
            "astcenc_diagnostic_trace.cpp",
            "astcenc_entry.cpp",
            "astcenc_find_best_partitioning.cpp",
            "astcenc_ideal_endpoints_and_weights.cpp",
            "astcenc_image.cpp",
            "astcenc_integer_sequence.cpp",
            "astcenc_mathlib.cpp",
            "astcenc_mathlib_softfloat.cpp",
            "astcenc_partition_tables.cpp",
            "astcenc_percentile_tables.cpp",
            "astcenc_pick_best_endpoint_format.cpp",
            "astcenc_quantization.cpp",
            "astcenc_symbolic_physical.cpp",
            "astcenc_weight_align.cpp",
            "astcenc_weight_quant_xfer_tables.cpp",
        },
        .root = astc_dep.path("Source"),
    });
    astc.installHeader(astc_dep.path("Source/astcenc.h"), "astcenc.h");

    try glslang_def.append(b.allocator, "-fvisibility=hidden");

    const glslang = b.addLibrary(.{
        .linkage = .static,
        .name = "glslang",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    var glslang_files = b.addWriteFiles();
    _ = glslang_files.add("glslang/build_info.h", b.fmt(
            \\#ifndef GLSLANG_BUILD_INFO
            \\#define GLSLANG_BUILD_INFO
            \\
            \\#define GLSLANG_VERSION_MAJOR {}
            \\#define GLSLANG_VERSION_MINOR {}
            \\#define GLSLANG_VERSION_PATCH {}
            \\#define GLSLANG_VERSION_FLAVOR ""
            \\
            \\#define GLSLANG_VERSION_GREATER_THAN(major, minor, patch) \
            \\    ((GLSLANG_VERSION_MAJOR) > (major) || ((major) == GLSLANG_VERSION_MAJOR && \
            \\    ((GLSLANG_VERSION_MINOR) > (minor) || ((minor) == GLSLANG_VERSION_MINOR && \
            \\     (GLSLANG_VERSION_PATCH) > (patch)))))
            \\
            \\#define GLSLANG_VERSION_GREATER_OR_EQUAL_TO(major, minor, patch) \
            \\    ((GLSLANG_VERSION_MAJOR) > (major) || ((major) == GLSLANG_VERSION_MAJOR && \
            \\    ((GLSLANG_VERSION_MINOR) > (minor) || ((minor) == GLSLANG_VERSION_MINOR && \
            \\     (GLSLANG_VERSION_PATCH >= (patch))))))
            \\
            \\#define GLSLANG_VERSION_LESS_THAN(major, minor, patch) \
            \\    ((GLSLANG_VERSION_MAJOR) < (major) || ((major) == GLSLANG_VERSION_MAJOR && \
            \\    ((GLSLANG_VERSION_MINOR) < (minor) || ((minor) == GLSLANG_VERSION_MINOR && \
            \\     (GLSLANG_VERSION_PATCH) < (patch)))))
            \\
            \\#define GLSLANG_VERSION_LESS_OR_EQUAL_TO(major, minor, patch) \
            \\    ((GLSLANG_VERSION_MAJOR) < (major) || ((major) == GLSLANG_VERSION_MAJOR && \
            \\    ((GLSLANG_VERSION_MINOR) < (minor) || ((minor) == GLSLANG_VERSION_MINOR && \
            \\     (GLSLANG_VERSION_PATCH <= (patch))))))
            \\
            \\#endif // GLSLANG_BUILD_INFO
            , .{16, 1, 0} // TODO: automate somehow
    ));
    glslang.root_module.addIncludePath(glslang_files.getDirectory());
    glslang.root_module.addIncludePath(glslang_dep.path(""));
    glslang.root_module.addCSourceFiles(.{
        .flags = glslang_def.items,
        .files = glslang_src.items,
        .language = .cpp,
        .root = glslang_dep.path(""),
    });
    glslang.root_module.addCSourceFiles(.{
        .flags = glslang_def.items,
        .files = &.{
            "SPIRV/GlslangToSpv.cpp",
            "SPIRV/InReadableOrder.cpp",
            "SPIRV/Logger.cpp",
            "SPIRV/SpvBuilder.cpp",
            "SPIRV/SpvPostProcess.cpp",
            "SPIRV/disassemble.cpp",
            "SPIRV/doc.cpp",
            "glslang/GenericCodeGen/CodeGen.cpp",
            "glslang/GenericCodeGen/Link.cpp",
            "glslang/MachineIndependent/Constant.cpp",
            "glslang/MachineIndependent/InfoSink.cpp",
            "glslang/MachineIndependent/Initialize.cpp",
            "glslang/MachineIndependent/IntermTraverse.cpp",
            "glslang/MachineIndependent/Intermediate.cpp",
            "glslang/MachineIndependent/ParseContextBase.cpp",
            "glslang/MachineIndependent/ParseHelper.cpp",
            "glslang/MachineIndependent/PoolAlloc.cpp",
            "glslang/MachineIndependent/RemoveTree.cpp",
            "glslang/MachineIndependent/Scan.cpp",
            "glslang/MachineIndependent/ShaderLang.cpp",
            "glslang/MachineIndependent/SpirvIntrinsics.cpp",
            "glslang/MachineIndependent/SymbolTable.cpp",
            "glslang/MachineIndependent/Versions.cpp",
            "glslang/MachineIndependent/attribute.cpp",
            "glslang/MachineIndependent/glslang_tab.cpp",
            "glslang/MachineIndependent/intermOut.cpp",
            "glslang/MachineIndependent/iomapper.cpp",
            "glslang/MachineIndependent/limits.cpp",
            "glslang/MachineIndependent/linkValidate.cpp",
            "glslang/MachineIndependent/parseConst.cpp",
            "glslang/MachineIndependent/preprocessor/Pp.cpp",
            "glslang/MachineIndependent/preprocessor/PpAtom.cpp",
            "glslang/MachineIndependent/preprocessor/PpContext.cpp",
            "glslang/MachineIndependent/preprocessor/PpScanner.cpp",
            "glslang/MachineIndependent/preprocessor/PpTokens.cpp",
            "glslang/MachineIndependent/propagateNoContraction.cpp",
            "glslang/MachineIndependent/reflection.cpp",
        },
        .root = glslang_dep.path(""),
    });

    try angle_def.appendSlice(b.allocator, &.{
        "-DLIBANGLE_IMPLEMENTATION",
        "-DANGLE_ENABLE_ESSL",
        "-DANGLE_ENABLE_GLSL",
        "-DANGLE_HAS_ASTCENC",
    });

    switch (target.result.abi) {
        .android, .androideabi => {},
        else => {
            try angle_def.appendSlice(b.allocator, &.{
                "-DANGLE_PLATFORM_EXPORT=",
            });
        },
    }

    if (linkage == .static) {
        try angle_def.appendSlice(b.allocator, &.{
            "-DANGLE_EXPORT=",
            "-DANGLE_STATIC=1",
            "-DANGLE_UTIL_EXPORT=",
            "-DEGLAPI=",
            "-DGL_APICALL=",
            "-DGL_API=",
        });
    }

    var angle_files = b.addWriteFiles();
    _ = angle_files.add("ANGLEShaderProgramVersion.h",
        // TODO: automate somehow
        \\#define ANGLE_PROGRAM_VERSION "d078f9a81d91c7a2907117d1489c88db"
        \\#define ANGLE_PROGRAM_VERSION_HASH_SIZE 16
    );
    _ = angle_files.add("angle_commit.h",
        // TODO: this shit probably does not matter
        \\#define ANGLE_COMMIT_HASH "49658850af8a"
        \\#define ANGLE_COMMIT_HASH_SIZE 12
        \\#define ANGLE_COMMIT_DATE "what year is it?"
        \\#define ANGLE_COMMIT_POSITION 0
    );

    const libANGLE = b.addLibrary(.{
        .linkage = .static,
        .name = "ANGLE",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    libANGLE.root_module.addIncludePath(angle_files.getDirectory());
    libANGLE.root_module.addIncludePath(angle_dep.path("include"));
    libANGLE.root_module.addIncludePath(angle_dep.path("src"));
    libANGLE.root_module.addIncludePath(angle_dep.path("src/common/base"));
    libANGLE.root_module.addCSourceFiles(.{
        .flags = concat(b, &.{
            &.{"-fvisibility=hidden"},
            angle_def.items,
        }),
        .files = angle_csrc.items,
        .language = .c,
        .root = angle_dep.path(""),
    });
    libANGLE.root_module.addCSourceFiles(.{
        .flags = concat(b, &.{
            &.{"-fvisibility=hidden"},
            angle_def.items,
        }),
        .files = angle_src.items,
        .language = .cpp,
        .root = angle_dep.path(""),
    });
    libANGLE.root_module.addCSourceFiles(.{
        .flags = concat(b, &.{
            &.{"-fvisibility=hidden"},
            angle_def.items,
        }),
        .files = angle_objc.items,
        .language = .objective_cpp,
        .root = angle_dep.path(""),
    });
    libANGLE.root_module.addCSourceFiles(.{
        .flags = concat(b, &.{
            &.{"-fvisibility=hidden"},
            angle_def.items,
        }),
        .files = &.{
            "src/common/angle_version_info.cpp",
            "src/common/Float16ToFloat32.cpp",
            "src/common/MemoryBuffer.cpp",
            "src/common/PackedEGLEnums_autogen.cpp",
            "src/common/PackedEnums.cpp",
            "src/common/PackedGLEnums_autogen.cpp",
            "src/common/PoolAlloc.cpp",
            "src/common/SimpleMutex.cpp",
            "src/common/WorkerThread.cpp",
            "src/common/aligned_memory.cpp",
            "src/common/android_util.cpp",
            "src/common/angleutils.cpp",
            "src/common/base/anglebase/sha1.cc",
            "src/common/debug.cpp",
            "src/common/entry_points_enum_autogen.cpp",
            "src/common/event_tracer.cpp",
            "src/common/mathutil.cpp",
            "src/common/matrix_utils.cpp",
            "src/common/platform_helpers.cpp",
            "src/common/string_utils.cpp",
            "src/common/system_utils.cpp",
            "src/common/tls.cpp",
            "src/common/uniform_type_info_autogen.cpp",
            "src/common/utilities.cpp",
            "src/common/CompiledShaderState.cpp",
            "src/common/gl_enum_utils.cpp",
            "src/common/gl_enum_utils_autogen.cpp",
            "src/image_util/copyimage.cpp",
            "src/image_util/imageformats.cpp",
            "src/image_util/loadimage.cpp",
            "src/image_util/loadimage_astc.cpp",
            "src/image_util/loadimage_etc.cpp",
            "src/image_util/loadimage_paletted.cpp",
            "src/image_util/storeimage_paletted.cpp",
            "src/image_util/AstcDecompressor.cpp",
            "src/gpu_info_util/SystemInfo.cpp",
            "src/libANGLE/capture/FrameCapture_mock.cpp",
            "src/libANGLE/capture/serialize_mock.cpp",
            "src/libANGLE/AttributeMap.cpp",
            "src/libANGLE/BlobCache.cpp",
            "src/libANGLE/Buffer.cpp",
            "src/libANGLE/Caps.cpp",
            "src/libANGLE/Compiler.cpp",
            "src/libANGLE/Config.cpp",
            "src/libANGLE/Context.cpp",
            "src/libANGLE/ContextMutex.cpp",
            "src/libANGLE/Context_gles_1_0.cpp",
            "src/libANGLE/Debug.cpp",
            "src/libANGLE/Device.cpp",
            "src/libANGLE/Display.cpp",
            "src/libANGLE/EGLSync.cpp",
            "src/libANGLE/Error.cpp",
            "src/libANGLE/Fence.cpp",
            "src/libANGLE/Framebuffer.cpp",
            "src/libANGLE/FramebufferAttachment.cpp",
            "src/libANGLE/GLES1Renderer.cpp",
            "src/libANGLE/GLES1State.cpp",
            "src/libANGLE/GlobalMutex.cpp",
            "src/libANGLE/HandleAllocator.cpp",
            "src/libANGLE/Image.cpp",
            "src/libANGLE/ImageIndex.cpp",
            "src/libANGLE/IndexRangeCache.cpp",
            "src/libANGLE/LoggingAnnotator.cpp",
            "src/libANGLE/MemoryObject.cpp",
            "src/libANGLE/MemoryProgramCache.cpp",
            "src/libANGLE/MemoryShaderCache.cpp",
            "src/libANGLE/Observer.cpp",
            "src/libANGLE/Overlay.cpp",
            "src/libANGLE/OverlayWidgets.cpp",
            "src/libANGLE/Overlay_autogen.cpp",
            "src/libANGLE/Overlay_font_autogen.cpp",
            "src/libANGLE/PixelLocalStorage.cpp",
            "src/libANGLE/Platform.cpp",
            "src/libANGLE/Program.cpp",
            "src/libANGLE/ProgramExecutable.cpp",
            "src/libANGLE/ProgramLinkedResources.cpp",
            "src/libANGLE/ProgramPipeline.cpp",
            "src/libANGLE/Query.cpp",
            "src/libANGLE/Renderbuffer.cpp",
            "src/libANGLE/ResourceManager.cpp",
            "src/libANGLE/Sampler.cpp",
            "src/libANGLE/Semaphore.cpp",
            "src/libANGLE/Shader.cpp",
            "src/libANGLE/ShareGroup.cpp",
            "src/libANGLE/State.cpp",
            "src/libANGLE/Stream.cpp",
            "src/libANGLE/Surface.cpp",
            "src/libANGLE/Texture.cpp",
            "src/libANGLE/Thread.cpp",
            "src/libANGLE/TransformFeedback.cpp",
            "src/libANGLE/Uniform.cpp",
            "src/libANGLE/VaryingPacking.cpp",
            "src/libANGLE/VertexArray.cpp",
            "src/libANGLE/VertexAttribute.cpp",
            "src/libANGLE/angletypes.cpp",
            "src/libANGLE/es3_copy_conversion_table_autogen.cpp",
            "src/libANGLE/format_map_autogen.cpp",
            "src/libANGLE/formatutils.cpp",
            "src/libANGLE/gles_extensions_autogen.cpp",
            "src/libANGLE/queryconversions.cpp",
            "src/libANGLE/queryutils.cpp",
            "src/libANGLE/renderer/BufferImpl.cpp",
            "src/libANGLE/renderer/ContextImpl.cpp",
            "src/libANGLE/renderer/DeviceImpl.cpp",
            "src/libANGLE/renderer/DisplayImpl.cpp",
            "src/libANGLE/renderer/EGLReusableSync.cpp",
            "src/libANGLE/renderer/EGLSyncImpl.cpp",
            "src/libANGLE/renderer/Format_table_autogen.cpp",
            "src/libANGLE/renderer/FramebufferImpl.cpp",
            "src/libANGLE/renderer/ImageImpl.cpp",
            "src/libANGLE/renderer/ProgramImpl.cpp",
            "src/libANGLE/renderer/ProgramPipelineImpl.cpp",
            "src/libANGLE/renderer/QueryImpl.cpp",
            "src/libANGLE/renderer/RenderbufferImpl.cpp",
            "src/libANGLE/renderer/ShaderImpl.cpp",
            "src/libANGLE/renderer/SurfaceImpl.cpp",
            "src/libANGLE/renderer/TextureImpl.cpp",
            "src/libANGLE/renderer/TransformFeedbackImpl.cpp",
            "src/libANGLE/renderer/VertexArrayImpl.cpp",
            "src/libANGLE/renderer/driver_utils.cpp",
            "src/libANGLE/renderer/load_functions_table_autogen.cpp",
            "src/libANGLE/renderer/renderer_utils.cpp",
            "src/libANGLE/validationEGL.cpp",
            "src/libANGLE/validationES.cpp",
            "src/libANGLE/validationES1.cpp",
            "src/libANGLE/validationES2.cpp",
            "src/libANGLE/validationES3.cpp",
            "src/libANGLE/validationES31.cpp",
            "src/libANGLE/validationES32.cpp",
            "src/libANGLE/validationESEXT.cpp",
            "src/compiler/translator/BaseTypes.cpp",
            "src/compiler/translator/BuiltInFunctionEmulator.cpp",
            "src/compiler/translator/CallDAG.cpp",
            "src/compiler/translator/CodeGen.cpp",
            "src/compiler/translator/CollectVariables.cpp",
            "src/compiler/translator/Compiler.cpp",
            "src/compiler/translator/ConstantUnion.cpp",
            "src/compiler/translator/Declarator.cpp",
            "src/compiler/translator/Diagnostics.cpp",
            "src/compiler/translator/DirectiveHandler.cpp",
            "src/compiler/translator/ExtensionBehavior.cpp",
            "src/compiler/translator/FlagStd140Structs.cpp",
            "src/compiler/translator/FunctionLookup.cpp",
            "src/compiler/translator/HashNames.cpp",
            "src/compiler/translator/ImmutableStringBuilder.cpp",
            "src/compiler/translator/InfoSink.cpp",
            "src/compiler/translator/Initialize.cpp",
            "src/compiler/translator/IntermNode.cpp",
            "src/compiler/translator/IntermRebuild.cpp",
            "src/compiler/translator/IsASTDepthBelowLimit.cpp",
            "src/compiler/translator/Name.cpp",
            "src/compiler/translator/Operator.cpp",
            "src/compiler/translator/OutputTree.cpp",
            "src/compiler/translator/ParseContext.cpp",
            "src/compiler/translator/PoolAlloc.cpp",
            "src/compiler/translator/QualifierTypes.cpp",
            "src/compiler/translator/ShaderLang.cpp",
            "src/compiler/translator/ShaderVars.cpp",
            "src/compiler/translator/SizeClipCullDistance.cpp",
            "src/compiler/translator/Symbol.cpp",
            "src/compiler/translator/SymbolTable.cpp",
            "src/compiler/translator/SymbolUniqueId.cpp",
            "src/compiler/translator/Types.cpp",
            "src/compiler/translator/ValidateAST.cpp",
            "src/compiler/translator/ValidateGlobalInitializer.cpp",
            "src/compiler/translator/ValidateOutputs.cpp",
            "src/compiler/translator/ValidateTypeSizeLimitations.cpp",
            "src/compiler/translator/ValidateVaryingLocations.cpp",
            "src/compiler/translator/VariablePacker.cpp",
            "src/compiler/translator/blocklayout.cpp",
            "src/compiler/translator/glslang_lex_autogen.cpp",
            "src/compiler/translator/glslang_tab_autogen.cpp",
            "src/compiler/translator/tree_ops/ClampFragDepth.cpp",
            "src/compiler/translator/tree_ops/ClampIndirectIndices.cpp",
            "src/compiler/translator/tree_ops/ClampPointSize.cpp",
            "src/compiler/translator/tree_ops/DeclareAndInitBuiltinsForInstancedMultiview.cpp",
            "src/compiler/translator/tree_ops/DeclarePerVertexBlocks.cpp",
            "src/compiler/translator/tree_ops/DeferGlobalInitializers.cpp",
            "src/compiler/translator/tree_ops/EmulateGLFragColorBroadcast.cpp",
            "src/compiler/translator/tree_ops/EmulateMultiDrawShaderBuiltins.cpp",
            "src/compiler/translator/tree_ops/FoldExpressions.cpp",
            "src/compiler/translator/tree_ops/GatherDefaultUniforms.cpp",
            "src/compiler/translator/tree_ops/InitializeVariables.cpp",
            "src/compiler/translator/tree_ops/MonomorphizeUnsupportedFunctions.cpp",
            "src/compiler/translator/tree_ops/PreTransformTextureCubeGradDerivatives.cpp",
            "src/compiler/translator/tree_ops/PruneEmptyCases.cpp",
            "src/compiler/translator/tree_ops/PruneNoOps.cpp",
            "src/compiler/translator/tree_ops/RecordConstantPrecision.cpp",
            "src/compiler/translator/tree_ops/ReduceInterfaceBlocks.cpp",
            "src/compiler/translator/tree_ops/RemoveArrayLengthMethod.cpp",
            "src/compiler/translator/tree_ops/RemoveAtomicCounterBuiltins.cpp",
            "src/compiler/translator/tree_ops/RemoveDynamicIndexing.cpp",
            "src/compiler/translator/tree_ops/RemoveInactiveInterfaceVariables.cpp",
            "src/compiler/translator/tree_ops/RemoveInvariantDeclaration.cpp",
            "src/compiler/translator/tree_ops/RemoveUnreferencedVariables.cpp",
            "src/compiler/translator/tree_ops/RemoveUnusedFramebufferFetch.cpp",
            "src/compiler/translator/tree_ops/RescopeGlobalVariables.cpp",
            "src/compiler/translator/tree_ops/RewriteArrayOfArrayOfOpaqueUniforms.cpp",
            "src/compiler/translator/tree_ops/RewriteAtomicCounters.cpp",
            "src/compiler/translator/tree_ops/RewriteDfdy.cpp",
            "src/compiler/translator/tree_ops/RewritePixelLocalStorage.cpp",
            "src/compiler/translator/tree_ops/RewriteStructSamplers.cpp",
            "src/compiler/translator/tree_ops/RewriteTexelFetchOffset.cpp",
            "src/compiler/translator/tree_ops/ScalarizeVecAndMatConstructorArgs.cpp",
            "src/compiler/translator/tree_ops/SeparateDeclarations.cpp",
            "src/compiler/translator/tree_ops/SeparateStructFromUniformDeclarations.cpp",
            "src/compiler/translator/tree_ops/SimplifyLoopConditions.cpp",
            "src/compiler/translator/tree_ops/SplitSequenceOperator.cpp",
            "src/compiler/translator/tree_util/DriverUniform.cpp",
            "src/compiler/translator/tree_util/FindFunction.cpp",
            "src/compiler/translator/tree_util/FindMain.cpp",
            "src/compiler/translator/tree_util/FindPreciseNodes.cpp",
            "src/compiler/translator/tree_util/FindSymbolNode.cpp",
            "src/compiler/translator/tree_util/IntermNodePatternMatcher.cpp",
            "src/compiler/translator/tree_util/IntermNode_util.cpp",
            "src/compiler/translator/tree_util/IntermTraverse.cpp",
            "src/compiler/translator/tree_util/ReplaceArrayOfMatrixVarying.cpp",
            "src/compiler/translator/tree_util/ReplaceClipCullDistanceVariable.cpp",
            "src/compiler/translator/tree_util/ReplaceShadowingVariables.cpp",
            "src/compiler/translator/tree_util/ReplaceVariable.cpp",
            "src/compiler/translator/tree_util/RewriteSampleMaskVariable.cpp",
            "src/compiler/translator/tree_util/RunAtTheBeginningOfShader.cpp",
            "src/compiler/translator/tree_util/RunAtTheEndOfShader.cpp",
            "src/compiler/translator/tree_util/SpecializationConstant.cpp",
            "src/compiler/translator/util.cpp",
            "src/compiler/translator/glsl/OutputGLSLBase.cpp",
            "src/compiler/translator/glsl/OutputGLSL.cpp",
            "src/compiler/translator/glsl/OutputESSL.cpp",
            "src/compiler/translator/glsl/TranslatorESSL.cpp",
            "src/compiler/translator/glsl/BuiltInFunctionEmulatorGLSL.cpp",
            "src/compiler/translator/glsl/ExtensionGLSL.cpp",
            "src/compiler/translator/glsl/TranslatorGLSL.cpp",
            "src/compiler/translator/glsl/VersionGLSL.cpp",
            "src/compiler/translator/tree_ops/glsl/RegenerateStructNames.cpp",
            "src/compiler/translator/tree_ops/glsl/RewriteRepeatedAssignToSwizzled.cpp",
            "src/compiler/translator/tree_ops/glsl/UseInterfaceBlockFields.cpp",
            "src/compiler/translator/ImmutableString_autogen.cpp",
            "src/compiler/translator/SymbolTable_autogen.cpp",
            "src/compiler/preprocessor/DiagnosticsBase.cpp",
            "src/compiler/preprocessor/DirectiveHandlerBase.cpp",
            "src/compiler/preprocessor/DirectiveParser.cpp",
            "src/compiler/preprocessor/Input.cpp",
            "src/compiler/preprocessor/Lexer.cpp",
            "src/compiler/preprocessor/Macro.cpp",
            "src/compiler/preprocessor/MacroExpander.cpp",
            "src/compiler/preprocessor/Preprocessor.cpp",
            "src/compiler/preprocessor/Token.cpp",
            "src/compiler/preprocessor/preprocessor_lex_autogen.cpp",
            "src/compiler/preprocessor/preprocessor_tab_autogen.cpp",
        },
        .language = .cpp,
        .root = angle_dep.path(""),
    });
    libANGLE.root_module.addIncludePath(angle_dep.path("src/common/third_party/xxhash"));
    libANGLE.root_module.addCSourceFiles(.{
        .flags = &.{"-fvisibility=hidden"},
        .files = &.{"src/common/third_party/xxhash/xxhash.c"},
        .language = .c,
        .root = angle_dep.path(""),
    });
    libANGLE.root_module.addIncludePath(b.path("src/zlib-google"));
    libANGLE.root_module.addCSourceFiles(.{
        .flags = &.{"-fvisibility=hidden"},
        .files = &.{"compression_utils_portable.cc"},
        .language = .cpp,
        .root = b.path("src/zlib-google"),
    });
    libANGLE.root_module.linkLibrary(zlib_dep.artifact("z"));
    libANGLE.root_module.linkLibrary(astc);
    libANGLE.root_module.linkLibrary(glslang);
    for (angle_frameworks.items) |framework| {
        libANGLE.root_module.linkFramework(framework, .{});
    }
    for (angle_libs.items) |lib| {
        libANGLE.root_module.linkSystemLibrary(lib, .{});
    }
    for (angle_incl.items) |inc| {
        libANGLE.root_module.addSystemIncludePath(inc);
    }
    if (target.result.os.tag == .linux) {
        libANGLE.root_module.linkLibrary(linux_support);
    }
    b.installArtifact(libANGLE);

    const need_prefix = target.result.libPrefix().len == 0;

    const libGLESv2 = b.addLibrary(.{
        .linkage = linkage,
        .name = if (need_prefix) "libGLESv2" else "GLESv2",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    libGLESv2.root_module.addIncludePath(angle_dep.path("include"));
    libGLESv2.root_module.addIncludePath(angle_dep.path("src"));
    libGLESv2.root_module.addIncludePath(angle_dep.path("src/common/base"));
    libGLESv2.root_module.addIncludePath(angle_dep.path("src/common/third_party/xxhash"));
    libGLESv2.root_module.addCSourceFiles(.{
        .flags = concat(b, &.{
            &.{
                "-DGL_GLES_PROTOTYPES=1",
                "-DGL_GLEXT_PROTOTYPES",
                "-DEGL_EGL_PROTOTYPES=1",
                "-DEGL_EGLEXT_PROTOTYPES",
                "-DLIBGLESV2_IMPLEMENTATION",
            },
            angle_def.items,
        }),
        .files = &.{
            "src/libGLESv2/libGLESv2_autogen.cpp",
            "src/libGLESv2/egl_ext_stubs.cpp",
            "src/libGLESv2/egl_stubs.cpp",
            "src/libGLESv2/egl_stubs_getprocaddress_autogen.cpp",
            "src/libGLESv2/entry_points_egl_autogen.cpp",
            "src/libGLESv2/entry_points_egl_ext_autogen.cpp",
            "src/libGLESv2/entry_points_gles_1_0_autogen.cpp",
            "src/libGLESv2/entry_points_gles_2_0_autogen.cpp",
            "src/libGLESv2/entry_points_gles_3_0_autogen.cpp",
            "src/libGLESv2/entry_points_gles_3_1_autogen.cpp",
            "src/libGLESv2/entry_points_gles_3_2_autogen.cpp",
            "src/libGLESv2/entry_points_gles_ext_autogen.cpp",
            "src/libGLESv2/global_state.cpp",
        },
        .language = .cpp,
        .root = angle_dep.path(""),
    });
    libGLESv2.root_module.linkLibrary(libANGLE);
    b.installArtifact(libGLESv2);

    const libGLESv1_CM = b.addLibrary(.{
        .linkage = linkage,
        .name = if (need_prefix) "libGLESv1_CM" else "GLESv1_CM",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    libGLESv1_CM.root_module.addIncludePath(angle_dep.path("include"));
    libGLESv1_CM.root_module.addIncludePath(angle_dep.path("src"));
    libGLESv1_CM.root_module.addCSourceFiles(.{
        .flags = concat(b, &.{
            &.{
                "-DGL_GLES_PROTOTYPES=1",
                "-DGL_GLEXT_PROTOTYPES",
            },
            angle_def.items,
        }),
        .files = &.{
            "src/libGLESv1_CM/libGLESv1_CM.cpp",
        },
        .language = .cpp,
        .root = angle_dep.path(""),
    });
    libGLESv1_CM.root_module.linkLibrary(libGLESv2);
    b.installArtifact(libGLESv1_CM);

    const libEGL = b.addLibrary(.{
        .linkage = linkage,
        .name = if (need_prefix) "libEGL" else "EGL",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    libEGL.root_module.addIncludePath(angle_dep.path("include"));
    libEGL.root_module.addIncludePath(angle_dep.path("src"));
    libEGL.root_module.addIncludePath(angle_dep.path("src/common/base"));
    libEGL.root_module.addIncludePath(angle_dep.path("src/common/third_party/xxhash"));

    var egl_def: std.ArrayListUnmanaged([]const u8) = .empty;
    var egl_src: std.ArrayListUnmanaged([]const u8) = .empty;

    if (linkage == .dynamic) {
        try egl_def.appendSlice(b.allocator, &.{
            "-DANGLE_USE_EGL_LOADER",
            // NOTE: The prefixes have to be 'lib' even on windows!
            b.fmt("-DANGLE_DISPATCH_LIBRARY=\"libGLESv2{s}\"", .{
                target.result.dynamicLibSuffix(),
            }),
            b.fmt("-DANGLE_EGL_LIBRARY_NAME=\"libEGL{s}\"", .{
                target.result.dynamicLibSuffix(),
            }),
            b.fmt("-DANGLE_GLESV2_LIBRARY_NAME=\"libGLESv2{s}\"", .{
                target.result.dynamicLibSuffix(),
            }),
        });
        try egl_src.appendSlice(b.allocator, &.{
            "src/libEGL/libEGL_autogen.cpp",
            "src/libEGL/egl_loader_autogen.cpp",
        });
    } else {
        try egl_def.appendSlice(b.allocator, &.{
            "-DEGL_EGL_PROTOTYPES=1",
            "-DEGL_EGLEXT_PROTOTYPES",
            "-DLIBEGL_IMPLEMENTATION",
        });
        try egl_src.appendSlice(b.allocator, &.{
            "src/libEGL/libEGL_autogen.cpp",
        });
    }

    libEGL.root_module.addCSourceFiles(.{
        .flags = concat(b, &.{ egl_def.items, angle_def.items }),
        .files = egl_src.items,
        .language = .cpp,
        .root = angle_dep.path(""),
    });
    libEGL.root_module.linkLibrary(libANGLE);
    if (linkage == .static) {
        libEGL.root_module.linkLibrary(libGLESv2);
    }
    b.installArtifact(libEGL);
}

fn concat(b: *std.Build, slices: []const []const []const u8) []const []const u8 {
    return std.mem.concat(b.allocator, []const u8, slices) catch @panic("OOM");
}
