`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2016 01:09:21 PM
// Design Name: 
// Module Name: test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
module test(b, CLK);

  wire a;
  output b;
  reg b;
  input CLK;
  wire CLK;
  
  assign a = !b;
  
  always @(posedge CLK)
  begin
    b <= a;
  end
endmodule

module counter(clk, enable, reset, out);
    input clk, enable, reset;
    output[7:0] out;
    
    reg[7:0] out;
    
    always @(posedge clk) begin
        if (reset) begin
            out <= 8'b0;
        end
        else if (enable) begin
            out <= out + 1;
        end
    end
endmodule

module bin(clk, val, outputs);
    input clk;
    input[1:0] val;
    output[3:0] outputs;
    
    wire clk, in;
    wire[1:0] val;
    reg[3:0] outputs;
    
    always @(posedge clk) begin
        case (val)  
            0: outputs <= 8'b0000;
            1: outputs <= 8'b0001;
            2: outputs <= 8'b0010;
            3: outputs <= 8'b0100;
            4: outputs <=  8'b1000;
        endcase
    end
endmodule

module fp_mult(clk, inA, inB, out);
    input clk;
    input[15:0] inA, inB;
    output[15:0] out;
    
    wire clk;
    wire[15:0] inA, inB;
    wire[15:0] out;
    
    assign out[0:0] = inA[0:0] != inB[0:0];
    assign out[1:8] = inA[1:8]+inB[1:8];
    assign out[9:15] = inA[9:15]*inB[9:15];
endmodule
*/
/*
module blinkyLights(switches, lights);
    input[3:0] switches;
    output[3:0] lights;
    
    wire[3:0] switches;
    wire[3:0] lights;
    
    assign lights = switches;
endmodule
*/
/*
module stickyLights(buttons, lights);
    input[3:0] buttons;
    
    output[3:0] lights;
    
    wire[3:0] buttons;
    reg[3:0] lights;
    reg[3:0] was_pressed;
    
    integer i;
    always @(*) begin
        for (i=0; i<4; i=i+1) begin
            if (buttons[i]) begin
                if (!was_pressed[i]) begin
                    lights[i] <= !lights[i];
                    was_pressed[i] <= 1;
                end
            end else was_pressed[i] <= 0;
        end
    end
endmodule


module pwm(clk, duty, pwm);
    input clk;
    input[7:0] duty;
    output pwm;
    
    reg pwm_d, pwm_q;
    reg[7:0] ctr_d, ctr_q;
    
    assign pwm = pwm_q;
    
    always @(*) begin
        ctr_d <= ctr_q + 1;
        if (duty > ctr_q) pwm_d = 1;
        else pwm_d = 0;
    end
    
    always @(posedge clk) begin
        ctr_q <= ctr_d;
        pwm_q <= pwm_d;
    end
endmodule

module pwmAdjuster(CLK, buttons, lights);
    input CLK;
    input[1:0] buttons;
    output[3:0] lights;
    
    wire[1:0] buttons;
    wire[3:0] lights;
    
    reg[7:0] duty;
            
    genvar i;
    generate
        for (i=0; i<4; i=i+1) begin
            pwm newPwm(.clk(CLK),.duty(duty),.pwm(lights[i]));
        end
    endgenerate
    
    reg[18:0] counter;
    always @(posedge CLK) begin
        if (counter == 0) begin
            if (buttons[0] && !buttons[1] && duty > 0) duty = duty-1;
            else if (buttons[1] && !buttons[0] && duty < 255) duty = duty + 1;
        end
        counter <= counter + 1;
    end
endmodule
*/


// 640 by 480 vga black and white renderer, pass in 125mhz clock
module vga(btns, auto, background, pclk, hsync, vsync, red, green, blue);
    input wire auto, background, pclk;
    output wire hsync, vsync;
    output reg[4:0] red, blue;
    output reg[5:0] green;
    
    input wire[3:0] btns;
    
    reg[319:0] pixels[0:239];
    
    parameter hpixels = 800;
    parameter vlines = 521;
    parameter hpulse = 96;
    parameter vpulse = 2;
    parameter hbp = 144;
    parameter hfp = 784;
    parameter vbp = 31;
    parameter vfp = 511;

    reg[9:0] hcount;
    reg[9:0] vcount;
        
    reg[3:0] counter;
    always @(posedge pclk)  begin
        if (counter == 4) begin
            if (hcount < hpixels-1) hcount <= hcount + 1;
            else begin
                hcount = 0;
                vcount = (vcount < vlines-1) ? vcount+1 : 0;
            end counter <= 0;
        end else counter <= counter + 1;
    end
    
    assign hsync = hcount >= hpulse;
    assign vsync = vcount >= vpulse;
    
    reg[319:0] render_temp;
    reg pixel_temp;
    always @(vcount or hcount) begin
        if (vcount >= vbp && vcount < vfp && hcount >= hbp && hcount < hfp) begin
            render_temp = pixels[(vcount-vbp)>>1];
            pixel_temp = render_temp[(hcount-hbp)>>1];
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
    
    integer i=0;
    integer r=0;
    integer c=0;
    parameter paddle_width = 5;
    parameter paddle_height = 30;
    parameter paddle_left = 20;
    parameter paddle_right = 320-paddle_left-paddle_width;
    
    reg[8:0] paddle1_pos = 100;
    reg[8:0] paddle2_pos = 100;
        
    reg[8:0] row_counter;
    reg[9:0] column_counter;
    
    reg[3:0] divider;
    
    reg[8:0] ball_y = 105;
    reg[9:0] ball_x = 158;
    
    reg[1:0] vel_x = 1;
    reg[1:0] vel_y = 3; // biased by -4
    
    parameter ball_width = 3;
    
    reg reset;
    
    always @(posedge pclk) begin
        if (reset) begin
            paddle1_pos = 100;
            paddle2_pos = 100;
            ball_x = 158;
            ball_y = 105;
            vel_x = 1;
            vel_y = 3;
            reset = 0;
        end
        
        if (divider == 0) begin
            if (btns[0] && paddle1_pos+paddle_height<239) paddle1_pos = paddle1_pos + 1;
            else if (btns[1] && paddle1_pos>0) paddle1_pos = paddle1_pos - 1;
            
            //if (!auto) begin
                if (btns[2] && paddle2_pos+paddle_height<239) paddle2_pos = paddle2_pos + 1;
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
            (column_counter > paddle_left && column_counter < paddle_left+paddle_width && // PADDLE 1
             row_counter > paddle1_pos && row_counter < paddle1_pos+paddle_height) ||
            (column_counter > paddle_right && column_counter < paddle_right+paddle_width && // PADDLE 2
             row_counter > paddle2_pos && row_counter < paddle2_pos+paddle_height) ||
            (column_counter > ball_x && column_counter < ball_x + ball_width &&
             row_counter > ball_y && row_counter < ball_y + ball_width) // BALL
           ) temp[column_counter] = !background; 
        else temp[column_counter] = background;
        
        pixels[row_counter] = temp;
        
        // PADDLE/GOAL DETECTION
        if (ball_x < paddle_left + paddle_width && vel_x < 2) begin // behind bounds left
            if (ball_x > paddle_left && ball_y > paddle1_pos && ball_y < paddle1_pos + paddle_height) begin
                vel_x = 3 - vel_x;
            end else reset = 1;
        end else if (ball_x > paddle_right && vel_x > 1) begin
            if (ball_x < paddle_right + paddle_width && ball_y > paddle2_pos && ball_y < paddle2_pos + paddle_height) begin
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