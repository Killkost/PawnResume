#include <Windows.h>
#include <string>
#include <vector>
#include <cmath>
#include "SAMPFUNCS_API.h"

#define _SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS 1
SAMPFUNCS* SF = new SAMPFUNCS();


bool show_menu = false;
stFontInfo* myFont = nullptr;


bool bAimbot = false;
bool bWH = false;
bool bSH = false;
bool bScanner = true; 
int selected_item = 0;

struct TargetData {
    bool active;
    float pos[3];
    char text[256];
    D3DCOLOR color;
} g_Target;


float GetDistance(float* a, float* b) {
    return sqrt(pow(a[0] - b[0], 2) + pow(a[1] - b[1], 2) + pow(a[2] - b[2], 2));
}


void UpdateScanner() {
    g_Target.active = false;
    if (!bScanner || !SF->getSAMP()->IsInitialized()) return;

    float screen_cx = (float)SF->getRender()->getPresentationParameters()->BackBufferWidth / 2.0f;
    float screen_cy = (float)SF->getRender()->getPresentationParameters()->BackBufferHeight / 2.0f;
    float closest_to_crosshair = 0.08f; 


    auto pPool = SF->getSAMP()->getPlayers();
    for (int i = 0; i < SF->getGame()->getActorPoolSize(); i++) {
        actor_info* a = SF->getGame()->actorInfoGet(i, 0);
        if (!a || a == pPool->pLocalPlayer->pSAMP_Actor->pGTA_Ped) continue;

        float s[2];
        SF->getGame()->convert3DCoordsToScreen(a->base.coords[0], a->base.coords[1], a->base.coords[2], &s[0], &s[1]);
            float dist_to_center = sqrt(pow((s[0] - screen_cx) / screen_cx, 2) + pow((s[1] - screen_cy) / screen_cy, 2));

            if (dist_to_center < closest_to_crosshair) {
                closest_to_crosshair = dist_to_center;
                g_Target.active = true;
                memcpy(g_Target.pos, a->base.coords, sizeof(float) * 3);
                g_Target.color = D3DCOLOR_XRGB(255, 165, 0); 
                sprintf(g_Target.text, "OBJECT: PLAYER\nHEALTH: %.0f\nARMOR: %.0f\nDIST: %.1fm",
                    a->hitpoints, a->armor, GetDistance(pPool->pLocalPlayer->onFootData.fPosition, a->base.coords));
            }
        }
    

    if (!g_Target.active) {
        for (int i = 0; i < SF->getGame()->getVehiclePoolSize(); i++) {
            vehicle_info* v = SF->getGame()->vehicleInfoGet(i, 0);
            if (!v) continue;

            float s[2];
            SF->getGame()->convert3DCoordsToScreen(v->base.coords[0], v->base.coords[1], v->base.coords[2], &s[0], &s[1]);
                float dist_to_center = sqrt(pow((s[0] - screen_cx) / screen_cx, 2) + pow((s[1] - screen_cy) / screen_cy, 2));

                if (dist_to_center < closest_to_crosshair) {
                    closest_to_crosshair = dist_to_center;
                    g_Target.active = true;
                    memcpy(g_Target.pos, v->base.coords, sizeof(float) * 3);
                    g_Target.color = D3DCOLOR_XRGB(0, 200, 255); 
                    float speed = sqrt(v->speed[0] * v->speed[0] + v->speed[1] * v->speed[1] + v->speed[2] * v->speed[2]) * 100.0f;
                    sprintf(g_Target.text, "OBJECT: VEHICLE\nHEALTH: %.0f\nSPEED: %.1f km/h\nTYPE: %d",
                        v->hitpoints, speed, v->vehicle_type);
                }
            
        }
    }
}


