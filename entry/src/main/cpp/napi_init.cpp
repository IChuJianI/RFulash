#include <cstdint>
#include <string>
#include <vector>

#include <ace/xcomponent/native_interface_xcomponent.h>
// hilog/log.h only defaults these when they are not defined yet.
#define LOG_DOMAIN 0x0000
#define LOG_TAG "RuffleNAPI"
#include <hilog/log.h>
#include <napi/native_api.h>
#include <native_window/external_window.h>

#define LOGI(...) OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, __VA_ARGS__)

extern "C" {
int ruffle_init(const char* files_dir);
int ruffle_surface_created(uintptr_t window);
int ruffle_surface_destroyed(void);
int ruffle_is_ready(void);
int ruffle_has_movie(void);
int ruffle_is_playing(void);
uint32_t ruffle_movie_width(void);
uint32_t ruffle_movie_height(void);
int ruffle_last_error(char* buffer, int32_t capacity);
int ruffle_peek_event(void);
int ruffle_poll_event(char* buffer, int32_t capacity);
int ruffle_http_result(uint32_t id, int32_t status, const char* content_type, const char* body);
int ruffle_load_swf(const char* path);
int ruffle_load_url(const char* url);
int ruffle_set_playing(int32_t playing);
int ruffle_toggle_playing(void);
int ruffle_touch(int32_t action, float x, float y);
int ruffle_key(int32_t action, int32_t key_code);
int ruffle_text(const char* text);
int ruffle_set_fullscreen(int32_t is_full);
int ruffle_dialog_result(uint32_t id, const char* paths);
int ruffle_mouse(int32_t action, float x, float y, int32_t button);
int ruffle_wheel(float delta);
int ruffle_focus(int32_t focused);
int ruffle_set_volume(float volume);
int ruffle_set_quality(int32_t index);
int ruffle_set_scale_mode(int32_t mode, int32_t forced);
int ruffle_set_letterbox(int32_t enabled);
int ruffle_step(void);
int ruffle_reload(void);
int ruffle_show_menu(void);
int ruffle_request_thumbnail(const char* name);
int ruffle_shutdown(void);
int ruffle_set_surface_size(uint32_t width, uint32_t height);
}

namespace {

OH_NativeXComponent* g_xcomponent = nullptr;
OHNativeWindow* g_window = nullptr;
int32_t g_surface_width = 0;
int32_t g_surface_height = 0;
// The engine lives between surface creation and destruction, so late surface
// callbacks after an explicit shutdown must not touch it again.
bool g_engine_shutdown = false;

// The XComponent surface keeps the buffer geometry it was created with until
// native code asks for a new one, so the player would keep rendering at that
// stale resolution.
void ApplySurfaceSize(int32_t width, int32_t height) {
    if (width <= 0 || height <= 0) {
        return;
    }
    if (width == g_surface_width && height == g_surface_height) {
        return;
    }
    g_surface_width = width;
    g_surface_height = height;
    if (g_window != nullptr) {
        OH_NativeWindow_NativeWindowHandleOpt(g_window, SET_BUFFER_GEOMETRY, width, height);
    }
    ruffle_set_surface_size(static_cast<uint32_t>(width), static_cast<uint32_t>(height));
    LOGI("surface size %{public}dx%{public}d", width, height);
}

void OnSurfaceCreated(OH_NativeXComponent* component, void* window) {
    if (g_engine_shutdown) {
        return;
    }
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
    LOGI("OnSurfaceCreated window=%{public}llu size=%{public}llux%{public}llu",
         static_cast<unsigned long long>(reinterpret_cast<uintptr_t>(window)),
         static_cast<unsigned long long>(width),
         static_cast<unsigned long long>(height));

    g_window = reinterpret_cast<OHNativeWindow*>(window);
    // Sizes from the XComponent callbacks are in vp; the ArkTS shell reports
    // the same surface in pixels right after layout.
    if (g_surface_width > 0 && g_surface_height > 0) {
        OH_NativeWindow_NativeWindowHandleOpt(g_window, SET_BUFFER_GEOMETRY, g_surface_width,
                                              g_surface_height);
    }

    ruffle_surface_created(reinterpret_cast<uintptr_t>(window));
}

void OnSurfaceChanged(OH_NativeXComponent* component, void* /*window*/) {
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, g_window, &width, &height);
    LOGI("OnSurfaceChanged size=%{public}llux%{public}llu",
         static_cast<unsigned long long>(width),
         static_cast<unsigned long long>(height));
}

