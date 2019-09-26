classdef Agilent6632B < GenericInstrumentConnection
    % Agilent(HP) 6632B power supply remote control
    %
    % This script may be used for other Agilent 663x units, but this is not
    % intentionally covered. At least the output value limits must be
    % adjusted.
    %
    % This script is not covering the complete device functionality.
    %
    %
    % last update: 2019/09
    
    properties
    end
    
    methods
        
        % **** CLASS CONSTRUCTOR ****
        % do not modify!
        function obj = Agilent6632B(interface_type, device_tcpip_address, device_gpib_address)
            obj@GenericInstrumentConnection(interface_type, device_tcpip_address, device_gpib_address);
        end
        
        % **** SET VOLTAGE ****
        function set_voltage(obj,value)
            
            assert(obj.ValidateNumeric(value,0,20), ...
                '[ERROR] voltage value out of range');
            
            obj.write([ 'VOLT ' num2str(value) 'V' ]);
        end
        
        % **** SET CURRENT ****
        function set_current(obj,value)
            
            assert(obj.ValidateNumeric(value,0,5), ...
                '[ERROR] current value out of range');
            
            obj.write([ 'CURR ' num2str(value) 'A' ]);
        end
        
        % **** SET OUTPUT STATE ****
        function set_output_state(obj,value)
            
            assert( obj.ValidateLogicalOrNumeric(value), ...
                '[ERROR] output state must be numeric or logial');
            
            if value == 0
                obj.write('OUTP 0');
            else
                obj.write('OUTP 1');
            end
        end
        
        % **** MEASURE ACTUAL OUTPUT VOLTAGE ****
        function result = measure_voltage(obj)
            [~, read_data] = obj.query( 'MEAS:VOLT?' );
            result = str2double(read_data);
        end
        
        % **** MEASURE ACTUAL OUTPUT CURRENT ****
        function result = measure_current(obj)
            [~, read_data] = obj.query( 'MEAS:CURR?' );
            result = str2double(read_data);
        end
        
    end
    
end

