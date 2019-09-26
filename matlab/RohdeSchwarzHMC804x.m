classdef RohdeSchwarzHMC804x < GenericInstrumentConnection
    % Rohde&Scharz HMC804x power supply remote control
    %
    % This script works for all three models (HMC8041, HMC8042 and
    % HMC8043) for both TCPIP and GPIB connection. However, the output
    % channels 2 and 3 are only programmable if they are available on the
    % respective unit. The same is for the maximal output power, as it
    % varies through the models.
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
        function obj = RohdeSchwarzHMC804x(interface_type, device_tcpip_address, device_gpib_address)
            obj@GenericInstrumentConnection(interface_type, device_tcpip_address, device_gpib_address);
        end
        
        % **** SET VOLTAGE ****
        function set_voltage(obj, channel, value)
            
            assert(obj.ValidateNumeric(value,0,32), ...
                '[ERROR] voltage value out of range');
            
            assert(obj.ValidateNumeric(channel,1,3), ...
                '[ERROR] channel number out of range');
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            obj.write([ 'VOLT ' num2str(value) 'V' ]);
        end
        
        % **** SET CURRENT ****
        function set_current(obj, channel, value)
            
            assert(obj.ValidateNumeric(value,0,10), ...
                '[ERROR] current value out of range');
            
            assert(obj.ValidateNumeric(channel,1,3), ...
                '[ERROR] channel number out of range');
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            obj.write([ 'CURR ' num2str(value) 'A' ]);
        end
        
        % **** SET OUTPUT STATE ****
        function set_output_state(obj, channel, value)
            
            assert( obj.ValidateLogicalOrNumeric(value), ...
                '[ERROR] output state must be logial');
            
            assert(obj.ValidateNumeric(channel,1,3), ...
                '[ERROR] channel number out of range');
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            
            if value == 0
                obj.write('OUTP 0');
            else
                obj.write('OUTP 1');
            end
        end
        
        % **** MEASURE ACTUAL OUTPUT VOLTAGE ****
        function result = measure_voltage(obj, channel)
            
            assert(obj.ValidateNumeric(channel,1,3), ...
                '[ERROR] channel number out of range');
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            
            [ ~, read_data ] = obj.query( 'MEAS:VOLT?' );
            result = str2double(read_data);
        end
        
        % **** MEASURE ACTUAL OUTPUT CURRENT ****
        function result = measure_current(obj, channel)
            
            assert(obj.ValidateNumeric(channel,1,3), ...
                '[ERROR] channel number out of range');
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            
            [ ~, read_data ] = obj.query( 'MEAS:CURR?' );
            result = str2double(read_data);
        end
        
    end
    
end