void OnSurfaceDestroyed(OH_NativeXComponent* /*component*/, void* /*window*/) {
    LOGI("OnSurfaceDestroyed");
    // Keep the last pixel size: a recreated surface must reuse it, and the
    // shell only reports sizes when the component actually changes.
    g_window = nullptr;
    if (g_engine_shutdown) {
        return;
    }
    ruffle_surface_destroyed();
}

void DispatchTouchEvent(OH_NativeXComponent* component, void* window) {
    OH_NativeXComponent_TouchEvent event;
    if (OH_NativeXComponent_GetTouchEvent(component, window, &event) != 0) {
        return;
    }
    ruffle_touch(static_cast<int32_t>(event.type), event.x, event.y);
}

OH_NativeXComponent_Callback g_surfaceCallback = {
    OnSurfaceCreated,
    OnSurfaceChanged,
    OnSurfaceDestroyed,
    DispatchTouchEvent,
};

void DispatchMouseEvent(OH_NativeXComponent* component, void* window) {
    OH_NativeXComponent_MouseEvent event;
    if (OH_NativeXComponent_GetMouseEvent(component, window, &event) != 0) {
        return;
    }
    // The Flash context menu belongs to the player, not the movie, so right
    // clicks open the shell menu instead of reaching ActionScript.
    const bool right_button = (event.button & 0x02) != 0;
    if (right_button) {
        if (event.action == 1) {
            ruffle_show_menu();
        }
        return;
    }
    ruffle_mouse(static_cast<int32_t>(event.action), event.x, event.y,
                 static_cast<int32_t>(event.button));
}

void DispatchHoverEvent(OH_NativeXComponent* /*component*/, bool /*isHover*/) {}

OH_NativeXComponent_MouseEvent_Callback g_mouseCallback = {
    DispatchMouseEvent,
    DispatchHoverEvent,
};

std::string GetStringArg(napi_env env, napi_value value) {
    size_t length = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) {
        return {};
    }
    std::vector<char> buffer(length + 1, '\0');
    size_t copied = 0;
    if (napi_get_value_string_utf8(env, value, buffer.data(), buffer.size(), &copied) != napi_ok) {
        return {};
    }
    return std::string(buffer.data(), copied);
}

int32_t GetIntArg(napi_env env, napi_value value, int32_t fallback) {
    int32_t result = fallback;
    if (napi_get_value_int32(env, value, &result) != napi_ok) {
        return fallback;
    }
    return result;
}

double GetDoubleArg(napi_env env, napi_value value) {
    double result = 0.0;
    if (napi_get_value_double(env, value, &result) != napi_ok) {
        return 0.0;
    }
    return result;
}

napi_value MakeInt(napi_env env, int32_t value) {
    napi_value result = nullptr;
    napi_create_int32(env, value, &result);
    return result;
}

napi_value NativeInit(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    std::string filesDir = GetStringArg(env, args[0]);
    if (filesDir.empty()) {
        return MakeInt(env, -1);
    }
    g_engine_shutdown = false;
    return MakeInt(env, ruffle_init(filesDir.c_str()));
}

napi_value NativeReady(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, ruffle_is_ready());
}

// 1 while the XComponent surface (and with it the native engine) exists.
napi_value NativeSurfaceReady(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, (g_window != nullptr && !g_engine_shutdown) ? 1 : 0);
}

napi_value NativeHasMovie(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, ruffle_has_movie());
}

napi_value NativeIsPlaying(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, ruffle_is_playing());
}

napi_value NativeMovieWidth(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, static_cast<int32_t>(ruffle_movie_width()));
}

