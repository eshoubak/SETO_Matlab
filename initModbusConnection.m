%%% Author: Bodo Baumann
%%% github: github.com/sarkspasst
%%% Organization: UNC Charlotte EPIC
%%% Date: 06/10/2024

%%% !!!TAKE CARE OF THE REGISTER NUMBERING IN THE CODE!!!
%%% !!!MATLAB STARTS COUNTING FROM 1, THEREFORE THE REGISTER NUMBERING IN THE CODE IS OFF BY 1!!!
%%% !!!MAKE SURE TO ADJUST THE REGISTER NUMBERING IN THE CODE BETWEEN PYTHON AND MATLAB!!!



function portNumbers = initModbusConnection(derCount)
    % Import the required libraries
    import matlab.net.*
    import matlab.net.http.*

    % Define the server IP address and port
    server_ip_address = '192.168.0.224';
    server_port = 600;

    % Initialize the error count
    errorCount = 0;

    success = false;

    % Loop indefinitely
    while ~success

        try
            % Get the number of DERs
            disp('*******************************************************');
            disp(['Sending # of DERs [count = ', num2str(derCount), '] to initialize Modbus servers']);

            % Create a Modbus TCP client
            client = modbus('tcpip', server_ip_address, server_port);
            disp('*******************************************************');
            disp(['[+]Info : Connection successful with ', num2str(server_port)]);

            % Write the DER count to register 40001
            write(client, 'holdingregs', 40002, derCount, 'int16');
            disp(['[+]Info : # of DER successfully sent to server [PORT: ', num2str(server_port), ']']);



            % Read the net load value (opendss + rtds) from register 40002
            client.WordOrder = 'little-endian';
            read_value = read(client, 'holdingregs', 40003, 1, 'single');
            netLoad = sprintf('%.2f', read_value);
            disp(['[+]Info : Netload (DSS+RTDS) received from simulation: ', num2str(netLoad), ' (kw)']);

            % Read the DER port numbers from PORT 600
            %portNumber = zeros(derCount, 1);
            portNumber = [];
            for portCount = 1:derCount
                value = read(client, 'holdingregs', 40004 + portCount, 1);
                %portNumber(portCount) = value;
                portNumber = [portNumber, value];
            end

            portNumbers = portNumber;

            % Write the port numbers to a txt file
            %writematrix(portNumber, 'serverPorts.txt');
            %disp(['Used Ports: ', num2str(portNumber)]);
            %disp('-------------------------------------------------------');

            % Close the connection
            %fclose(client);

            success = true;
        catch % Maybe add a specific exception here to start the modbus server on other machine
            errorCount = errorCount + 1;
            disp(['ERROR in writing data to PORT: ', num2str(server_port), '. Error count# ', num2str(errorCount), '. Trying again...']);
    
            if errorCount >= 5
                disp(['PORT: ', num2str(server_port), ' write operation FAILED in try# ', num2str(errorCount), '!!! skipping to next loop...']);
            end
    
            % Wait for 5 seconds
            pause(5);
        end
    end
