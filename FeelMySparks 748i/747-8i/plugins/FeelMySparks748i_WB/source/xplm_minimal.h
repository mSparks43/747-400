#ifndef XPLM_MINIMAL_H
#define XPLM_MINIMAL_H

#define PLUGIN_API __attribute__((visibility("default")))

void XPLMSetGraphicsState(int, int, int, int, int, int, int, int);

typedef void *XPLMWindowID;
typedef void *XPLMDataRef;
typedef void *XPLMMenuID;
typedef int XPLMMouseStatus;
typedef int XPLMFontID;
typedef int XPLMPluginID;
typedef int XPLMCursorStatus;
typedef void (*XPLMMenuHandler_f)(void *, void *);
typedef void (*XPLMDrawWindow_f)(XPLMWindowID, void *);
typedef int (*XPLMHandleMouseClick_f)(XPLMWindowID, int, int, XPLMMouseStatus, void *);

typedef struct {
    int structSize;
    int left;
    int top;
    int right;
    int bottom;
    int visible;
    XPLMDrawWindow_f drawWindowFunc;
    XPLMHandleMouseClick_f handleMouseClickFunc;
    void *handleKeyFunc;
    void *handleCursorFunc;
    void *handleMouseWheelFunc;
    void *refcon;
    int decorateAsFloatingWindow;
    int layer;
    void *handleRightClickFunc;
} XPLMCreateWindow_t;

#define xplm_MouseDown 0
#define xplm_MouseUp 1
#define xplm_MouseDrag 2
#define xplm_WindowDecorationRoundRectangle 1
#define xplm_WindowLayerFloatingWindows 0
#define xplmType_Int 1
#define xplmType_Float 2
#define xplmType_Double 4
#define xplmType_FloatArray 8
#define xplmFont_Proportional 1

XPLMWindowID XPLMCreateWindowEx(XPLMCreateWindow_t *);
void XPLMDestroyWindow(XPLMWindowID);
void XPLMSetWindowIsVisible(XPLMWindowID, int);
void XPLMGetWindowGeometry(XPLMWindowID, int *, int *, int *, int *);
void XPLMGetScreenBoundsGlobal(int *, int *, int *, int *);
void XPLMDrawString(float *, int, int, char *, int *, XPLMFontID);
XPLMDataRef XPLMFindDataRef(const char *);
int XPLMGetDataRefTypes(XPLMDataRef);
int XPLMCanWriteDataRef(XPLMDataRef);
int XPLMGetDatai(XPLMDataRef);
float XPLMGetDataf(XPLMDataRef);
void XPLMGetDatad(XPLMDataRef, double *, int, int);
void XPLMSetDatai(XPLMDataRef, int);
void XPLMSetDataf(XPLMDataRef, float);
void XPLMSetDatad(XPLMDataRef, double);
int XPLMGetDatavf(XPLMDataRef, float *, int, int);
void XPLMSetDatavf(XPLMDataRef, float *, int, int);
void XPLMRegisterFlightLoopCallback(float (*)(float, float, int, void *), float, void *);
void XPLMUnregisterFlightLoopCallback(float (*)(float, float, int, void *), void *);
void XPLMDebugString(const char *);
XPLMMenuID XPLMFindPluginsMenu(void);
int XPLMAppendMenuItem(XPLMMenuID, char *, void *, int);
XPLMMenuID XPLMCreateMenu(char *, XPLMMenuID, int, XPLMMenuHandler_f, void *);
void XPLMDestroyMenu(XPLMMenuID);

PLUGIN_API int XPluginStart(char *, char *, char *);
PLUGIN_API void XPluginStop(void);
PLUGIN_API int XPluginEnable(void);
PLUGIN_API void XPluginDisable(void);
PLUGIN_API void XPluginReceiveMessage(XPLMPluginID, int, void *);

#endif
