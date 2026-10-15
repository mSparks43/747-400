extern "C" {
#include "xplm_minimal.h"
#include <OpenGL/gl.h>
}

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

namespace {

struct SignalRow {
    std::string label;
    std::string dataref;
    const char *format;
    XPLMDataRef ref;
    double value;
    bool available;
};

std::vector<SignalRow> rowsFlight;
std::vector<SignalRow> rowsFbw;
std::vector<SignalRow> rowsControls;
std::vector<SignalRow> rowsSupport;
std::vector<SignalRow> *activeRows = &rowsFlight;

XPLMWindowID gWindow = nullptr;
XPLMMenuID gMenu = nullptr;
int gLeft = 50, gTop = 760, gRight = 620, gBottom = 120;
int gTab = 0;
double gLastSample = -100.0;

static void addRow(std::vector<SignalRow> &rows, const char *label, const char *dataref, const char *format) {
    rows.push_back({label, dataref, format, nullptr, 0.0, false});
}

static void ensureRows() {
    if (!rowsFlight.empty()) return;

    addRow(rowsFlight, "Time (s)", "sim/time/total_running_time_sec", "%.1f");
    addRow(rowsFlight, "IAS (kt)", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot", "%.1f");
    addRow(rowsFlight, "Mach", "sim/cockpit2/gauges/indicators/machno", "%.3f");
    addRow(rowsFlight, "Clmb rate (fpm)", "sim/flightmodel/position/vh_ind_fpm", "%.0f");
    addRow(rowsFlight, "Ground speed (m/s)", "sim/flightmodel/position/groundspeed", "%.1f");
    addRow(rowsFlight, "Roll angle (deg)", "sim/flightmodel/position/phi", "%.1f");
    addRow(rowsFlight, "Pitch angle (deg)", "sim/flightmodel/position/theta", "%.1f");
    addRow(rowsFlight, "Heading (deg)", "sim/flightmodel/position/psi", "%.1f");
    addRow(rowsFlight, "Roll rate (deg/s)", "sim/flightmodel/position/P", "%.2f");
    addRow(rowsFlight, "Pitch rate (deg/s)", "sim/flightmodel/position/Q", "%.2f");
    addRow(rowsFlight, "Yaw rate (deg/s)", "sim/flightmodel/position/R", "%.2f");
    addRow(rowsFlight, "Normal G", "sim/flightmodel/forces/g_nrml", "%.3f");
    addRow(rowsFlight, "On ground", "sim/flightmodel/failures/onground_any", "%.0f");
    addRow(rowsFlight, "Flap ratio (sim)", "sim/cockpit2/controls/flap_ratio", "%.3f");
    addRow(rowsFlight, "Flap ratio (B747)", "laminar/B747/cablecontrols/flap_ratio", "%.3f");

    addRow(rowsFbw, "FBW enabled", "laminar/B747/fbw/enabled", "%.0f");
    addRow(rowsFbw, "MLA enabled", "laminar/B747/fbw/mla_enabled", "%.0f");
    addRow(rowsFbw, "Droop enabled", "laminar/B747/fbw/droop_enabled", "%.0f");
    addRow(rowsFbw, "Buffet enabled", "laminar/B747/fbw/buffet_enabled", "%.0f");
    addRow(rowsFbw, "Roll respawn target", "laminar/B747/fbw/roll_response_gain", "%.4f");
    addRow(rowsFbw, "Roll damping target", "laminar/B747/fbw/roll_rate_damping_gain", "%.4f");
    addRow(rowsFbw, "Low-speed blend", "laminar/B747/fbw/low_speed_blend", "%.3f");
    addRow(rowsFbw, "Roll response effect", "laminar/B747/fbw/roll_response_effect", "%.4f");
    addRow(rowsFbw, "Roll damping effect", "laminar/B747/fbw/roll_rate_damping_effect", "%.4f");
    addRow(rowsFbw, "MLA demand", "laminar/B747/fbw/mla_demand", "%.3f");
    addRow(rowsFbw, "Aileron droop", "laminar/B747/fbw/aileron_droop_ratio", "%.3f");
    addRow(rowsFbw, "FBW active", "laminar/B747/fbw/active", "%.0f");
    addRow(rowsFbw, "AP servos", "laminar/B747/autopilot/servos_on", "%.0f");

    addRow(rowsControls, "Left outer aileron", "laminar/B747/flt_ctrls/l_aileron_outer", "%.2f");
    addRow(rowsControls, "Right outer aileron", "laminar/B747/flt_ctrls/r_aileron_outer", "%.2f");
    addRow(rowsControls, "Left inner aileron", "laminar/B747/flt_ctrls/l_aileron_inner", "%.2f");
    addRow(rowsControls, "Right inner aileron", "laminar/B747/flt_ctrls/r_aileron_inner", "%.2f");
    addRow(rowsControls, "Left outer control", "laminar/B747/cablecontrols/left_outer_aileron", "%.2f");
    addRow(rowsControls, "Right outer control", "laminar/B747/cablecontrols/right_outer_aileron", "%.2f");
    addRow(rowsControls, "Left outer lockout", "laminar/B747/flt_ctrls/left_outer_aileron_lockout", "%.0f");
    addRow(rowsControls, "Right outer lockout", "laminar/B747/flt_ctrls/right_outer_aileron_lockout", "%.0f");
    addRow(rowsControls, "Speedbrake 1/2", "laminar/B747/cablecontrols/speedbrake1", "%.2f");
    addRow(rowsControls, "Speedbrake 5/8", "laminar/B747/cablecontrols/speedbrake2", "%.2f");

    addRow(rowsSupport, "Hyd 1 use pressure", "laminar/B747/hydraulics/pressure_use_1", "%.0f");
    addRow(rowsSupport, "Hyd 2 use pressure", "laminar/B747/hydraulics/pressure_use_2", "%.0f");
    addRow(rowsSupport, "Hyd 3 use pressure", "laminar/B747/hydraulics/pressure_use_3", "%.0f");
    addRow(rowsSupport, "Hyd 4 use pressure", "laminar/B747/hydraulics/pressure_use_4", "%.0f");
    addRow(rowsSupport, "ERP stick shaker", "sim/aircraft/forcefeedback/acf_ff_stickshaker", "%.3f");
    addRow(rowsSupport, "Vertical speed", "sim/flightmodel/position/vh_ind", "%.1f");
}

static void collectRows(std::vector<SignalRow> &rows) {
    for (size_t i = 0; i < rows.size(); ++i) {
        if (rows[i].ref == nullptr) rows[i].ref = XPLMFindDataRef(rows[i].dataref.c_str());
        if (rows[i].ref == nullptr) { rows[i].available = false; continue; }
        double value = 0.0;
        XPLMGetDatad(rows[i].ref, &value, 0, 1);
        if (!std::isfinite(value)) value = 0.0;
        rows[i].value = value;
        rows[i].available = true;
    }
}

static void collectAll() {
    collectRows(rowsFlight);
    collectRows(rowsFbw);
    collectRows(rowsControls);
    collectRows(rowsSupport);
}

static void switchTab(int tab) {
    gTab = tab;
    if (tab == 0) activeRows = &rowsFlight;
    else if (tab == 1) activeRows = &rowsFbw;
    else if (tab == 2) activeRows = &rowsControls;
    else activeRows = &rowsSupport;
}

static void drawRect(int left, int top, int right, int bottom, float r, float g, float b, float a) {
    if (left > right) std::swap(left, right);
    if (bottom > top) std::swap(bottom, top);
    glColor4f(r, g, b, a);
    glBegin(GL_QUADS);
    glVertex2i(left, top);
    glVertex2i(right, top);
    glVertex2i(right, bottom);
    glVertex2i(left, bottom);
    glEnd();
}

static int buttonTop() { return gTop - 40; }

static void drawText(int x, int y, const char *text, float r, float g, float b) {
    float color[3] = {r, g, b};
    char buffer[256];
    std::snprintf(buffer, sizeof(buffer), "%s", text);
    XPLMDrawString(color, x, y, buffer, nullptr, xplmFont_Basic);
}

static void drawRows(const std::vector<SignalRow> &rows, int x, int y) {
    char label[192];
    char value[64];
    for (size_t i = 0; i < rows.size() && i < 20; ++i) {
        int rowY = y - static_cast<int>(i * 16);
        std::snprintf(label, sizeof(label), "%-30s", rows[i].label.c_str());
        drawText(x, rowY, label, 0.78f, 0.78f, 0.78f);
        if (rows[i].available) {
            std::snprintf(value, sizeof(value), rows[i].format, rows[i].value);
            drawText(x + 250, rowY, value, 0.35f, 1.0f, 0.45f);
        } else {
            drawText(x + 250, rowY, "---", 0.4f, 0.4f, 0.4f);
        }
    }
}

static const char *tabName(int tab) {
    switch (tab) {
        case 0: return "Flight";
        case 1: return "FBW";
        case 2: return "Controls";
        default: return "Support";
    }
}

static int contains(int x, int y, int left, int top, int right, int bottom) {
    if (left > right) std::swap(left, right);
    if (bottom > top) std::swap(bottom, top);
    return x >= left && x <= right && y <= top && y >= bottom;
}

static void drawWindow(XPLMWindowID, void *) {
    XPLMGetWindowGeometry(gWindow, &gLeft, &gTop, &gRight, &gBottom);
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glPushMatrix();
    XPLMSetGraphicsState(0, 0, 0, 0, 0, 0, 0, 0);

    /* Black work surface plus a very subtle grid. */
    drawRect(gLeft, gTop, gRight, gBottom, 0.0f, 0.0f, 0.0f, 1.0f);
    glColor4f(0.12f, 0.16f, 0.30f, 0.45f);
    glLineWidth(1.0f);
    glBegin(GL_LINES);
    for (int y = gTop; y >= gBottom; y -= 16) {
        glVertex2i(gLeft, y);
        glVertex2i(gRight, y);
    }
    for (int x = gLeft; x <= gRight; x += 150) {
        glVertex2i(x, gTop);
        glVertex2i(x, gBottom);
    }
    glEnd();

    /* Tab strip. */
    int yTab = gTop - 18;
    for (int i = 0; i < 4; ++i) {
        int left = gLeft + 8 + i * 138;
        int right = left + 126;
        drawRect(left, yTab + 6, right, yTab - 16, (i == gTab) ? 0.08f : 0.03f, (i == gTab) ? 0.12f : 0.03f, (i == gTab) ? 0.25f : 0.03f, 0.95f);
        drawText(left + 42, yTab - 12, tabName(i), 1.0f, 1.0f, (i == gTab) ? 0.4f : 0.75f);
    }

    drawText(gLeft + 10, gTop - 40, "FeelMySparks FBW Debug - read-only", 1.0f, 1.0f, 1.0f);
    if (gTab == 0) drawRows(rowsFlight, gLeft + 8, gTop - 76);
    if (gTab == 1) drawRows(rowsFbw, gLeft + 8, gTop - 76);
    if (gTab == 2) drawRows(rowsControls, gLeft + 8, gTop - 76);
    if (gTab == 3) drawRows(rowsSupport, gLeft + 8, gTop - 76);

    int logTop = gTop - 42;
    drawRect(gLeft + 8, logTop, gLeft + 128, logTop - 24, 0.12f, 0.15f, 0.40f, 0.95f);
    drawRect(gLeft + 136, logTop, gLeft + 246, logTop - 24, 0.12f, 0.12f, 0.12f, 0.95f);
    drawText(gLeft + 36, logTop - 18, "SNAPSHOT", 1.0f, 1.0f, 1.0f);
    drawText(gLeft + 180, logTop - 18, "HIDE", 1.0f, 1.0f, 1.0f);
    drawText(gLeft + 256, logTop - 18, "Click tabs to change pages", 0.60f, 0.60f, 0.60f);

    glPopMatrix();
    glPopAttrib();
    XPLMSetGraphicsState(0, 0, 0, 0, 0, 0, 0, 0);
}

static int handleMouseClick(XPLMWindowID, int x, int y, XPLMMouseStatus status, void *) {
    XPLMGetWindowGeometry(gWindow, &gLeft, &gTop, &gRight, &gBottom);
    if (x < gLeft || x > gRight || y > gTop || y < gBottom) return 1;
    if (status != xplm_MouseDown) return 1;

    int tabY = gTop - 18;
    for (int i = 0; i < 4; ++i) {
        int left = gLeft + 8 + i * 138;
        int right = left + 126;
        if (contains(x, y, left, tabY + 6, right, tabY - 16)) {
            switchTab(i);
            return 1;
        }
    }

    int top = gTop - 42;
    if (contains(x, y, gLeft + 8, top, gLeft + 128, top - 24)) {
        char message[8192];
        size_t used = std::snprintf(message, sizeof(message), "FBW Debug snapshot");
        std::vector<SignalRow> *banks[4] = {&rowsFlight, &rowsFbw, &rowsControls, &rowsSupport};
        for (int bankIndex = 0; bankIndex < 4; ++bankIndex) {
            for (size_t i = 0; i < (*banks[bankIndex]).size() && used < sizeof(message) - 100; ++i) {
                if (!(*banks[bankIndex])[i].available) continue;
                used += std::snprintf(message + used, sizeof(message) - used, "; %s=%.3f", (*banks[bankIndex])[i].label.c_str(), (*banks[bankIndex])[i].value);
            }
        }
        XPLMDebugString(message);
        return 1;
    }

    if (contains(x, y, gLeft + 136, top, gLeft + 246, top - 24)) {
        if (gWindow != nullptr) XPLMSetWindowIsVisible(gWindow, 0);
        return 1;
    }
    return 1;
}

static void showWindow() {
    if (gWindow != nullptr) XPLMSetWindowIsVisible(gWindow, 1);
}

static void debugMenuHandler(void *menuRef, void *itemRef) {
    (void)menuRef;
    if (itemRef == (void *)1) showWindow();
}

float flightLoop(float, float, int, void *) {
    gTab = gTab;
    ensureRows();
    double now = 0.0;
    XPLMDataRef timeRef = XPLMFindDataRef("sim/time/total_running_time_sec");
    if (timeRef != nullptr) XPLMGetDatad(timeRef, &now, 0, 1);
    if (!std::isfinite(now)) now = 0.0;
    collectAll();
    gLastSample = now;
    return 0.25f;
}

} // namespace

extern "C" PLUGIN_API int XPluginStart(char *outName, char *outSig, char *outDesc) {
    if (outName == nullptr || outSig == nullptr || outDesc == nullptr) return 0;
    std::strcpy(outName, "FeelMySparks 748i FBW Debug");
    std::strcpy(outSig, "feelmysparks.748i.fbw.debug");
    std::strcpy(outDesc, "Read-only instrumentation window for the 747-8i FBW prototype");

    ensureRows();
    activeRows = &rowsFlight;
    switchTab(0);
    return 1;
}

extern "C" PLUGIN_API void XPluginStop(void) {
    if (gWindow != nullptr) {
        XPLMDestroyWindow(gWindow);
        gWindow = nullptr;
    }
}

extern "C" PLUGIN_API int XPluginEnable(void) {
    XPLMRegisterFlightLoopCallback(flightLoop, 0.25f, nullptr);
    XPLMMenuID pluginsMenu = XPLMFindPluginsMenu();
    if (pluginsMenu != nullptr && gMenu == nullptr) {
        int item = XPLMAppendMenuItem(pluginsMenu, "FeelMySparks FBW Debug", nullptr, 0);
        gMenu = XPLMCreateMenu("FeelMySparks 748i FBW Debug", pluginsMenu, item, debugMenuHandler, nullptr);
        if (gMenu != nullptr) {
            XPLMAppendMenuItem(gMenu, "Show Debug Window", (void *)1, 0);
        }
    }

    XPLMCreateWindow_t params{};
    params.structSize = sizeof(params);
    params.left = 50;
    params.top = 760;
    params.right = 620;
    params.bottom = 120;
    params.visible = 1;
    params.drawWindowFunc = drawWindow;
    params.handleMouseClickFunc = handleMouseClick;
    params.handleKeyFunc = nullptr;
    params.handleCursorFunc = nullptr;
    params.handleMouseWheelFunc = nullptr;
    params.refcon = nullptr;
    params.decorateAsFloatingWindow = xplm_WindowDecorationRoundRectangle;
    params.layer = xplm_WindowLayerFloatingWindows;
    params.handleRightClickFunc = nullptr;
    gWindow = XPLMCreateWindowEx(&params);
    if (gWindow != nullptr) XPLMSetWindowIsVisible(gWindow, 1);
    return 1;
}

extern "C" PLUGIN_API void XPluginDisable(void) {
    XPLMUnregisterFlightLoopCallback(flightLoop, nullptr);
    if (gWindow != nullptr) XPLMSetWindowIsVisible(gWindow, 0);
}

extern "C" PLUGIN_API void XPluginReceiveMessage(XPLMPluginID, int, void *) {
}
