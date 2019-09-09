classdef GenericInstrumentConnection < handle
    % GENERIC INSTRUMENT CONNECTION CLASS
    % 
    % Base class for derivation of independent instrument classes.
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
        interface_handle = '';      % holds the interface handle
        interface_type = [];        % numeric identifier: 10=GPIB, 20=TCPIP, 30=GPIBoE
        device_tcpip_address = '';  % target device IP address
        device_gpib_address = [];   % target device GPIB address
        
        % default values used at object creation, do NOT update interface property on change, if class is already constructed.
        interface_timeout = 1;      % timeout for interface, default 1 sec
        gpib_vendor = 'ni';         % vendor for GPIB DLL, may be 'ni' 'keysight' or other (for details see MatLab "gpib" documentation)
        gpib_board_index = 0;       % local system GPIB board index
    end
    
    methods
        
        % **** CLASS CONSTRUCTOR ****
        % distinguishes between TCPIP, GPIB and GPIBoE
        % checks for gpib addresses space
        % if only GPIB or TCPIP is used, the other address field must be
        % provided, but does not care
        function obj = GenericInstrumentConnection(interface_type, device_tcpip_address, device_gpib_address)
            
            if ~( ischar(interface_type) )
                disp('[ERROR] interface_type must be provided as string');
                obj.delete();
                return;
            end
            
            interface_type = lower(interface_type);
            switch(interface_type)
                
                % ---- GPIB ----
                case 'gpib'
                    obj.interface_type = 10;
                    
                    % gpib address checker
                    if ~( isnumeric(device_gpib_address) && isscalar(device_gpib_address) && (device_gpib_address < 30) && (device_gpib_address > 0) )
                        disp('[ERROR] GPIB address must be numeric and between 1 and 29');
                        obj.delete();
                        return;
                    end
                    obj.device_gpib_address = device_gpib_address;
                    
                    obj.interface_handle = gpib(obj.gpib_vendor, obj.gpib_board_index, obj.device_gpib_address);
                    obj.interface_handle.Timeout = obj.interface_timeout;
                    
                    disp(['[INFO] created GPIB interface handle to address ' num2str(obj.device_gpib_address) ' successfully']);
                    
                % ---- TCPIP ----
                case 'tcpip'
                    obj.interface_type = 20;
                    
                    % TCPIP address string checker
                    if ~( ischar(device_tcpip_address) )
                        disp('[ERROR] TCPIP address must be provided as string');
                        obj.delete();
                        return;
                    end
                    obj.device_tcpip_address = device_tcpip_address;
                    
                    obj.interface_handle = tcpip(obj.device_tcpip_address,5025,'Terminator','LF');
                    obj.interface_handle.Timeout = obj.interface_timeout;
                    
                    disp(['[INFO] created TPCIP interface handle to address ' obj.device_tcpip_address ' successfully']);
                    
                % ---- GPIB over Ethernet ----
                % uses propritary Raspberry Pi based GPIB gateway or
                % something protocol compliant
                case 'gpiboe'
                    obj.interface_type = 30;
                    
                    % TCPIP address string checker
                    if ~( ischar(device_tcpip_address) )
                        disp('[ERROR] TCPIP address must be provided as string');
                        obj.delete();
                        return;
                    end
                    obj.device_tcpip_address = device_tcpip_address;
                    
                    % gpib address checker
                    if ~( isnumeric(device_gpib_address) && isscalar(device_gpib_address) && (device_gpib_address < 30) && (device_gpib_address > 0) )
                        disp('[ERROR] GPIB address must be numeric and between 1 and 29');
                        obj.delete();
                        return;
                    end
                    obj.device_gpib_address = device_gpib_address;
                    
                    obj.interface_handle = tcpip(obj.device_tcpip_address,5025,'Terminator','LF');
                    obj.interface_handle.Timeout = obj.interface_timeout;
                    
                    disp(['[INFO] created GPIB over Ethernet interface handle to IP:' obj.device_tcpip_address ...
                        ' / GPIB:' num2str(obj.device_gpib_address) ' successfully']);
                    
                % ---- not supported ----
                otherwise
                    disp(['[ERROR] interface type "' interface_type '" not supported']);
                    obj.delete();
                    return;
                    
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
		function status = write(obj, message)
            
            % check for text message, binary not supported
            if ~( ischar(message) )
                disp('[ERROR] message must be provided as string');
                status = -3;
                return;
            end
            
            try
                
                fopen(obj.interface_handle);
                
                if ( obj.interface_type == 30 )
                    obj = obj.gpiboe_write(message);
                else
                    fprintf(obj.interface_handle, message);
                end
                
                fclose(obj.interface_handle);
                
            catch exception
                fclose(obj.interface_handle);
                status = -4;
                disp('[ERROR] device write error');
                disp(exception.message);
                return;
            end
            
            status = 0;
        end
        
        
        % **** READ ****
        % acquires data from the device
        function [ read_data, status ] = read(obj)
            
            try
                
                fopen(obj.interface_handle);
                
                if ( obj.interface_type == 30 )
                    [obj, read_data] = obj.gpiboe_read();
                else
                    read_data = fscanf(obj.interface_handle);
                end
                
                fclose(obj.interface_handle);
                
            catch exception
                fclose(obj.interface_handle);
                status = -4;
                read_data = [];
                disp('[ERROR] device read error');
                disp(exception.message);
                return;
            end
            
            status = 0;
        end
        
        
        % **** QUERY ****
        % writes a message and reads the return data
        function [ read_data, status ] = query(obj, message)
            
            % check for text message, binary not supported
            if ~( ischar(message) )
                disp('[ERROR] message must be provided as string');
                status = -3;
                return;
            end
            
            try
                
                fopen(obj.interface_handle);
                
                if ( obj.interface_type == 30 )
                    obj = obj.gpiboe_write(message);
                    [obj, read_data] = obj.gpiboe_read();
                else
                    fprintf(obj.interface_handle, message);
                    read_data = fscanf(obj.interface_handle);
                end
                
                fclose(obj.interface_handle);
                
            catch exception
                fclose(obj.interface_handle);
                status = -4;
                disp('[ERROR] device query error');
                disp(exception.message);
                return;
            end
            
            status = 0;
        end
        
        % **** RESET ****
        % IEEE488.2 conform reset
		function status = reset(obj)
            
            message = '*RST';
            
            try
                
                fopen(obj.interface_handle);
                
                if ( obj.interface_type == 30 )
                    obj = obj.gpiboe_write(message);
                else
                    fprintf(obj.interface_handle, message);
                end
                
                fclose(obj.interface_handle);
                
            catch exception
                fclose(obj.interface_handle);
                status = -4;
                disp('[ERROR] device write error');
                disp(exception.message);
                return;
            end
            
            status = 0;
        end
        
    end
    
    methods(Access = private)
        
        % **** GPIBoE write function ****
        % private subfunction to access the GPIB over Ethernet gateway with
        % correct error decoding
        function obj = gpiboe_write(obj, message)
            
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
        function [obj, read_data] = gpiboe_read(obj)
            
            fprintf(obj.interface_handle, [ 'R|' num2str(obj.device_gpib_address) ]);
            return_data = fscanf(obj.interface_handle);
            return_data = strsplit(return_data, '|');
            if (str2double( return_data{1} ) ~= 0)
                error([ 'GPIBoE gateway returned an error: ' return_data{2} ]);
            end
            read_data = return_data{2};
            
        end
    end
end






