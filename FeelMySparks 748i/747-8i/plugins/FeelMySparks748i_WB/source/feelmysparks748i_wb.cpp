extern "C" {
#include "xplm_minimal.h"
#include <OpenGL/gl.h>
}

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>

namespace {
constexpr int kTankCount = 9;
constexpr double kTankCapacity[kTankCount] = {
    72000.0, 17500.0, 17500.0, 17500.0, 17500.0, 8500.0, 8500.0, 12000.0, 15000.0
};
constexpr double kPresetFuel[] = {0.0, 35000.0, 120000.0, 186000.0};
constexpr double kPayloadMaximumKg = 75000.0;
constexpr double kPayloadStepKg = 500.0;
constexpr double kFuelStepKg = 250.0;
constexpr double kFuelLargeStepKg = 1000.0;

XPLMWindowID gWindow = nullptr;
XPLMMenuID gMenu = nullptr;
XPLMDataRef gGrossWeightRef = nullptr;
XPLMDataRef gPayloadRef = nullptr;
XPLMDataRef gFuelRef = nullptr;
XPLMDataRef gOnGroundRef = nullptr;
float gTanks[kTankCount] = {};
int gSelectedTank = 0;
int gWindowLeft = 0;
int gWindowTop = 0;
int gWindowRight = 0;
int gWindowBottom = 0;
bool gOnGround = false;
bool gFuelWritable = false;
bool gPayloadWritable = false;
char gNotice[128] = "Ready - use the on-screen controls";

struct Rect {
    int left;
    int top;
    int right;
    int bottom;
};

double readScalar(XPLMDataRef ref, double fallback = 0.0) {
    if (ref == nullptr) return fallback;
    const int types = XPLMGetDataRefTypes(ref);
    double value = fallback;
    if ((types & xplmType_Double) != 0) XPLMGetDatad(ref, &value, 0, 1);
    else if ((types & xplmType_Float) != 0) value = XPLMGetDataf(ref);
    else if ((types & xplmType_Int) != 0) value = XPLMGetDatai(ref);
    return std::isfinite(value) ? value : fallback;
}

void writeScalar(XPLMDataRef ref, double value) {
    if (ref == nullptr || !std::isfinite(value)) return;
    const int types = XPLMGetDataRefTypes(ref);
    if ((types & xplmType_Double) != 0) XPLMSetDatad(ref, value);
    else if ((types & xplmType_Float) != 0) XPLMSetDataf(ref, static_cast<float>(value));
    else if ((types & xplmType_Int) != 0) XPLMSetDatai(ref, static_cast<int>(value));
}

void refreshRefs() {
    if (gGrossWeightRef == nullptr) gGrossWeightRef = XPLMFindDataRef("sim/flightmodel/weight/m_total");
    if (gPayloadRef == nullptr) gPayloadRef = XPLMFindDataRef("sim/flightmodel/weight/m_fixed");
    if (gFuelRef == nullptr) gFuelRef = XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity");
    if (gOnGroundRef == nullptr) gOnGroundRef = XPLMFindDataRef("sim/flightmodel/failures/onground_any");

    gFuelWritable = gFuelRef != nullptr && XPLMCanWriteDataRef(gFuelRef) != 0;
    gPayloadWritable = gPayloadRef != nullptr && XPLMCanWriteDataRef(gPayloadRef) != 0;
    gOnGround = gOnGroundRef != nullptr && readScalar(gOnGroundRef) > 0.5;
}

void refreshTanks() {
    if (gFuelRef == nullptr) return;
    float fresh[kTankCount] = {};
    const int count = XPLMGetDatavf(gFuelRef, fresh, 0, kTankCount);
    if (count < kTankCount) {
        std::snprintf(gNotice, sizeof(gNotice), "Fuel tank data unavailable");
        return;
    }
    for (int i = 0; i < kTankCount; ++i) {
        double amount = (i < count) ? fresh[i] : 0.0;
        if (!std::isfinite(amount)) amount = 0.0;
        gTanks[i] = static_cast<float>(std::max(0.0, std::min(kTankCapacity[i], amount)));
    }
}

double totalFuel() {
    double sum = 0.0;
    for (float tank : gTanks) sum += tank;
    return sum;
}

bool setTank(int index, double amount) {
    if (!gOnGround) {
        std::snprintf(gNotice, sizeof(gNotice), "Fuel loading is locked while airborne");
        return false;
    }
    if (!gFuelWritable || gFuelRef == nullptr) {
        std::snprintf(gNotice, sizeof(gNotice), "X-Plane fuel dataref is read-only");
        return false;
    }
    amount = std::max(0.0, std::min(kTankCapacity[index], amount));
    gTanks[index] = static_cast<float>(amount);
    float output[kTankCount];
    std::memcpy(output, gTanks, sizeof(output));
    XPLMSetDatavf(gFuelRef, output, 0, kTankCount);
    refreshTanks();
    if (std::abs(gTanks[index] - amount) > 1.0) {
        std::snprintf(gNotice, sizeof(gNotice), "X-Plane rejected the tank update");
        return false;
    }
    std::snprintf(gNotice, sizeof(gNotice), "Tank %d set to %.0f kg", index + 1, amount);
    return true;
}

bool adjustPayload(double delta) {
    if (!gOnGround) {
        std::snprintf(gNotice, sizeof(gNotice), "Payload loading is locked while airborne");
        return false;
    }
    if (!gPayloadWritable || gPayloadRef == nullptr) {
        std::snprintf(gNotice, sizeof(gNotice), "X-Plane payload dataref is read-only");
        return false;
    }
    const double current = readScalar(gPayloadRef);
    const double target = std::max(0.0, std::min(kPayloadMaximumKg, current + delta));
    writeScalar(gPayloadRef, target);
    const double applied = readScalar(gPayloadRef, -1.0);
    if (applied < 0.0 || std::abs(applied - target) > 1.0) {
        std::snprintf(gNotice, sizeof(gNotice), "X-Plane rejected payload change");
        return false;
    }
    std::snprintf(gNotice, sizeof(gNotice), "Payload set to %.0f kg", applied);
    return true;
}

bool setFuelPreset(double target) {
    if (!gOnGround) {
        std::snprintf(gNotice, sizeof(gNotice), "Fuel loading is locked while airborne");
        return false;
    }
    if (!gFuelWritable || gFuelRef == nullptr) {
        std::snprintf(gNotice, sizeof(gNotice), "X-Plane fuel dataref is read-only");
        return false;
    }

    double remaining = std::min(target, [&]() {
        double capacity = 0.0;
        for (double value : kTankCapacity) capacity += value;
        return capacity;
    }());
    float output[kTankCount] = {};
    constexpr int priority[kTankCount] = {1, 2, 3, 4, 0, 7, 5, 6, 8};
    for (int index : priority) {
        const double amount = std::min(kTankCapacity[index], remaining);
        output[index] = static_cast<float>(amount);
        remaining -= amount;
    }
    XPLMSetDatavf(gFuelRef, output, 0, kTankCount);
    refreshTanks();
    if (std::abs(totalFuel() - (target - remaining)) > 10.0) {
        std::snprintf(gNotice, sizeof(gNotice), "X-Plane rejected the fuel preset");
        return false;
    }
    std::snprintf(gNotice, sizeof(gNotice), "Fuel preset applied - %.0f kg", totalFuel());
    return true;
}

void drawRect(const Rect &r, const float color[3], float alpha = 1.0f) {
    glColor4f(color[0], color[1], color[2], alpha);
    glBegin(GL_QUADS);
    glVertex2i(r.left, r.top);
    glVertex2i(r.right, r.top);
    glVertex2i(r.right, r.bottom);
    glVertex2i(r.left, r.bottom);
    glEnd();
}

void drawText(const float color[3], int x, int y, const char *text) {
    float rgb[3] = {color[0], color[1], color[2]};
    XPLMDrawString(rgb, x, y, const_cast<char *>(text), nullptr, xplmFont_Proportional);
}

Rect centeredButton(int centerX, int centerY, int width, int height) {
    return {centerX - width / 2, centerY + height / 2,
            centerX + width / 2, centerY - height / 2};
}

bool contains(const Rect &r, int x, int y) {
    return x >= r.left && x <= r.right && y <= r.top && y >= r.bottom;
}

void button(const Rect &r, const char *label, bool enabled,
            const float enabledColor[3], const float disabledColor[3],
            const float textColor[3]) {
    drawRect(r, enabled ? enabledColor : disabledColor);
    drawText(textColor, r.left + 8, r.bottom + (r.top - r.bottom) / 2 - 5, label);
}

void drawWindow(XPLMWindowID window, void *) {
    XPLMGetWindowGeometry(window, &gWindowLeft, &gWindowTop, &gWindowRight, &gWindowBottom);
    const int left = gWindowLeft;
    const int top = gWindowTop;
    const int right = gWindowRight;
    const int width = right - left;
    const int mid = left + width / 2;
    const bool ready = gGrossWeightRef != nullptr;
    const double gross = readScalar(gGrossWeightRef);
    const double payload = readScalar(gPayloadRef);
    const double selectedFuel = gTanks[gSelectedTank];

    const float bg[3] = {0.025f, 0.043f, 0.067f};
    const float surface[3] = {0.055f, 0.083f, 0.117f};
    const float card[3] = {0.080f, 0.119f, 0.157f};
    const float cyan[3] = {0.10f, 0.73f, 0.86f};
    const float blue[3] = {0.12f, 0.36f, 0.63f};
    const float disabled[3] = {0.16f, 0.20f, 0.24f};
    const float white[3] = {0.95f, 0.97f, 0.99f};
    const float muted[3] = {0.58f, 0.69f, 0.78f};
    const float green[3] = {0.15f, 0.59f, 0.38f};
    const float amber[3] = {0.67f, 0.39f, 0.10f};

    glPushAttrib(GL_ALL_ATTRIB_BITS);
    XPLMSetGraphicsState(0, 0, 0, 0, 0, 0, 0, 0);
    glDisable(GL_LINE_SMOOTH);
    drawRect({left, top, right, gWindowBottom}, bg);
    drawRect({left, top, right, top - 70}, surface);
    drawRect({left, top - 70, right, top - 74}, cyan);
    drawRect({left + 24, top - 103, right - 24, top - 174}, card);
    drawRect({left + 24, top - 196, mid - 12, gWindowBottom + 66}, surface);
    drawRect({mid + 12, top - 196, right - 24, gWindowBottom + 66}, surface);
    glPopAttrib();
    XPLMSetGraphicsState(0, 0, 0, 0, 0, 0, 0, 0);

    drawText(cyan, left + 28, top - 42, "FS");
    drawText(white, left + 78, top - 35, "747-8i  |  WEIGHT & FUEL LOADING");
    drawText(gOnGround ? green : amber, right - 238, top - 35,
             gOnGround ? "GROUND CONTROLS ACTIVE" : "AIRBORNE - LOCKED");
    drawText(muted, left + 30, top - 125, "GROSS MASS");
    drawText(muted, left + width / 4, top - 125, "PAYLOAD");
    drawText(muted, left + width / 2, top - 125, "FUEL TOTAL");
    drawText(muted, left + (width * 3) / 4, top - 125, "SELECTED TANK");

    char value[96];
    std::snprintf(value, sizeof(value), "%.0f kg", gross);
    drawText(white, left + 30, top - 155, value);
    std::snprintf(value, sizeof(value), "%.0f kg", payload);
    drawText(white, left + width / 4, top - 155, value);
    std::snprintf(value, sizeof(value), "%.0f kg", totalFuel());
    drawText(white, left + width / 2, top - 155, value);
    std::snprintf(value, sizeof(value), "%d / %d", gSelectedTank + 1, kTankCount);
    drawText(white, left + (width * 3) / 4, top - 155, value);

    const int leftCol = left + 42;
    const int rightCol = mid + 30;
    const int leftWidth = mid - left - 72;
    const int rightWidth = right - mid - 72;
    drawText(cyan, leftCol, top - 224, "PAYLOAD ADJUSTMENT");
    drawText(muted, leftCol, top - 249, "Click a step to apply directly to X-Plane");
    drawText(white, leftCol, top - 301, "Decrease / increase payload");
    const int payloadY = top - 357;
    const int payloadButtonW = std::max(52, (leftWidth - 18) / 4);
    button(centeredButton(leftCol + payloadButtonW / 2, payloadY, payloadButtonW, 38),
           "-1000", gOnGround && gPayloadWritable, blue, disabled, white);
    button(centeredButton(leftCol + payloadButtonW * 1.5 + 6, payloadY, payloadButtonW, 38),
           "-500", gOnGround && gPayloadWritable, blue, disabled, white);
    button(centeredButton(leftCol + payloadButtonW * 2.5 + 12, payloadY, payloadButtonW, 38),
           "+500", gOnGround && gPayloadWritable, blue, disabled, white);
    button(centeredButton(leftCol + payloadButtonW * 3.5 + 18, payloadY, payloadButtonW, 38),
           "+1000", gOnGround && gPayloadWritable, blue, disabled, white);

    drawText(cyan, rightCol, top - 224, "INDIVIDUAL FUEL TANK");
    const char *tankNames[kTankCount] = {
        "Center wing", "No. 1 main", "No. 2 main", "No. 3 main", "No. 4 main",
        "No. 2 reserve", "No. 3 reserve", "Horizontal stabilizer", "Additional tank"
    };
    drawText(white, rightCol, top - 260, tankNames[gSelectedTank]);
    std::snprintf(value, sizeof(value), "%.0f / %.0f kg", selectedFuel, kTankCapacity[gSelectedTank]);
    drawText(muted, rightCol, top - 283, value);

    const int selectY = top - 330;
    button(centeredButton(rightCol + 48, selectY, 84, 36), "< PREV", true, blue, disabled, white);
    button(centeredButton(rightCol + rightWidth - 48, selectY, 84, 36), "NEXT >", true, blue, disabled, white);

    const int fuelY = top - 390;
    const int fuelButtonW = std::max(52, (rightWidth - 18) / 4);
    button(centeredButton(rightCol + fuelButtonW / 2, fuelY, fuelButtonW, 38),
           "-1000", gOnGround && gFuelWritable, blue, disabled, white);
    button(centeredButton(rightCol + fuelButtonW * 1.5 + 6, fuelY, fuelButtonW, 38),
           "-250", gOnGround && gFuelWritable, blue, disabled, white);
    button(centeredButton(rightCol + fuelButtonW * 2.5 + 12, fuelY, fuelButtonW, 38),
           "+250", gOnGround && gFuelWritable, blue, disabled, white);
    button(centeredButton(rightCol + fuelButtonW * 3.5 + 18, fuelY, fuelButtonW, 38),
           "+1000", gOnGround && gFuelWritable, blue, disabled, white);

    drawText(cyan, leftCol, top - 420, "FUEL PRESETS");
    const char *presetNames[] = {"EMPTY", "STANDARD 35T", "HIGH 120T", "FULL 186T"};
    const int presetY = top - 476;
    const int presetW = std::max(76, (width - 80) / 4);
    for (int i = 0; i < 4; ++i) {
        button(centeredButton(left + 40 + presetW * i + presetW / 2, presetY,
                              presetW - 8, 42),
               presetNames[i], gOnGround && gFuelWritable, i == 3 ? green : blue, disabled, white);
    }
    drawText(muted, leftCol, gWindowBottom + 25, gNotice);
    if (!ready) drawText(amber, rightCol, top - 450, "Waiting for aircraft weight data");
}

enum class Action {
    None, PayloadMinusLarge, PayloadMinus, PayloadPlus, PayloadPlusLarge,
    TankPrevious, TankNext, FuelMinusLarge, FuelMinus, FuelPlus, FuelPlusLarge,
    PresetEmpty, PresetStandard, PresetHigh, PresetFull
};

Action hitTest(int x, int y, int left, int top, int right) {
    const int width = right - left;
    const int mid = left + width / 2;
    const int leftCol = left + 42;
    const int rightCol = mid + 30;
    const int leftWidth = mid - left - 72;
    const int rightWidth = right - mid - 72;
    const int payloadY = top - 357;
    const int payloadButtonW = std::max(52, (leftWidth - 18) / 4);
    const Rect payloadRects[] = {
        centeredButton(leftCol + payloadButtonW / 2, payloadY, payloadButtonW, 38),
        centeredButton(leftCol + payloadButtonW * 1.5 + 6, payloadY, payloadButtonW, 38),
        centeredButton(leftCol + payloadButtonW * 2.5 + 12, payloadY, payloadButtonW, 38),
        centeredButton(leftCol + payloadButtonW * 3.5 + 18, payloadY, payloadButtonW, 38)
    };
    const Action payloadActions[] = {Action::PayloadMinusLarge, Action::PayloadMinus,
                                     Action::PayloadPlus, Action::PayloadPlusLarge};
    for (int i = 0; i < 4; ++i) if (contains(payloadRects[i], x, y)) return payloadActions[i];

    const int selectY = top - 330;
    if (contains(centeredButton(rightCol + 48, selectY, 84, 36), x, y)) return Action::TankPrevious;
    if (contains(centeredButton(rightCol + rightWidth - 48, selectY, 84, 36), x, y)) return Action::TankNext;

    const int fuelY = top - 390;
    const int fuelButtonW = std::max(52, (rightWidth - 18) / 4);
    const Rect fuelRects[] = {
        centeredButton(rightCol + fuelButtonW / 2, fuelY, fuelButtonW, 38),
        centeredButton(rightCol + fuelButtonW * 1.5 + 6, fuelY, fuelButtonW, 38),
        centeredButton(rightCol + fuelButtonW * 2.5 + 12, fuelY, fuelButtonW, 38),
        centeredButton(rightCol + fuelButtonW * 3.5 + 18, fuelY, fuelButtonW, 38)
    };
    const Action fuelActions[] = {Action::FuelMinusLarge, Action::FuelMinus,
                                  Action::FuelPlus, Action::FuelPlusLarge};
    for (int i = 0; i < 4; ++i) if (contains(fuelRects[i], x, y)) return fuelActions[i];

    const int presetY = top - 476;
    const int presetW = std::max(76, (width - 80) / 4);
    const Action presetActions[] = {Action::PresetEmpty, Action::PresetStandard,
                                    Action::PresetHigh, Action::PresetFull};
    for (int i = 0; i < 4; ++i) {
        const Rect r = centeredButton(left + 40 + presetW * i + presetW / 2,
                                      presetY, presetW - 8, 42);
        if (contains(r, x, y)) return presetActions[i];
    }
    return Action::None;
}

int clickWindow(XPLMWindowID window, int x, int y, XPLMMouseStatus status, void *) {
    if (status == xplm_MouseUp || status == xplm_MouseDrag) return 1;
    if (status != xplm_MouseDown) return 1;

    int left, top, right, bottom;
    XPLMGetWindowGeometry(window, &left, &top, &right, &bottom);
    const Action action = hitTest(x, y, left, top, right);
    refreshRefs();
    refreshTanks();
    switch (action) {
        case Action::PayloadMinusLarge: adjustPayload(-2.0 * kPayloadStepKg); break;
        case Action::PayloadMinus: adjustPayload(-kPayloadStepKg); break;
        case Action::PayloadPlus: adjustPayload(kPayloadStepKg); break;
        case Action::PayloadPlusLarge: adjustPayload(2.0 * kPayloadStepKg); break;
        case Action::TankPrevious: gSelectedTank = (gSelectedTank + kTankCount - 1) % kTankCount; std::snprintf(gNotice, sizeof(gNotice), "Selected tank %d", gSelectedTank + 1); break;
        case Action::TankNext: gSelectedTank = (gSelectedTank + 1) % kTankCount; std::snprintf(gNotice, sizeof(gNotice), "Selected tank %d", gSelectedTank + 1); break;
        case Action::FuelMinusLarge: setTank(gSelectedTank, gTanks[gSelectedTank] - kFuelLargeStepKg); break;
        case Action::FuelMinus: setTank(gSelectedTank, gTanks[gSelectedTank] - kFuelStepKg); break;
        case Action::FuelPlus: setTank(gSelectedTank, gTanks[gSelectedTank] + kFuelStepKg); break;
        case Action::FuelPlusLarge: setTank(gSelectedTank, gTanks[gSelectedTank] + kFuelLargeStepKg); break;
        case Action::PresetEmpty: setFuelPreset(kPresetFuel[0]); break;
        case Action::PresetStandard: setFuelPreset(kPresetFuel[1]); break;
        case Action::PresetHigh: setFuelPreset(kPresetFuel[2]); break;
        case Action::PresetFull: setFuelPreset(kPresetFuel[3]); break;
        case Action::None: std::snprintf(gNotice, sizeof(gNotice), "Click one of the labeled controls"); break;
    }
    return 1;
}

float flightLoop(float, float, int, void *) {
    refreshRefs();
    refreshTanks();
    return 0.25f;
}

void menuHandler(void *, void *) {
    if (gWindow != nullptr) XPLMSetWindowIsVisible(gWindow, 1);
}
}

