module tail_lights(clk, rst, sw, led_8bit, led_L_R_N5, led_R_R_T5, digit_seg, digit_cath);
input clk;
input rst;
input [2:0] sw;
output reg [7:0] led_8bit;
output led_L_R_N5;
output led_R_R_T5;
output [7:0] digit_seg;
output [1:0] digit_cath;


wire [1:0] cnt;
wire clk_2;
wire [7:0] code_for_led8bit_state1;
wire [7:0] code_for_led8bit_state2;
wire [7:0] code_for_led8bit_state3;
wire [7:0] code_for_led8bit_state4;
wire [7:0] code_for_led8bit_state5; 
wire [7:0] code_for_seg_wire;
wire led_L_R_N5_temp;
wire led_R_R_T5_temp;

reg [7:0] code_for_seg;
reg flag_for_led_L;
reg flag_for_led_R;

assign code_for_seg_wire = code_for_seg;
assign led_L_R_N5 = flag_for_led_L | led_L_R_N5_temp;
assign led_R_R_T5 = flag_for_led_R | led_R_R_T5_temp;
always @(posedge clk or posedge rst) begin
	case(sw)
	1:begin
		led_8bit<=code_for_led8bit_state1;
		code_for_seg<=8'b0000_0001;
		flag_for_led_L<=1;
		flag_for_led_R<=1;
	end
	2:begin
		led_8bit<=code_for_led8bit_state2;
		code_for_seg<=8'b0010_0011;
		flag_for_led_L<=1;
		flag_for_led_R<=0;
	end
	3:begin
		led_8bit<=code_for_led8bit_state3;
		code_for_seg<=8'b0100_0010;
		flag_for_led_L<=0;
		flag_for_led_R<=1;
	end
	4:begin
		led_8bit<=code_for_led8bit_state4;
		code_for_seg<=8'b0101_0101;
		flag_for_led_L<=0;
		flag_for_led_R<=0;
	end
	5:begin
		led_8bit<=code_for_led8bit_state5;
		code_for_seg<=8'b0110_0111;
		flag_for_led_L<=0;
		flag_for_led_R<=0;
	end
	default:begin
		led_8bit<=0;
		code_for_seg<=8'b1000_1001;
		flag_for_led_L<=1;
		flag_for_led_R<=1;
	end
	endcase
end
frequency_divider #(.N(12499999)) u_clk_2(
    .clkin(clk),
    .clkout(clk_2)
    );
cnt_out u_cnt(
	.clk_2(clk_2),
	.cnt(cnt)
	);
led_8bit_state1 u_led8bit_state1(
	.clk(clk), 
	.cnt(cnt), 
	.code_for_led8bit_state1(code_for_led8bit_state1)
	);
led_8bit_state2 u_led8bit_state2(
	.clk(clk), 
	.cnt(cnt), 
	.code_for_led8bit_state2(code_for_led8bit_state2)
	);
led_8bit_state3 u_led8bit_state3(
	.clk(clk), 
	.cnt(cnt), 
	.code_for_led8bit_state3(code_for_led8bit_state3)
	);
led_8bit_state4 u_led8bit_state4(
	.clk(clk), 
	.cnt(cnt), 
	.code_for_led8bit_state4(code_for_led8bit_state4)
	);
led_8bit_state5 u_led8bit_state5(
	.clk(clk), 
	.cnt(cnt), 
	.code_for_led8bit_state5(code_for_led8bit_state5)
	);
seg_scan u_seg(
	.clk_50M(clk),
	.rst_button(rst), 
	.switch(code_for_seg_wire), 
	.digit_seg(digit_seg), 
	.digit_cath(digit_cath)
	);
led_R u_led_R(
	.clk(clk), 
	.cnt(cnt), 
	.led_R_R_T5_temp(led_R_R_T5_temp), 
	.led_L_R_N5_temp(led_L_R_N5_temp)
	);
endmodule

module seg_scan(clk_50M,rst_button, switch, digit_seg, digit_cath);
input clk_50M; //板载50M晶振
input rst_button;
input [7:0] switch;
output reg [7:0] digit_seg; //七段数码管的段选端
output [1:0] digit_cath; //2个数码管的片选端
wire reset; //复位按键
assign reset = rst_button;

//计数分频，通过读取32位计数器div_count不同位数的上升沿或下降沿来获得频率不同的时钟
reg [31:0] div_count;
always @(posedge clk_50M,posedge reset)
begin
    if(reset)
        div_count <= 0;   //如果按下复位按键，计数清零
    else
        div_count <= div_count + 1;
end

//拨码开关控制数码管显示，每4位拨码开关控制一个七段数码管
wire [7:0] digit_display;
assign digit_display = switch;

wire [3:0] digit;
always @(*)      //对所有信号敏感
begin
    case (digit)
        4'h0:  digit_seg <= 8'b10001100; //显示0~F
        4'h1:  digit_seg <= 8'b11100000;   
        4'h2:  digit_seg <= 8'b00000010;
        4'h3:  digit_seg <= 8'b11110010;
        4'h4:  digit_seg <= 8'b10011110;
        4'h5:  digit_seg <= 8'b11111110;
        4'h6:  digit_seg <= 8'b00011100;
        4'h7:  digit_seg <= 8'b01110000;
        4'h8:  digit_seg <= 8'b10011100;
        4'h9:  digit_seg <= 8'b11110000;
        4'hA:  digit_seg <= 8'b11101110;
        4'hB:  digit_seg <= 8'b00111110;
        4'hC:  digit_seg <= 8'b10011100;
        4'hD:  digit_seg <= 8'b01111010;
        4'hE:  digit_seg <= 8'b10011110;
        4'hF:  digit_seg <= 8'b10001110;
    endcase