bool CALLBACK Present(CONST RECT* pSrc, CONST RECT* pDest, HWND hWin, CONST RGNDATA* pReg)
{
    if (!SF->getRender()->CanDraw()) return true;

    if (SUCCEEDED(SF->getRender()->BeginRender()))
    {
        if (bScanner && SF->getSAMP()->IsInitialized())
        {
            float screen_cx = (float)SF->getRender()->getPresentationParameters()->BackBufferWidth / 2.0f;
            float screen_cy = (float)SF->getRender()->getPresentationParameters()->BackBufferHeight / 2.0f;
            auto pPool = SF->getSAMP()->getPlayers();

           
            for (int i = 0; i < SF->getGame()->getActorPoolSize(); i++) {
                actor_info* a = SF->getGame()->actorInfoGet(i, 0);
                if (!a || a == pPool->pLocalPlayer->pSAMP_Actor->pGTA_Ped) continue;

                float s[2];
                SF->getGame()->convert3DCoordsToScreen(a->base.coords[0], a->base.coords[1], a->base.coords[2], &s[0], &s[1]);
                    
                    float dist_to_center = sqrt(pow(s[0] - screen_cx, 2) + pow(s[1] - screen_cy, 2));

                    if (dist_to_center < 300.0f) {
                        D3DCOLOR col = D3DCOLOR_XRGB(255, 165, 0);

                        
                        SF->getRender()->DrawLine((int)screen_cx, (int)screen_cy, (int)s[0], (int)s[1], 1, col);

                        
                        SF->getRender()->DrawBorderedBox((int)s[0] - 5, (int)s[1] - 5, 10, 10, 0, 1, col);

                        
                        char buf[128];
                        sprintf(buf, "P: %d | HP: %.0f", i, a->hitpoints);
                        myFont->Print(buf, D3DCOLOR_XRGB(255, 255, 255), s[0] + 10, s[1] - 10);
                    }
                
            }

      
            for (int i = 0; i < SF->getGame()->getVehiclePoolSize(); i++) {
                vehicle_info* v = SF->getGame()->vehicleInfoGet(i, 0);
                if (!v) continue;

                float s[2];
               
                SF->getGame()->convert3DCoordsToScreen(v->base.coords[0], v->base.coords[1], v->base.coords[2] + 0.5f, &s[0], &s[1]);
                    float dist_to_center = sqrt(pow(s[0] - screen_cx, 2) + pow(s[1] - screen_cy, 2));

                    if (dist_to_center < 400.0f) { 
                        D3DCOLOR col = D3DCOLOR_XRGB(0, 200, 255);

                       
                        SF->getRender()->DrawLine((int)screen_cx, (int)screen_cy, (int)s[0], (int)s[1], 1, col);

                        
                        SF->getRender()->DrawBorderedBox((int)s[0] - 8, (int)s[1] - 8, 16, 16, 0, 2, col);

                        
                        char buf[128];
                        float speed = sqrt(v->speed[0] * v->speed[0] + v->speed[1] * v->speed[1]) * 150.0f;
                        sprintf(buf, "VEH ID: %d\nHP: %.0f\nSPD: %.0f km/h", i, v->hitpoints, speed);
                        myFont->Print(buf, D3DCOLOR_XRGB(255, 255, 255), s[0] + 15, s[1]);
                    }
                
            }
        }

        
        if (show_menu) {
            // Поки меню не показую, тест інших можливостей
        }
        SF->getRender()->EndRender();
    }
    return true;
}

bool CALLBACK WndProcHandler(HWND hwd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (!show_menu) return true;

    if (msg == WM_KEYDOWN) {
        if (wParam == VK_UP) { selected_item = (selected_item > 0) ? selected_item - 1 : 3; return false; }
        if (wParam == VK_DOWN) { selected_item = (selected_item < 3) ? selected_item + 1 : 0; return false; }
        if (wParam == VK_RETURN) {
            bool* values[] = { &bAimbot, &bWH, &bSH, &bScanner };
            *values[selected_item] = !*values[selected_item];
            return false;
        }
    }
    return true;
}


HRESULT CALLBACK Reset(D3DPRESENT_PARAMETERS* p) { return true; }
void CALLBACK PluginFree() {}

void __stdcall mainloop()
{
    static bool init = false;
    if (!init && SF->getSAMP()->IsInitialized())
    {
        myFont = SF->getRender()->CreateNewFont("Segoe UI", 9, FCR_BOLD | FCR_SHADOW);
        SF->getRender()->registerD3DCallback(eDirect3DDeviceMethods::D3DMETHOD_PRESENT, Present);
        SF->getRender()->registerD3DCallback(eDirect3DDeviceMethods::D3DMETHOD_RESET, Reset);
        SF->getGame()->registerWndProcCallback(SFGame::MEDIUM_CB_PRIORITY, WndProcHandler);

        SF->getSAMP()->registerChatCommand("udev", [](std::string params) {
            show_menu = !show_menu;
            SF->getSAMP()->getMisc()->ToggleCursor(show_menu);
            });

        SF->getSAMP()->getChat()->AddChatMessage(D3DCOLOR_XRGB(255, 165, 0), "Inspector Plugin Loaded. Type /udev for menu.");
        init = true;
    }
}

BOOL APIENTRY DllMain(HMODULE hMod, DWORD dwReason, LPVOID lpRes)
{
    if (dwReason == DLL_PROCESS_ATTACH) SF->initPlugin(mainloop, hMod);
    return TRUE;
}
