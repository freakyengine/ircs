#!/usr/bin/python3

## DOC -------------------------------------------------------------------------
# Generic class for remote control of electronic instrumentation equipment. It should be used to derive sub-classes for
# each instrument. TCPIP and GPIB over Ethernet are supported on Windows and Linux. This class raises errors and
# properly handles the interfaces after an error occured.
# Create a TCPIP device by GenericInstrumentConnection.GenericInstrumentConnection.tcpip()
# Create a GPIBoE device by GenericInstrumentConnection.GenericInstrumentConnection.gpiboe()
# A two element status list, first an integer status code, second a string containing the return string on success or
# an error message are returned.
#
# last modified 2019/09

import socket


class GenericInstrumentConnection:

    ## constructor
    # creates an instrument object without specifying the connection type or address
    def __init__(self,
                 connection_type: str = None,
                 device_ip_address: str = None,
                 device_gpib_address: int = None):

        if connection_type not in ['tcpip', 'gpiboe']:
            raise AttributeError('Connection type "' + str(connection_type) + '" not supported!')

        if connection_type == 'gpiboe':
            if not self.__ValidateGpibAddress(device_gpib_address):
                raise ValueError('GPIB address out of range!')

        self.connection_type = connection_type
        self.device_ip_address = device_ip_address
        self.device_port = 5025
        self.device_gpib_address = device_gpib_address
        self.message_termination_character = '\n'

    ## additional constructor (TCPIP)
    # creates an instrument object with TCPIP connection from the given address
    @classmethod
    def tcpip(cls, device_ip_address: str):
        return cls('tcpip',
                   device_ip_address,
                   None)

    ## additional constructor (GPIBoE)
    # creates an instrument object with GPIB over ethernet connection from the given addresses
    @classmethod
    def gpiboe(cls, device_gpib_address: int, gpib_gateway_ip_address: str):
        return cls('gpiboe',
                   gpib_gateway_ip_address,
                   device_gpib_address)

    ## WRITE
    # write the given message and do not read anything
    def write(self, message: str, connection_timeout: int = 1):

        if message[-1] != self.message_termination_character:
            message += self.message_termination_character

        if self.connection_type == 'gpiboe':
            status = self.__GpiboeTransfer(message, False, connection_timeout)
        else:
            status = self.__TcpipTransfer(message, False, connection_timeout)

        return self.__HandleStatus(status)

    ## QUERY
    # write the given message and returns the data read. if no data is returned, an error is raised
    def query(self, message: str, connection_timeout: int = 1):

        if message[-1] != self.message_termination_character:
            message += self.message_termination_character

        if self.connection_type == 'gpiboe':
            status = self.__GpiboeTransfer(message, True, connection_timeout)
        else:
            status = self.__TcpipTransfer(message, True, connection_timeout)

        return self.__HandleStatus(status)

    ## ---- supportive functions ----

    ## TCPIP TRANSFER
    # transmit data over socket and read response if requested
    def __TcpipTransfer(self, message: str, read_response: bool = 0, connection_timeout: int = 1):

        try:
            connection_handle = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            connection_handle.settimeout(connection_timeout)  # in seconds
            connection_handle.connect((self.device_ip_address, self.device_port))

            connection_handle.sendall(message.encode())

            recv_msg = ''

            if read_response:
                while True:
                    recv_buffer = connection_handle.recv(4096)
                    recv_msg += str(recv_buffer.decode())
                    if recv_msg[-1] == self.message_termination_character:
                        break

            connection_handle.shutdown(socket.SHUT_RDWR)
            connection_handle.close()

            return [0, recv_msg]

        except Exception as err:

            return [-1, ('[ERROR] during TCPIP transfer: ' + str(err.args[0]))]

    ## GPIBoE transfer
    # builds, transmits and, if requested, receives and decodes the message format for GPIB over ethernet
    def __GpiboeTransfer(self, message: str, read_response: bool = 0, connection_timeout: int = 1):

        gpib_cmd = 'W|' + str(self.device_gpib_address) + '|' + message
        status = self.__TcpipTransfer(gpib_cmd, True, connection_timeout)

        if status[0] != 0:
            return status

        gpiboe_status = self.__ParseGpiboeReceiveMessage(status[1])
        if gpiboe_status[0] != 0:
            return gpiboe_status

        if read_response:
            gpib_cmd = 'R|' + str(self.device_gpib_address) + self.message_termination_character
            status = self.__TcpipTransfer(gpib_cmd, True, connection_timeout)

            if status[0] != 0:
                return status

            gpiboe_status = self.__ParseGpiboeReceiveMessage(status[1])
            return gpiboe_status

        else:
            return gpiboe_status

    ## VALIDATE GPIB ADDRESS
    # checks, if GPIB address is in valid range
    def __ValidateGpibAddress(self, gpib_address: int):
        if (gpib_address >= 1) and (gpib_address <= 30):
            return 1
        else:
            return 0

    ## GPIBOE STATUS DECODE
    # splits and formats the GPIBoE return message
    def __ParseGpiboeReceiveMessage(self, message: str):
        message = message.split('|', 1)
        if len(message) > 1:
            return [int(message[0]), message[1]]
        else:
            return [int(message[0]), '']

    ## HANDLE STATUS LIST
    # handle procedure for two-element status list
    def __HandleStatus(self, status):
        if status[0] == 0:
            return status
        else:
            raise ConnectionError('ERROR: ' + str(status[0]) + ', ' + status[1])
