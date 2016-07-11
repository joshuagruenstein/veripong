`timescale 1ns / 1ps

module vga(btns, auto, background, pclk, hsync, vsync, red, green, blue);
    input wire pclk; // CLOCK
    
    // CTRL
    input wire auto, background;
    input wire[3:0] btns;
    
    // VGA IO
    output wire hsync, vsync;
    output reg[4:0] red, blue;
    output reg[5:0] green;
    
    // VGA CONSTANTS
    parameter H_PIXELS = 800;
    parameter V_LINES = 521;
    parameter H_PULSE = 96;
    parameter V_PULSE = 2;
    parameter HBP = 144;
    parameter HFP = 784;
    parameter VBP = 31;
    parameter VFP = 511;

    // PIXEL MEMORY
    reg[319:0] pixels[0:239];
    
    // PIXEL COUNTERS
    reg[9:0] hcount;
    reg[9:0] vcount;
        
    reg[3:0] counter;
    always @(posedge pclk)  begin
        if (counter == 4) begin
            if (hcount < H_PIXELS-1) hcount <= hcount + 1;
            else begin
                hcount = 0;
                vcount = (vcount < V_LINES-1) ? vcount+1 : 0;
            end counter <= 0;
        end else counter <= counter + 1;
    end
    
    assign hsync = hcount >= H_PULSE;
    assign vsync = vcount >= V_PULSE;
    
    reg[319:0] render_temp;
    reg pixel_temp;
    always @(vcount or hcount) begin
        if (vcount >= VBP && vcount < VFP && hcount >= HBP && hcount < HFP) begin
            render_temp = pixels[(vcount-VBP)>>1];
            pixel_temp = render_temp[(hcount-HBP)>>1];
            blue = pixel_temp ? 31:0;
            red = pixel_temp ? 31:0;
            green = pixel_temp ? 63:0;
            //red <= 31; blue <= 31; green <= 63;
        end else begin
            red = 0;
            blue = 0;
            green = 0;
        end
    end
    
    reg[319:0] temp;    
    
    // PADDLE
    parameter PADDLE_WIDTH = 5;
    parameter PADDLE_HEIGHT = 30;
    parameter PADDLE_LEFT = 20;
    parameter PADDLE_RIGHT = 320-PADDLE_LEFT-PADDLE_WIDTH;
    parameter PADDLE_START = 100;
    
    
    reg[8:0] paddle1_pos = 100;
    reg[8:0] paddle2_pos = 100;
    
    // BALL
    parameter BALL_WIDTH = 3;
    parameter BALL_START_X = 158;
    parameter BALL_START_Y = 105;
    parameter VEL_START_X = 1;
    parameter VEL_START_Y = 3;
    
    reg[8:0] ball_y;
    reg[9:0] ball_x;
    reg[1:0] vel_x = 1;
    reg[1:0] vel_y = 3;
    
    // TIMING AND COUNTERS
    reg[8:0] row_counter;
    reg[9:0] column_counter;
    reg[3:0] divider;
    
    reg reset = 1;
    always @(posedge pclk) begin
        if (reset) begin
            paddle1_pos = PADDLE_START;
            paddle2_pos = PADDLE_START;
            ball_x = BALL_START_X;
            ball_y = BALL_START_Y;
            vel_x = VEL_START_X;
            vel_y = VEL_START_Y;
            reset = 0;
        end
        
        if (divider == 0) begin
            if (btns[0] && paddle1_pos+PADDLE_HEIGHT<239) paddle1_pos = paddle1_pos + 1;
            else if (btns[1] && paddle1_pos>0) paddle1_pos = paddle1_pos - 1;
            
            //if (!auto) begin
                if (btns[2] && paddle2_pos+PADDLE_HEIGHT<239) paddle2_pos = paddle2_pos + 1;
                else if (btns[3] && paddle2_pos>0) paddle2_pos = paddle2_pos - 1;
            //end else paddle2_pos = (ball_y > 223) ? 223 : ((ball_y < 17) ? 17 : ball_y - 15);
            
            
            if (vel_x >= 2) ball_x = ball_x + (vel_x-1);
            else if (vel_x < 2) ball_x = ball_x - (2-vel_x);
            if (vel_y >= 2) ball_y = ball_y + (vel_y-1);
            else if (vel_y < 2) ball_y = ball_y - (2-vel_y);
            
            divider = 1;
         end
        
        temp = pixels[row_counter];
        
        if (
            (column_counter > PADDLE_LEFT && column_counter < PADDLE_LEFT+PADDLE_WIDTH && // PADDLE 1
             row_counter > paddle1_pos && row_counter < paddle1_pos+PADDLE_HEIGHT) ||
            (column_counter > PADDLE_RIGHT && column_counter < PADDLE_RIGHT+PADDLE_WIDTH && // PADDLE 2
             row_counter > paddle2_pos && row_counter < paddle2_pos+PADDLE_HEIGHT) ||
            (column_counter > ball_x && column_counter < ball_x + BALL_WIDTH &&
             row_counter > ball_y && row_counter < ball_y + BALL_WIDTH) // BALL
           ) temp[column_counter] = !background; 
        else temp[column_counter] = background;
        
        pixels[row_counter] = temp;
        
        // PADDLE/GOAL DETECTION
        if (ball_x < PADDLE_LEFT + PADDLE_WIDTH && vel_x < 2) begin // behind bounds left
            if (ball_x > PADDLE_LEFT && ball_y > paddle1_pos && ball_y < paddle1_pos + PADDLE_HEIGHT) begin
                vel_x = 3 - vel_x;
            end else reset = 1;
        end else if (ball_x > PADDLE_RIGHT && vel_x > 1) begin
            if (ball_x < PADDLE_RIGHT + PADDLE_WIDTH && ball_y > paddle2_pos && ball_y < paddle2_pos + PADDLE_HEIGHT) begin
                vel_x = 3 - vel_x;
            end else reset = 1;
        end else if ((ball_y < 2 && vel_y < 2) || (ball_y > 237 && vel_y > 1)) begin
            vel_y = 3 - vel_y;  // WALL COLLISION DETECTION
        end
        
        if (column_counter > 318) begin
            row_counter = row_counter + 1;
            column_counter = 0;
        end else column_counter = column_counter + 1;
        
        if (row_counter > 238) begin
            row_counter = 0;
            divider = divider + 1;
        end
    end
endmodule