napi_value NativeMovieHeight(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, static_cast<int32_t>(ruffle_movie_height()));
}

napi_value NativeLastError(napi_env env, napi_callback_info /*info*/) {
    int32_t length = ruffle_last_error(nullptr, 0);
    if (length <= 0) {
        napi_value empty = nullptr;
        napi_create_string_utf8(env, "", 0, &empty);
        return empty;
    }
    std::vector<char> buffer(static_cast<size_t>(length) + 1, '\0');
    ruffle_last_error(buffer.data(), static_cast<int32_t>(buffer.size()));
    napi_value result = nullptr;
    napi_create_string_utf8(env, buffer.data(), static_cast<size_t>(length), &result);
    return result;
}

napi_value NativePollEvent(napi_env env, napi_callback_info /*info*/) {
    // HTTP bridge events carry base64 bodies, so size the buffer from the
    // queued event instead of using a fixed cap that would truncate it.
    int32_t length = ruffle_peek_event();
    if (length < 0) {
        napi_value empty = nullptr;
        napi_create_string_utf8(env, "", 0, &empty);
        return empty;
    }
    std::vector<char> buffer(static_cast<size_t>(length) + 1, '\0');
    length = ruffle_poll_event(buffer.data(), static_cast<int32_t>(buffer.size()));
    if (length <= 0) {
        napi_value empty = nullptr;
        napi_create_string_utf8(env, "", 0, &empty);
        return empty;
    }
    napi_value result = nullptr;
    napi_create_string_utf8(env, buffer.data(), static_cast<size_t>(length), &result);
    return result;
}

napi_value NativeHttpResult(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value args[4] = {nullptr, nullptr, nullptr, nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 4) {
        return MakeInt(env, -1);
    }
    uint32_t id = static_cast<uint32_t>(GetIntArg(env, args[0], 0));
    int32_t status = GetIntArg(env, args[1], 0);
    std::string contentType = GetStringArg(env, args[2]);
    std::string body = GetStringArg(env, args[3]);
    return MakeInt(env, ruffle_http_result(id, status, contentType.c_str(), body.c_str()));
}

napi_value NativeLoadSwf(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    std::string path = GetStringArg(env, args[0]);
    if (path.empty()) {
        return MakeInt(env, -1);
    }
    LOGI("nativeLoadSwf %{public}s", path.c_str());
    return MakeInt(env, ruffle_load_swf(path.c_str()));
}

napi_value NativeLoadUrl(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    std::string url = GetStringArg(env, args[0]);
    if (url.empty()) {
        return MakeInt(env, -1);
    }
    LOGI("nativeLoadUrl %{public}s", url.c_str());
    return MakeInt(env, ruffle_load_url(url.c_str()));
}

napi_value NativeSetPlaying(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_set_playing(GetIntArg(env, args[0], 0)));
}

napi_value NativeTogglePlaying(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, ruffle_toggle_playing());
}

napi_value NativeKey(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 2) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_key(GetIntArg(env, args[0], 0), GetIntArg(env, args[1], 0)));
}

napi_value NativeTextInput(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    std::string text = GetStringArg(env, args[0]);
    if (text.empty()) {
        return MakeInt(env, 0);
    }
    return MakeInt(env, ruffle_text(text.c_str()));
}

napi_value NativeSetFullscreen(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_set_fullscreen(GetIntArg(env, args[0], 0)));
}

napi_value NativeDialogResult(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 2) {
        return MakeInt(env, -1);
    }
    uint32_t id = static_cast<uint32_t>(GetIntArg(env, args[0], 0));
    std::string paths = GetStringArg(env, args[1]);
    return MakeInt(env, ruffle_dialog_result(id, paths.c_str()));
}

napi_value NativeSurfaceSize(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 2) {
        return MakeInt(env, -1);
    }
    ApplySurfaceSize(GetIntArg(env, args[0], 0), GetIntArg(env, args[1], 0));
    return MakeInt(env, 0);
}

