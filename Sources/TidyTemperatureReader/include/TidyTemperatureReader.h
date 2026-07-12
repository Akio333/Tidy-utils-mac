#ifndef TIDY_TEMPERATURE_READER_H
#define TIDY_TEMPERATURE_READER_H

// Returns the highest available CPU-die temperature in Celsius, or a negative
// value when the Mac does not expose a compatible sensor.
double TidyCPUTemperature(void);

#endif
