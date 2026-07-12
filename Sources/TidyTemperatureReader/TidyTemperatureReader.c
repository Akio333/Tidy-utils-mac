// Native Apple-silicon thermal reader.
//
// This uses the temperature events exposed by macOS's HID event system. It
// intentionally performs read-only access and requires neither a privileged
// helper nor an external package manager.

#include "TidyTemperatureReader.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <IOKit/hidsystem/IOHIDServiceClient.h>
#include <math.h>
#include <string.h>

// These symbols are present in macOS but are not included in the public
// headers. The declarations match the system ABI used by the HID event client.
extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
extern void IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef matching);
extern CFTypeRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type, int64_t matching, int64_t options);
extern double IOHIDEventGetFloatValue(CFTypeRef event, int64_t field);

double TidyCPUTemperature(void) {
    int32_t page = 0xFF00;
    int32_t usage = 0x05;
    CFNumberRef pageValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &page);
    CFNumberRef usageValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usage);
    const void *keys[] = { CFSTR("PrimaryUsagePage"), CFSTR("PrimaryUsage") };
    const void *values[] = { pageValue, usageValue };
    CFDictionaryRef matching = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    IOHIDEventSystemClientRef client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    if (!client) {
        CFRelease(matching);
        CFRelease(pageValue);
        CFRelease(usageValue);
        return -1;
    }

    IOHIDEventSystemClientSetMatching(client, matching);
    CFArrayRef services = IOHIDEventSystemClientCopyServices(client);
    double highest = -1;

    if (services) {
        for (CFIndex index = 0; index < CFArrayGetCount(services); index++) {
            IOHIDServiceClientRef service = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, index);
            CFStringRef product = IOHIDServiceClientCopyProperty(service, CFSTR("Product"));
            char name[256] = {0};
            if (product) { CFStringGetCString(product, name, sizeof(name), kCFStringEncodingUTF8); }

            CFTypeRef event = IOHIDServiceClientCopyEvent(service, 0x0F, 0, 0);
            if (event && (strstr(name, "tdie") || strstr(name, "pACC") || strstr(name, "eACC"))) {
                double value = IOHIDEventGetFloatValue(event, 0x0F << 16);
                if (value > 0 && value < 130 && value > highest) { highest = value; }
            }
            if (event) { CFRelease(event); }
            if (product) { CFRelease(product); }
        }
        CFRelease(services);
    }

    CFRelease(client);
    CFRelease(matching);
    CFRelease(pageValue);
    CFRelease(usageValue);
    return highest;
}
