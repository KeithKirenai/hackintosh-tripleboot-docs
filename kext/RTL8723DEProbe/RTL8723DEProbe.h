#ifndef RTL8723DEProbe_h
#define RTL8723DEProbe_h

#include <IOKit/IOService.h>

class RTL8723DEProbe : public IOService
{
    OSDeclareDefaultStructors(RTL8723DEProbe)

public:
    virtual bool start(IOService *provider) override;
    virtual void stop(IOService *provider) override;
    virtual IOService *probe(IOService *provider, SInt32 *score) override;
};

#endif
