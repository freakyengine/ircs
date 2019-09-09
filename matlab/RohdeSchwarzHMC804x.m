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
    % status codes:
    %  0    success
    % -1    generic
    % -2    address issue
    % -3    message issue
    % -4    communication issue
    % -6    value error, e.g. over/underflow
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
        function status = set_voltage(obj, channel, value)
            
            if ~( isnumeric(value) && isscalar(value) )
                status = -6;
                return;
            end
            if ~( isnumeric(channel) && isscalar(channel) && (channel <= 3) && (channel >= 1) )
                status = -6;
                return;
            end
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            obj.write([ 'VOLT ' num2str(value) 'V' ]);
            
            status = 0;
        end
        
        % **** SET CURRENT ****
        function status = set_current(obj, channel, value)
            
            if ~( isnumeric(value) && isscalar(value) )
                status = -6;
                return;
            end
            if ~( isnumeric(channel) && isscalar(channel) && (channel <= 3) && (channel >= 1) )
                status = -6;
                return;
            end
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            obj.write([ 'CURR ' num2str(value) 'A' ]);
            
            status = 0;
        end
        
        % **** SET OUTPUT STATE ****
        function status = set_output_state(obj, channel, value)
            
            if ~( isnumeric(value) || islogical(value) )
                status = -6;
                return;
            end
            if ~( isnumeric(channel) && isscalar(channel) && (channel <= 3) && (channel >= 1) )
                status = -6;
                return;
            end
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            
            if value == 0
                obj.write('OUTP 0');
            else
                obj.write('OUTP 1');
            end
            
            status = 0;
        end
        
        % **** MEASURE ACTUAL OUTPUT VOLTAGE ****
        function [ result, status ] = measure_voltage(obj, channel)
            
            if ~( isnumeric(channel) && isscalar(channel) && (channel <= 3) && (channel >= 1) )
                status = -6;
                return;
            end
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            [ result, ~ ] = obj.query( 'MEAS:VOLT?' );
            
            result = str2double(result);
            status = 0;
        end
        
        % **** MEASURE ACTUAL OUTPUT CURRENT ****
        function [ result, status ] = measure_current(obj, channel)
            
            if ~( isnumeric(channel) && isscalar(channel) && (channel <= 3) && (channel >= 1) )
                status = -6;
                return;
            end
            
            obj.write([ 'INST:NSEL ' num2str(channel) ]);
            [ result, ~ ] = obj.query( 'MEAS:CURR?' );
            
            result = str2double(result);
            status = 0;
        end
        
    end
    
end

