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
    reg[19:0] action_divider = 1;
    reg[9:0] hcount;
    reg[9:0] vcount;
    reg[3:0] counter;
    
    reg reset = 1;
    
    always @(posedge pclk)  begin
        if (reset) begin
            paddle1_pos = PADDLE_START;
            paddle2_pos = PADDLE_START;
            ball_x = BALL_START_X;
            ball_y = BALL_START_Y;
            vel_x = VEL_START_X;
            vel_y = VEL_START_Y;
            reset = 0;
        end
        
        if (counter == 4) begin
            if (hcount < H_PIXELS-1) hcount <= hcount + 1;
            else begin
                hcount = 0;
                vcount = (vcount < V_LINES-1) ? vcount+1 : 0;
            end counter <= 0;
        end else counter <= counter + 1;
        
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
        
        if (action_divider == 0) begin
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
            
        end
    
        action_divider <= action_divider + 1;
    end
    
    assign hsync = hcount >= H_PULSE;
    assign vsync = vcount >= V_PULSE;
    
    reg[9:0] pixel_x;
    reg[8:0] pixel_y;
    
    always @(vcount or hcount) begin
        if (vcount >= VBP && vcount < VFP && hcount >= HBP && hcount < HFP) begin
            pixel_x = (hcount - HBP) >> 1;
            pixel_y = (vcount - VBP) >> 1;
            
            if (pixel_x > PADDLE_LEFT && pixel_x < PADDLE_LEFT+PADDLE_WIDTH &&
                pixel_y > paddle1_pos && pixel_y < paddle1_pos+PADDLE_HEIGHT) begin
                red = 31;
                blue = 31;
                green = 63;
            end
            
            else if (pixel_x > PADDLE_RIGHT && pixel_x < PADDLE_RIGHT+PADDLE_WIDTH && 
                     pixel_y > paddle2_pos && pixel_y < paddle2_pos+PADDLE_HEIGHT) begin
                // PADDLE 2
                red = 31;
                blue = 31;
                green = 63;
            end
            
            else if (pixel_x > ball_x && pixel_x < ball_x + BALL_WIDTH &&
                     pixel_y > ball_y && pixel_y < ball_y + BALL_WIDTH) begin
                // BALL
                red = 31;
                blue = 31;
                green = 63;
            end
            
            else begin
               // BACKGROUND
               red = 0;
               blue = 0;
               green = 0;
            end
            
        end else begin
            red = 0;
            blue = 0;
            green = 0;
        end
    end
    
endmodule