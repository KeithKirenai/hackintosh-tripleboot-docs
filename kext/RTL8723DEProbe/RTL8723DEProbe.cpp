#include "RTL8723DEProbe.h"
#include <IOKit/IOLib.h>

#define super IOService
OSDefineMetaClassAndStructors(RTL8723DEProbe, IOService)

IOService *RTL8723DEProbe::probe(IOService *provider, SInt32 *score)
{
    IOLog("RTL8723DEProbe::probe — provider: %s, class: %s\n",
          provider->getName(), provider->getMetaClass()->getClassName());
    *score += 1000;
    return this;
}

bool RTL8723DEProbe::start(IOService *provider)
{
    if (!super::start(provider))
        return false;

    IOLog("RTL8723DEProbe::start — RTL8723DE reclamado\n");
    provider->setProperty("rtl8723de-probed", true);
    registerService();
    return true;
}

void RTL8723DEProbe::stop(IOService *provider)
{
    IOLog("RTL8723DEProbe::stop\n");
    super::stop(provider);
}
