//
// Network Analyzer by KillKost
//

#include <Windows.h>
#include <string>
#include <map>

#include "SAMPFUNCS_API.h"
#include "SFRakNet.h"
#include "SFSAMP.h"

SAMPFUNCS* SF = new SAMPFUNCS();


struct PacketData {
	uint32_t count;
	uint32_t bytes;
};


std::map<int, PacketData> netStats;


bool __stdcall onIncomingPacket(stRakNetHookParams* params) {
	if (params == nullptr || params->bitStream == nullptr) return true;

	int pID = params->packetId;
	uint32_t pSize = params->bitStream->GetNumberOfBytesUsed();

	netStats[pID].count++;
	netStats[pID].bytes += pSize;

	return true;
}

// ÔÓÍÊÖÈß ÊÎÌÀÍÄÛ ÄÎËÆÍÀ ÁÛÒÜ __stdcall (ðåøàåò îøèáêó E0167)
void __stdcall cmdNetStat(std::string params) {
	SF->getSAMP()->getChat()->AddChatMessage(D3DCOLOR_XRGB(255, 255, 0), "--- Network Stats ---");

	for (auto const& item : netStats) {
		char buf[128];
		// item.first - ID, item.second - äàííûå
		sprintf(buf, "ID: %d | Packets: %u | Total: %u bytes", item.first, item.second.count, item.second.bytes);
		SF->getSAMP()->getChat()->AddChatMessage(D3DCOLOR_XRGB(255, 255, 255), buf);
	}
}

void __stdcall mainloop() {
	static bool initialized = false;
	if (!initialized && SF->getSAMP()->IsInitialized()) {

		// Ðåãèñòðàöèÿ êîëáýêà íà ïàêåòû
		SF->getRakNet()->registerRakNetCallback(RAKHOOK_TYPE_INCOMING_PACKET, onIncomingPacket);

		// Ïðàâèëüíàÿ ðåãèñòðàöèÿ êîìàíäû (óêàçûâàåì ôóíêöèþ íàïðÿìóþ)
		SF->getSAMP()->registerChatCommand("netstat", cmdNetStat);

		SF->getSAMP()->getChat()->AddChatMessage(D3DCOLOR_XRGB(0, 255, 0), "Network Analyzer Started!");
		initialized = true;
	}
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD dwReason, LPVOID lpReserved) {
	if (dwReason == DLL_PROCESS_ATTACH) {
		SF->initPlugin(mainloop, hModule);
	}
	return TRUE;

}
