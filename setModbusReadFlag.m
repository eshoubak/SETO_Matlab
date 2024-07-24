%%% Author: Bodo Baumann
%%% github: github.com/sarkspasst
%%% Organization: UNC Charlotte EPIC
%%% Date: 06/10/2024

%%% !!!TAKE CARE OF THE REGISTER NUMBERING IN THE CODE!!!
%%% !!!MATLAB STARTS COUNTING FROM 1, THEREFORE THE REGISTER NUMBERING IN THE CODE IS OFF BY 1!!!
%%% !!!MAKE SURE TO ADJUST THE REGISTER NUMBERING IN THE CODE BETWEEN PYTHON AND MATLAB!!!



function setModbusReadFlag()
    % Server IP and port
    server_ip_address = '192.168.0.224';
    server_port = 600;

    success = false;
    while ~success
        try
            % Create a modbus object
            client = modbus('tcpip', server_ip_address, server_port);
            success = true;
        catch
            disp('Failed to connect to the server. Retrying...');
            pause(1);
        end
    end

    write(client, 'holdingregs', 42069, 1, 'int16');
    disp('OpenDSS calculation started. Waiting for OpenDSS to finish the calculation...');

    writeFlag = false;
    writeFlagCounter = 0;
    start_time = tic;
    while ~writeFlag
        if read(client, 'holdingregs', 42069, 1, 'int16') == 0
            writeFlag = true;
            elapsed_time = toc(start_time);
            disp('OpenDSS finished the calculation in ' + string(elapsed_time) + ' seconds');
        else
            writeFlagCounter = writeFlagCounter + 1;
            if mod(writeFlagCounter, 10) == 0
                disp('Waiting for OpenDSS to finish the calculation...');
            end
            pause(1);
        end
    end