napi_value NativeWheel(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_wheel(static_cast<float>(GetDoubleArg(env, args[0]))));
}

napi_value NativeFocus(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_focus(GetIntArg(env, args[0], 0)));
}

napi_value NativeSetVolume(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_set_volume(static_cast<float>(GetDoubleArg(env, args[0]))));
}

napi_value NativeSetQuality(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_set_quality(GetIntArg(env, args[0], 2)));
}

napi_value NativeSetScaleMode(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 2) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_set_scale_mode(GetIntArg(env, args[0], 3),
                                              GetIntArg(env, args[1], 0)));
}

napi_value NativeSetLetterbox(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_set_letterbox(GetIntArg(env, args[0], 0)));
}

napi_value NativeStep(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, ruffle_step());
}

napi_value NativeReload(napi_env env, napi_callback_info /*info*/) {
    return MakeInt(env, ruffle_reload());
}

napi_value NativeShutdown(napi_env env, napi_callback_info /*info*/) {
    g_engine_shutdown = true;
    return MakeInt(env, ruffle_shutdown());
}

napi_value NativeRequestThumbnail(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok || argc < 1) {
        return MakeInt(env, -1);
    }
    std::string name = GetStringArg(env, args[0]);
    if (name.empty()) {
        return MakeInt(env, -1);
    }
    return MakeInt(env, ruffle_request_thumbnail(name.c_str()));
}

napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"nativeInit", nullptr, NativeInit, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeReady", nullptr, NativeReady, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeSurfaceReady", nullptr, NativeSurfaceReady, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeHasMovie", nullptr, NativeHasMovie, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeIsPlaying", nullptr, NativeIsPlaying, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeMovieWidth", nullptr, NativeMovieWidth, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeMovieHeight", nullptr, NativeMovieHeight, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeLastError", nullptr, NativeLastError, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativePollEvent", nullptr, NativePollEvent, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeHttpResult", nullptr, NativeHttpResult, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeLoadSwf", nullptr, NativeLoadSwf, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeLoadUrl", nullptr, NativeLoadUrl, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeSetPlaying", nullptr, NativeSetPlaying, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeTogglePlaying", nullptr, NativeTogglePlaying, nullptr, nullptr, nullptr,
         napi_default, nullptr},
        {"nativeKey", nullptr, NativeKey, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeTextInput", nullptr, NativeTextInput, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeSetFullscreen", nullptr, NativeSetFullscreen, nullptr, nullptr, nullptr,
         napi_default, nullptr},
        {"nativeDialogResult", nullptr, NativeDialogResult, nullptr, nullptr, nullptr,
         napi_default, nullptr},
        {"nativeSurfaceSize", nullptr, NativeSurfaceSize, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeWheel", nullptr, NativeWheel, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeFocus", nullptr, NativeFocus, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeSetVolume", nullptr, NativeSetVolume, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeSetQuality", nullptr, NativeSetQuality, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeSetScaleMode", nullptr, NativeSetScaleMode, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeSetLetterbox", nullptr, NativeSetLetterbox, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeStep", nullptr, NativeStep, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeReload", nullptr, NativeReload, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeShutdown", nullptr, NativeShutdown, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"nativeRequestThumbnail", nullptr, NativeRequestThumbnail, nullptr, nullptr, nullptr,
         napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);

    napi_value exportInstance = nullptr;
    if (napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance) ==
        napi_ok) {
        void* instance = nullptr;
        if (napi_unwrap(env, exportInstance, &instance) == napi_ok && instance != nullptr) {
            g_xcomponent = reinterpret_cast<OH_NativeXComponent*>(instance);
            OH_NativeXComponent_RegisterCallback(g_xcomponent, &g_surfaceCallback);
            OH_NativeXComponent_RegisterMouseEventCallback(g_xcomponent, &g_mouseCallback);
            LOGI("XComponent callbacks registered");
        }
    } else {
        LOGE("XComponent object missing from exports");
    }

    return exports;
}

} // namespace

static napi_module g_entryModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) {
    napi_module_register(&g_entryModule);
}
