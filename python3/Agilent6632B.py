#!/usr/bin/python3

## DOC -------------------------------------------------------------------------
# Agilent(HP) 6632B power supply remote control
#
# This script may be used for other Agilent 663x units, but this is not
# intentionally covered. At least the output value limits must be
# adjusted.
# This script is not covering the complete device functionality.
#
# last modified 2019/09

from GenericInstrumentConnection import GenericInstrumentConnection


class Agilent6632B(GenericInstrumentConnection):

    def set_voltage(self, value: float):
        self.write('VOLT ' + str(value) + 'V')

    def set_current(self, value: float):
        self.write('CURR ' + str(value) + 'A')

    def set_output_state(self, value: bool):
        if value == 0:
            self.write('OUTP 0')
        else:
            self.write('OUTP 1')

    def measure_voltage(self):
        read_data = self.query('MEAS:VOLT?')
        return float(read_data[1])

    def measure_current(self):
        read_data = self.query('MEAS:CURR?')
        return float(read_data[1])
