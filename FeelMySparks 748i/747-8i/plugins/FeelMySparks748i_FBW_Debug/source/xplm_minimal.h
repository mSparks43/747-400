#ifndef XPLM_MINIMAL_H
#define XPLM_MINIMAL_H
#define PLUGIN_API __attribute__((visibility("default")))

#include <stddef.h>

void XPLMSetGraphicsState(int, int, int, int, int, int, int, int);

typedef void *XPLMWindowID;
typedef void *XPLMDataRef;
typedef void *XPLMMenuID;
typedef double (*XPLMGetDatad_f)(void *);
typedef void (*XPLMSetDatad_f)(void *, double);
typedef int XPLMPluginID;
typedef int XPLMMouseStatus;
typedef int XPLMKeyFlags;
typedef int XPLMFontID;
typedef int XPLMCursorStatus;
typedef int XPLMCommandPhase;
typedef void (*XPLMMenuHandler_f)(void *, void *);

#define xplmFont_Basic 0
#define xplmFont_Proportional 1
#define xplm_MouseDown 0
#define xplm_MouseUp 1
#define xplm_MouseDrag 2
#define xplm_WindowDecorationRoundRectangle 1
#define xplm_WindowLayerFloatingWindows 0
#define xplmType_Int 1
#define xplmType_Float 2
#define xplmType_Double 4
#define xplmType_FloatArray 8
#define xplmType_IntArray 16
#define xplmType_Data 32

typedef int (*XPLMHandleMouseClick_f)(XPLMWindowID, int, int, XPLMMouseStatus, void *);
typedef void (*XPLMHandleKey_f)(XPLMWindowID, char, XPLMKeyFlags, char, void *, int);
typedef XPLMCursorStatus (*XPLMHandleCursor_f)(XPLMWindowID, int, int, void *);
typedef int (*XPLMHandleMouseWheel_f)(XPLMWindowID, int, int, int, void *);
typedef void (*XPLMHandleRightClick_f)(XPLMWindowID, int, int, void *);
typedef void (*XPLMDrawWindow_f)(XPLMWindowID, void *);

typedef struct {
    int structSize;
    int left, top, right, bottom, visible;
    XPLMDrawWindow_f drawWindowFunc;
    XPLMHandleMouseClick_f handleMouseClickFunc;
    XPLMHandleKey_f handleKeyFunc;
    XPLMHandleCursor_f handleCursorFunc;
    XPLMHandleMouseWheel_f handleMouseWheelFunc;
    void *refcon;
    int decorateAsFloatingWindow;
    int layer;
    XPLMHandleRightClick_f handleRightClickFunc;
} XPLMCreateWindow_t;

XPLMWindowID XPLMCreateWindowEx(XPLMCreateWindow_t *);
void XPLMDestroyWindow(XPLMWindowID);
void XPLMSetWindowIsVisible(XPLMWindowID, int);
void XPLMTakeKeyboardFocus(XPLMWindowID);
void XPLMGetWindowGeometry(XPLMWindowID, int *, int *, int *, int *);
void XPLMDrawString(float [3], int, int, char *, int *, XPLMFontID);
void XPLMDrawTranslucentDarkBox(int, int, int, int);
XPLMDataRef XPLMFindDataRef(const char *);
void XPLMGetDatad(XPLMDataRef, double *, int, int);
void XPLMSetDatad(XPLMDataRef, double);
void XPLMGetDatavf(XPLMDataRef, float *, int, int);
XPLMDataRef XPLMRegisterDataAccessor(const char *, int, int, void *, void *, void *, void *,
    XPLMGetDatad_f, XPLMSetDatad_f, void *, void *, void *, void *, void *, void *, void *, void *);
void XPLMUnregisterDataAccessor(XPLMDataRef);
XPLMMenuID XPLMFindPluginsMenu(void);
XPLMMenuID XPLMCreateMenu(const char *, XPLMMenuID, int, XPLMMenuHandler_f, void *);
int XPLMAppendMenuItem(XPLMMenuID, const char *, void *, int);
void XPLMRegisterFlightLoopCallback(float (*)(float, float, int, void *), float, void *);
void XPLMUnregisterFlightLoopCallback(float (*)(float, float, int, void *), void *);
void XPLMDebugString(const char *);

PLUGIN_API int XPluginStart(char *, char *, char *);
PLUGIN_API void XPluginStop(void);
PLUGIN_API int XPluginEnable(void);
PLUGIN_API void XPluginDisable(void);
PLUGIN_API void XPluginReceiveMessage(XPLMPluginID, int, void *);
#endif
