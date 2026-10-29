#include "Kagura/Kagura.h"
#include "Kagura/Core/ReservationTable.h"

namespace Kagura
{
    void Init()
    {
        Core::ReservationTable::GetSingleton().ResetForLoad();
        logger::info("Kagura core initialized (P1 S0/S1 skeleton)");
    }

    void Shutdown()
    {
        Core::ReservationTable::GetSingleton().ResetForLoad();
    }
}