extern "C" PLUGIN_API int XPluginStart(char *name, char *signature, char *description) {
    if (name == nullptr || signature == nullptr || description == nullptr) return 0;
    std::strcpy(name, "FeelMySparks 748i Load Control");
    std::strcpy(signature, "feelmysparks.748i.loadcontrol");
    std::strcpy(description, "Direct on-screen payload and fuel controls for the 747-8i");
    refreshRefs();
    refreshTanks();
    return 1;
}

extern "C" PLUGIN_API int XPluginEnable(void) {
    refreshRefs();
    refreshTanks();
    XPLMRegisterFlightLoopCallback(flightLoop, 0.25f, nullptr);
    if (gWindow != nullptr) {
        XPLMSetWindowIsVisible(gWindow, 1);
        return 1;
    }

    int screenLeft = 0, screenTop = 0, screenRight = 0, screenBottom = 0;
    XPLMGetScreenBoundsGlobal(&screenLeft, &screenTop, &screenRight, &screenBottom);
    int screenWidth = screenRight - screenLeft;
    int screenHeight = screenTop - screenBottom;
    if (screenWidth <= 0 || screenHeight <= 0) {
        screenLeft = 0;
        screenTop = 900;
        screenWidth = 1280;
        screenHeight = 900;
    }
    const int width = std::min(920, std::max(640, screenWidth - 24));
    const int height = std::min(640, std::max(540, screenHeight - 32));
    gWindowLeft = screenLeft + (screenWidth - width) / 2;
    gWindowRight = gWindowLeft + width;
    gWindowTop = screenTop - 16;
    gWindowBottom = gWindowTop - height;

    XPLMCreateWindow_t params{};
    params.structSize = sizeof(params);
    params.left = gWindowLeft;
    params.top = gWindowTop;
    params.right = gWindowRight;
    params.bottom = gWindowBottom;
    params.visible = 1;
    params.drawWindowFunc = drawWindow;
    params.handleMouseClickFunc = clickWindow;
    params.decorateAsFloatingWindow = xplm_WindowDecorationRoundRectangle;
    params.layer = xplm_WindowLayerFloatingWindows;
    gWindow = XPLMCreateWindowEx(&params);
    if (gWindow == nullptr) {
        XPLMUnregisterFlightLoopCallback(flightLoop, nullptr);
        XPLMDebugString("[FeelMySparks Load Control] Failed to create modern window\n");
        return 0;
    }

    XPLMMenuID pluginsMenu = XPLMFindPluginsMenu();
    if (pluginsMenu != nullptr) {
        const int item = XPLMAppendMenuItem(pluginsMenu, const_cast<char *>("FeelMySparks Load Control"), nullptr, 0);
        gMenu = XPLMCreateMenu(const_cast<char *>("FeelMySparks Load Control"), pluginsMenu, item,
                               menuHandler, nullptr);
    }
    return 1;
}

extern "C" PLUGIN_API void XPluginStop(void) {
    XPLMUnregisterFlightLoopCallback(flightLoop, nullptr);
    if (gWindow != nullptr) {
        XPLMDestroyWindow(gWindow);
        gWindow = nullptr;
    }
    if (gMenu != nullptr) {
        XPLMDestroyMenu(gMenu);
        gMenu = nullptr;
    }
}

extern "C" PLUGIN_API void XPluginDisable(void) {
    XPLMUnregisterFlightLoopCallback(flightLoop, nullptr);
    if (gWindow != nullptr) XPLMSetWindowIsVisible(gWindow, 0);
}

extern "C" PLUGIN_API void XPluginReceiveMessage(XPLMPluginID, int, void *) {}