end

//通过读取32位计数器的第10位的上升沿得到分频时钟，用于数码管的扫描
reg segcath_holdtime;
always @(posedge div_count[10], posedge reset)
begin
if(reset)
     segcath_holdtime <= 0;
else
     segcath_holdtime <= ~segcath_holdtime;
end

//7段数码管位选控制
assign digit_cath ={segcath_holdtime, ~segcath_holdtime};
// 相应位数码管段选信号控制
assign digit =segcath_holdtime ? digit_display[7:4] : digit_display[3:0];

endmodule

module led_8bit_state1(clk, cnt, code_for_led8bit_state1);
input clk;
input [1:0] cnt;
output reg [7:0] code_for_led8bit_state1;
always @(posedge clk) begin
	case(cnt)
	0:begin
		code_for_led8bit_state1<=8'b11100111;
	end
	1:begin
		code_for_led8bit_state1<=8'b11011011;
	end
	2:begin
		code_for_led8bit_state1<=8'b10111101;
	end
	3:begin
		code_for_led8bit_state1<=8'b01111110;
	end
	default:begin
		code_for_led8bit_state1<=0;
	end
	endcase
end

endmodule

module led_8bit_state2(clk, cnt, code_for_led8bit_state2);
input clk;
input [1:0] cnt;
output reg [7:0] code_for_led8bit_state2;
always @(posedge clk) begin
	case(cnt)
	0:begin
		code_for_led8bit_state2<=8'b01110111;
	end
	1:begin
		code_for_led8bit_state2<=8'b10111011;
	end
	2:begin
		code_for_led8bit_state2<=8'b11011101;
	end
	3:begin
		code_for_led8bit_state2<=8'b11101110;
	end
	default:begin
		code_for_led8bit_state2<=0;
	end
	endcase
end

endmodule

module led_8bit_state3(clk, cnt, code_for_led8bit_state3);
input clk;
input [1:0] cnt;
output reg [7:0] code_for_led8bit_state3;
always @(posedge clk) begin
	case(cnt)
	0:begin
		code_for_led8bit_state3<=8'b11101110;
	end
	1:begin
		code_for_led8bit_state3<=8'b11011101;
	end
	2:begin
		code_for_led8bit_state3<=8'b10111011;
	end
	3:begin
		code_for_led8bit_state3<=8'b01110111;
	end
	default:begin
		code_for_led8bit_state3<=0;
	end
	endcase
end

endmodule

module led_8bit_state4(clk, cnt, code_for_led8bit_state4);
input clk;
input [1:0] cnt;
output reg [7:0] code_for_led8bit_state4;
always @(posedge clk) begin
	case(cnt)
	0:begin
		code_for_led8bit_state4<=8'b01111110;
	end
	1:begin
		code_for_led8bit_state4<=8'b10111101;
	end
	2:begin
		code_for_led8bit_state4<=8'b11011011;
	end
	3:begin
		code_for_led8bit_state4<=8'b11100111;
	end
	default:begin
		code_for_led8bit_state4<=0;
	end
	endcase
end

endmodule

module led_8bit_state5(clk, cnt, code_for_led8bit_state5);
input clk;
input [1:0] cnt;
output reg [7:0] code_for_led8bit_state5;
always @(posedge clk) begin
	case(cnt)
	0:begin
		code_for_led8bit_state5<=8'b0000_0000;
	end
	1:begin
		code_for_led8bit_state5<=8'b1111_1111;
	end
	2:begin
		code_for_led8bit_state5<=8'b1111_1111;
	end
	3:begin
		code_for_led8bit_state5<=8'b0000_0000;
	end
	default:begin
		code_for_led8bit_state5<=0;
	end
	endcase
end

endmodule

module led_R(clk, cnt, led_R_R_T5_temp, led_L_R_N5_temp);
input clk;
input [1:0] cnt;
output reg led_L_R_N5_temp, led_R_R_T5_temp;
always @(posedge clk) begin
	case(cnt)
	0:begin
		led_R_R_T5_temp<=0;led_L_R_N5_temp<=0;
	end
	1:begin
		led_R_R_T5_temp<=0;led_L_R_N5_temp<=0;
	end
	2:begin
		led_R_R_T5_temp<=1;led_L_R_N5_temp<=1;
	end
	3:begin
		led_R_R_T5_temp<=1;led_L_R_N5_temp<=1;
	end
	default:begin
		led_R_R_T5_temp<=1;led_L_R_N5_temp<=1;
	end
	endcase
end

endmodule

module cnt_out(clk_2, cnt);
input clk_2;
output reg [1:0] cnt;
initial begin
	cnt=0;
end
always @(posedge clk_2) begin
	cnt<=cnt+1;
end

endmodule

module frequency_divider(clkin, clkout);
parameter N = 1;
input clkin;
output reg clkout;
reg [27:0] cnt;
initial 
begin
cnt<=0;
clkout<=0;
end
always @(posedge clkin) begin
    if (cnt==N) begin
        clkout <= !clkout;
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end
endmodule
