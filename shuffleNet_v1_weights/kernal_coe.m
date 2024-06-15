%turn kernal to .coe file (change data form to ap_fixed(1, 5, 10))

clc;
close all;

fid = fopen('yes_signal0.coe', 'wt');
load('yes_signal0.mat');
height = size(weight, 1);
width = size(weight, 2);
fprintf(fid,'%s\n',';.COE file with hex coefficients');
fprintf(fid,';Height: %d,Width: %d\n\n',height,width*4);
fprintf(fid, 'MEMORY_INITIALIZATION_RADIX = 16;\n');
fprintf(fid, 'MEMORY_INITIALIZATION_VECTOR =\n');
desiredLength = 4;


for i=1:height
    for j=1:width
        bindata = 0;
        hexdata = 0;
        odata = weight(i, j);
        %disp('origin data: ')
        %disp(odata);
        data = fi(odata, 1, 16, 10);
        %disp('after dec: ');
        %disp(' bin: ');
        if(data < 0)
            str_value = sprintf('%0.10f', data);
            disp(str_value);
           tempdata = abs(data); % 取绝对值处理负数
           bindata = ''; % 初始化 bindata
           bindata = strcat(bindata, '1');
           for a = 1:15
               if(tempdata - 2^(5-a) >= 0)
                   tempdata = tempdata - 2^(5-a);
                   bindata = strcat(bindata, '0'); % 拼接二进制字符串
               else
                   bindata = strcat(bindata, '1');
               end
           end
           carry = 1
           for a = 16:-1:2
               if(bindata(a) == '0' && carry == 1)
                   bindata(a) = '1';
                   carry = 0;
               elseif(bindata(a) == '1' && carry == 1)
                   bindata(a) = '0';
                   carry = 1;
               end
           end
           for a = 1:4
               if(bindata((a*4 - 3):(a*4)) == "0000")
                   hexdata = strcat(hexdata, '0');
               elseif(bindata(a*4 - 3:a*4) == "0001")
                   hexdata = strcat(hexdata, '1');
               elseif(bindata(a*4 - 3:a*4) == "0010")
                   hexdata = strcat(hexdata, '2');
               elseif(bindata(a*4 - 3:a*4) == "0011")
                   hexdata = strcat(hexdata, '3');
               elseif(bindata(a*4 - 3:a*4) == "0100")
                   hexdata = strcat(hexdata, '4');
               elseif(bindata(a*4 - 3:a*4) == "0101")
                   hexdata = strcat(hexdata, '5');
               elseif(bindata(a*4 - 3:a*4) == "0110")
                   hexdata = strcat(hexdata, '6');
               elseif(bindata(a*4 - 3:a*4) == "0111")
                   hexdata = strcat(hexdata, '7');
               elseif(bindata(a*4 - 3:a*4) == "1000")
                   hexdata = strcat(hexdata, '8');
               elseif(bindata(a*4 - 3:a*4) == "1001")
                   hexdata = strcat(hexdata, '9');
               elseif(bindata(a*4 - 3:a*4) == "1010")
                   hexdata = strcat(hexdata, 'A');
               elseif(bindata(a*4 - 3:a*4) == "1011")
                   hexdata = strcat(hexdata, 'B');
               elseif(bindata(a*4 - 3:a*4) == "1100")
                   hexdata = strcat(hexdata, 'C');
               elseif(bindata(a*4 - 3:a*4) == "1101")
                   hexdata = strcat(hexdata, 'D');
               elseif(bindata(a*4 - 3:a*4) == "1110")
                   hexdata = strcat(hexdata, 'E');
               elseif(bindata(a*4 - 3:a*4) == "1111")
                   hexdata = strcat(hexdata, 'F');
               end
           end
           currentLength = numel(hexdata);
           if currentLength < desiredLength
               hexdata = [repmat('0', 1, (desiredLength - currentLength)) hexdata];
           end
           disp('negative');
           disp(i);
           disp(j);
           disp(hexdata);
           fprintf(fid, '%s', hexdata);
        elseif(data == 0)
            %disp(bindata);
            fprintf(fid, '%s', '0000');
        else
            tempdata = data;
            for a=1:15
                if(tempdata - 2^(5-a) >= 0)
                    tempdata = tempdata - 2^(5-a);
                    bindata = bindata + 2^(15 - a);
                end
            end
            hexdata = dec2hex(bindata);
            currentLength = numel(hexdata);
           if currentLength < desiredLength
               hexdata = [repmat('0', 1, (desiredLength - currentLength)) hexdata];
           end
           if(i == 1 && j == 2)
               disp('postive');
               disp(i);
               disp(j);
               disp(hexdata);
           end
           fprintf(fid, '%s', hexdata);
            
        end        


        if(i == height && j == width)
            fprintf(fid,'%c',';');
        elseif(j == width)
            fprintf(fid,'%c\n',',');   
        else
            fprintf(fid,'%c',',');
        end
    end
end
fclose(fid);

disp('finish');
% end



