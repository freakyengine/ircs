classdef GenericInstrumentConnection < handle
    % GENERIC INSTRUMENT CONNECTION CLASS
    % 
    % Generic class for remote control of electronic instrumentation
    % equipment. It should be used to derive sub-classes for each
    % instrument.Base class for derivation of independent instrument
    % classes. This class raises errors and properly handles the interfaces
    % after an error occured.
    % Supports TCPIP, GPIB and GPIB over Ethernet connections.
    % - TCPIP:  provide a target device IP address as string and an empty
    %           GPIB address (does not care)
    % - GPIB:   provide a target device GPIB address as number and an empty
    %           TCPIP address (does not care)
    % - GPIBoEthernet: provide a GPIB gateway IP as string and a target
    %           device GPIB address
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
    

    % !! class derivation from handle superclass needed to achieve correct delete behavior
    
    properties      % ---- Be aware of the results of modifications!
        % object storage properties
        interface_handle = [];      % holds the interface handle
        interface_type = [];        % numeric identifier: 10=GPIB, 20=TCPIP, 30=GPIBoE
        device_tcpip_address = '';  % target device IP address
        device_gpib_address = [];   % target device GPIB address
    end
    
    properties(Access = private)
        % default values used at object creation, do NOT update interface
        % property on change, if class is already constructed
        interface_timeout = 1;      % timeout for interface, default 1 sec
        gpib_vendor = 'ni';         % vendor for GPIB DLL, may be 'ni' 'keysight' or other (for details see MatLab "gpib" documentation)
        gpib_board_index = 0;       % local system GPIB board index
    end
    
    methods
        
        % **** CLASS CONSTRUCTOR ****
        % distinguishes between TCPIP, GPIB and GPIBoE and validates
        % addresses
        % If only GPIB or TCPIP is used, the other address field must be
        % provided, but does not care (Matlab does not allow multiple
        % constructors)
        function obj = GenericInstrumentConnection(interface_type, device_tcpip_address, device_gpib_address)
            
            assert(ischar(interface_type), '[ERROR] interface_type must be provided as string');
            
            interface_type = lower(interface_type);
            switch(interface_type)
                
                % ---- GPIB ----
                case 'gpib'
                    obj.interface_type = 10;
                    
                    % validate and store interface address
                    assert(obj.ValidateGpibAddress(device_gpib_address), ...
                        '[ERROR] GPIB address must be numeric and between 1 and 29');
                    obj.device_gpib_address = device_gpib_address;
                    
                    % create interface handle and set default properties
                    obj.interface_handle = gpib(obj.gpib_vendor, obj.gpib_board_index, obj.device_gpib_address);
                    obj.interface_handle.Timeout = obj.interface_timeout;
                    
                    disp(['[INFO] created GPIB interface handle to address ' num2str(obj.device_gpib_address) ' successfully']);
                    
                % ---- TCPIP ----
                case 'tcpip'
                    obj.interface_type = 20;
                    
                    % validate and store interface address
                    assert(ischar(device_tcpip_address), ...
                        '[ERROR] TCPIP address must be provided as string');
                    
                    obj.device_tcpip_address = device_tcpip_address;
                    
                    % create interface handle and set default properties
                    obj.interface_handle = tcpip(obj.device_tcpip_address,5025,'Terminator','LF');
                    obj.interface_handle.Timeout = obj.interface_timeout;
                    
                    disp(['[INFO] created TPCIP interface handle to address ' obj.device_tcpip_address ' successfully']);
                    
                % ---- GPIB over Ethernet ----
                % uses propritary Raspberry Pi based GPIB gateway or
                % something protocol compliant
                case 'gpiboe'
                    obj.interface_type = 30;
                    
                    % validate and store interface address
                    assert(ischar(device_tcpip_address), ...
                        '[ERROR] TCPIP address must be provided as string');
                    assert(obj.ValidateGpibAddress(device_gpib_address), ...
                        '[ERROR] GPIB address must be numeric and between 1 and 29');
                    
                    obj.device_tcpip_address = device_tcpip_address;
                    obj.device_gpib_address = device_gpib_address;
                    
                    % create interface handle and set default properties
                    obj.interface_handle = tcpip(obj.device_tcpip_address,5025,'Terminator','LF');
                    obj.interface_handle.Timeout = obj.interface_timeout;
                    
                    disp(['[INFO] created GPIB over Ethernet interface handle to IP:' obj.device_tcpip_address ...
                        ' / GPIB:' num2str(obj.device_gpib_address) ' successfully']);
                    
                % ---- not supported ----
                otherwise
                    error(['[ERROR] interface type "' interface_type '" not supported']);
                    
            end
            
        end
        
        % **** CLASS DESTRUCTOR ****
        function delete(obj)
            try
                fclose(obj.interface_handle);
            catch
            end
            try
                delete(obj.interface_handle);
            catch
            end
            
            disp('[INFO] Instrument successfully closed!');
        end
        
        % **** WRITE ****
        % writes data to the device
		function obj = write(obj, message)
            
            % check for text message, binary not supported
            assert(ischar(message), ...
                '[ERROR] message must be provided as string');
            
            try
                
                fopen(obj.interface_handle);
                
                if ( obj.interface_type == 30 )
                    obj = obj.GpiboeWrite(message);
                else
                    fprintf(obj.interface_handle, message);
                end
                
                fclose(obj.interface_handle);
                
            catch exception
                try
                    fclose(obj.interface_handle);
                catch
                end
                
                error(['[ERROR] device write error: ' exception.message]);
            end
        end
        
        % **** QUERY ****
        % writes a message and reads the return data
        function [ obj, read_data ] = query(obj, message)
            
            % check for text message, binary not supported
            assert(ischar(message), ...
                '[ERROR] message must be provided as string');
            
            try
                
                fopen(obj.interface_handle);
                
                if ( obj.interface_type == 30 )
                    obj = obj.GpiboeWrite(message);
                    [obj, read_data] = obj.GpiboeRead();
                else
                    fprintf(obj.interface_handle, message);
                    read_data = fscanf(obj.interface_handle);
                end
                
                fclose(obj.interface_handle);
                
            catch exception
                try
                    fclose(obj.interface_handle);
                catch
                end
                
                error(['[ERROR] device query error: ' exception.message]);
            end
        end
        
        % **** READ ****
        % Only for GPIB interfaces, as it acquires data from the device
        % without sending a command. For command-based reads use the query
        % function!
        function [ obj, read_data ] = read(obj)
            
            assert( ((obj.interface_type == 10) || (obj.interface_type == 30)),...
                '[ERROR] read request without command is only available on GPIB');
            
            try
                
                fopen(obj.interface_handle);
                
                if ( obj.interface_type == 30 )
                    [obj, read_data] = obj.GpiboeRead();
                else
                    read_data = fscanf(obj.interface_handle);
                end
                
                fclose(obj.interface_handle);
                
            catch exception
                try
                    fclose(obj.interface_handle);
                catch
                end
                
                error(['[ERROR] device read error: ' exception.message]);
            end
        end
        
        % **** RESET ****
        % IEEE488.2 conform reset
		function reset(obj)
            obj.write('*RST');
        end
        
    end
    
    % methods providing sub-functions to the class, which should not be
    % accessed from outside or sub-classes
    methods(Access = private)
        
        % **** GPIBoE write function ****
        % private subfunction to access the GPIB over Ethernet gateway with
        % correct error decoding
        function obj = GpiboeWrite(obj, message)
            
            fprintf(obj.interface_handle, [ 'W|' num2str(obj.device_gpib_address) '|' message ]);
            return_data = fscanf(obj.interface_handle);
            return_data = strsplit(return_data, '|');
            if (str2double( return_data{1} ) ~= 0)
                error([ 'GPIBoE gateway returned an error: ' return_data{2} ]);
            end
            
        end
        
        % **** GPIBoE read function ****
        % private subfunction to access the GPIB over Ethernet gateway with
        % correct error decoding
        function [obj, read_data] = GpiboeRead(obj)
            
            fprintf(obj.interface_handle, [ 'R|' num2str(obj.device_gpib_address) ]);
            return_data = fscanf(obj.interface_handle);
            return_data = strsplit(return_data, '|');
            if (str2double( return_data{1} ) ~= 0)
                error([ 'GPIBoE gateway returned an error: ' return_data{2} ]);
            end
            read_data = return_data{2};
            
        end
        
        % **** GPIB address validation function ****
        % returns true if GPIB address is valid
        function result = ValidateGpibAddress(~, address)
            result = ...
                isnumeric(address) && ...
                isscalar(address) && ...
                (address < 30) && ...
                (address > 0);
        end
        
    end
    
    % static helper methods, which provide additional useful functionality
    % to sub-classes
    methods(Access=protected, Static=true)
        
        % **** VALIDATE NUMERIC INPUT ****
        % Validates numeric input to be numeric, scalar and in specified
        % range. Returns true on valid number.
        function result = ValidateNumeric(value, lower_limit, upper_limit)
            result = isnumeric(value) && ...
                isscalar(value) && ...
                (value <= upper_limit) && ...
                (value >= lower_limit);
        end
        
        % **** VALIDATE LOGICAL INPUT ****
        % Validates numeric or logical input to be numeric or logical for
        % usage in expressions. Returns true on valid logical or scalar
        % number.
        function result = ValidateLogicalOrNumeric(value)
            result = ...
                (isnumeric(value) && isscalar(value)) ...
                || islogical(value);
        end
    end
end






