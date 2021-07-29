module MIPS(
	input clk,
	input rst_n,
	input cpu_en,
	input [7:0] data_read,
	input ram_send,
	input ram_receive,
	output reg cpu_send,
	output reg cpu_receive,
	output reg cpu_ready,
	output reg [15:0] data_addr,
	output reg [7:0] data_store,
	output reg [1:0] mem_ctrl,//1:1 for read,0:0 for write
	output reg done
	);
	
	reg [15:0] R [7:0];//register group
	reg [15:0] PC,IR;
	reg [3:0] OP;
	reg [2:0] funct;//[2:0]for real funct
						 
	reg [2:0] state,next_state;
	parameter IDLE = 3'b000,
				 IF = 3'b001,
				 ID = 3'b010,
				 EX = 3'b011,
				 MEM = 3'b100,
				 WB = 3'b101;
	
	always@(posedge clk)
	begin
		if(~(rst_n&cpu_en))
		begin
			state <= IDLE;
		end
		else
		begin
			case(next_state)
				IDLE:state <= IDLE;
				IF:state <= IF;
				ID:state <= ID;
				EX:state <= EX;
				MEM:state <= MEM;
				WB:state <= WB;
				default:state <= state;
			endcase
		end
	end
	
	reg [15:0] rs,rt;
	reg [5:0] im;
	reg [11:0] addr;
	reg [15:0] temp;
	reg [1:0] read_cnt;
	reg [1:0] write_cnt;
	
	reg delay_cnt;
	reg delay_en;
	always@(posedge clk)//pulse generator
	begin
		if(~(rst_n&cpu_en))
		begin
			cpu_ready <= 1'b0;
			delay_cnt <= 1'b0;
		end
		else if(delay_en)
		begin
			if(delay_cnt)
				cpu_ready <= 1'b0;//cpu_ready control part
			else
			begin
				cpu_ready <= 1'b1;
				delay_cnt <= 1'b1;
			end
		end
		else
		begin
			cpu_ready <= 1'b0;
			delay_cnt <= 1'b0;
		end
	end
	
	
	//reg hold_MEM;
	wire [15:0]PC_1;
	assign PC_1 = PC + 16'd2;

	always@(posedge clk)
	begin
		if(~(rst_n&cpu_en))
		begin
			{R[0],R[1],R[2],R[3],R[4],R[5],R[6],R[7]} <= 128'd0;
			{PC,IR} <= 32'd0;
			{rs,rt} <= 32'd0;
			im <= 6'd0;
			addr <= 12'd0;
			temp <= 16'd0;
			{cpu_receive,cpu_send} <= 2'b00;
			next_state <= IDLE;
			data_addr <= 16'd0;
			data_store <= 8'd0;
			OP <= 4'd0;
			IR <= 16'd0;
			funct <= 3'd0;
			//hold_MEM <= 1'b0;
			done <= 1'b0;
			mem_ctrl <= 2'd0;//disable
			read_cnt <= 2'd0;
			write_cnt <= 2'd0;
		end
		else
		begin
			case(state)
				IDLE:
				begin
					done <= 1'b0;
					next_state <= IF;
					read_cnt <= 2'd0;
					write_cnt <= 2'd0;
					{cpu_receive,cpu_send} <= 2'b00;
					mem_ctrl <= 2'b00;//invalid
				end
				IF:
				begin
					mem_ctrl <= 2'b10;//read
					{cpu_receive,cpu_send} <= 2'b00;//must be reseted before ram corresponding execution
					
					if(read_cnt == 2'd0)
					begin
						data_addr <= PC;
						delay_en <= 1'b1;
						
						//signal receive control part
						if(cpu_receive && ram_send)//priority
						begin
							cpu_receive <= 1'b0;
							delay_en <= 1'b0;
							read_cnt <= 2'd1;
						end
						else if(ram_send)//cpu read control part
						begin
							IR[15:8] <= data_read;
							if(IR[15:8] == data_read)
								cpu_receive <= 1'b1;
							else
								cpu_receive <= 1'b0;
						end
						else
						begin
							IR[15:8] <= IR[15:8];
							read_cnt <= 2'd0;
						end
					end
					
					else if(read_cnt == 2'd1)
					begin
						data_addr <= PC + 16'd1;
						
						delay_en <= 1'b1;
						
						//signal receive control part
						if(cpu_receive && ram_send)//priority
						begin
							cpu_receive <= 1'b0;
							delay_en <= 1'b0;
							read_cnt <= 2'd2;
						end
						else if(ram_send)//cpu read control part
						begin
							IR[7:0] <= data_read;
							if(IR[7:0] == data_read)
								cpu_receive <= 1'b1;
							else
								cpu_receive <= 1'b0;
						end
						else
						begin
							IR[7:0] <= IR[7:0];
							read_cnt <= 2'd1;
						end
					end

					else if(read_cnt == 2'd2)
					begin
						next_state <= ID;
						PC <= PC + 16'd2;
						read_cnt <= 2'd0;
						mem_ctrl <= 2'b00;//disable
						{cpu_receive,cpu_send} <= 2'b00;
					end
					
					else
					begin
						next_state <= IF;
						PC <= PC;
					end
					
				end
				ID:
				begin
					OP <= IR[15:12];
					case(IR[11:9])
						3'd0:rs <= R[0];
						3'd1:rs <= R[1];
						3'd2:rs <= R[2];
						3'd3:rs <= R[3];
						3'd4:rs <= R[4];
						3'd5:rs <= R[5];
						3'd6:rs <= R[6];
						3'd7:rs <= R[7];
						default:rs <= 16'd0;
					endcase
					case(IR[8:6])
						3'd0:rt <= R[0];
						3'd1:rt <= R[1];
						3'd2:rt <= R[2];
						3'd3:rt <= R[3];
						3'd4:rt <= R[4];
						3'd5:rt <= R[5];
						3'd6:rt <= R[6];
						3'd7:rt <= R[7];
						default:rt <= 16'd0;
					endcase
					funct <= IR[2:0];
					im <= IR[5:0];
					addr <= IR[11:0];
					next_state <= EX;
				end
				EX:
				begin
					if(OP == 4'b0000)//R sort
					begin
						case(funct)
							3'b000,3'b001:temp <= rs + rt;//add or addu
							3'b010,3'b011:temp <= rs - rt;//sub or subu
							3'b100:temp <= (rs < rt) ? 16'd1:16'd0;//slt
							3'b101:temp <= rs & rt;//and
							3'b110:temp <= rs | rt;//or
							3'b111:PC <= rs;//jr
							default:temp <= 16'd0;
						endcase
					end
					else if(OP[3])//I sort
					begin
						case(OP)
							4'b1000:temp <= rs + {10'd0,im};//addi
							4'b1001:temp <= rs - {10'd0,im};//subi
							4'b1010:temp <= rs & {10'd0,im};//andi
							4'b1011:temp <= rs | {10'd0,im};//ori
							4'b1110:PC <= (rs==rt) ? (PC+16'd2+im<<1):PC;//beq
							4'b1111:PC <= (rs!=rt) ? (PC+16'd2+im<<1):PC;//bne
							default:temp <= 16'd0;
						endcase
					end
					else if(OP[2])//J sort
					begin
						if(OP == 4'b0100)//j
							PC <= {PC_1[15:12],addr};
						else if(OP == 4'b0101)//jal
						begin
							R[7] <= PC;
							PC <= {PC_1[15:12],addr};
						end
					end
					else
						next_state <= IDLE;
						
					next_state <= MEM;
					read_cnt <= 2'd0;
					write_cnt <= 2'd0;
					data_addr <= 16'd0;
				end
				MEM:
				begin
					case(OP)
						4'b1100://lw
							begin
								mem_ctrl <= 2'b10;//read
								{cpu_receive,cpu_send} <= 2'b00;//must be reseted before ram corresponding execution
								
								if(read_cnt == 2'd0)
								begin
									data_addr <= rs + {10'd0,im};
									delay_en <= 1'b1;
									
									//signal receive control part
									if(cpu_receive && ram_send)//priority
									begin
										cpu_receive <= 1'b0;
										delay_en <= 1'b0;
										read_cnt <= 2'd1;
									end
									else if(ram_send)//cpu read control part
									begin
										temp[15:8] <= data_read;
										if(temp[15:8] == data_read)
											cpu_receive <= 1'b1;
										else
											cpu_receive <= 1'b0;
									end
									else
									begin
										temp[15:8] <= temp[15:8];
										read_cnt <= 2'd0;
									end
								end
								
								else if(read_cnt == 2'd1)
								begin
									data_addr <= rs + {10'd0,im} + 16'd1;
									delay_en <= 1'b1;
									
									//signal receive control part
									if(cpu_receive && ram_send)//priority
									begin
										cpu_receive <= 1'b0;
										delay_en <= 1'b0;
										read_cnt <= 2'd2;
									end
									else if(ram_send)//cpu read control part
									begin
										temp[7:0] <= data_read;
										if(temp[7:0] == data_read)
											cpu_receive <= 1'b1;
										else
											cpu_receive <= 1'b0;
									end
									else
									begin
										temp[7:0] <= temp[7:0];
										read_cnt <= 2'd1;
									end
								end

								else if(read_cnt == 2'd2)
								begin
									next_state <= WB;
									read_cnt = 2'd0;
									mem_ctrl <= 2'b00;//disable
									{cpu_receive,cpu_send} <= 2'b00;
								end

								else
								begin
									next_state <= MEM;
									temp <= temp;
								end
								
							end
						4'b1101://sw
							begin
								mem_ctrl <= 2'b01;//write
								{cpu_receive,cpu_send} <= 2'b00;//must be reseted before ram corresponding execution
								
								if(write_cnt == 2'd0)
								begin
									data_addr <= rs + {10'd0,im};
									data_store <= rt[15:8];
									
									//signal send control part
									if(cpu_send && ram_receive)
									begin
										cpu_send <= 1'b0;
										write_cnt <= 2'd1;
									end
									else if(data_store == rt[15:8])
										cpu_send <= 1'b1;
									else
									begin
										cpu_send <= 1'b0;
										write_cnt <= 2'd0;
									end
								end
								
								else if(write_cnt == 2'd1)
								begin
									data_addr <= rs + {10'd0,im} + 16'd1;
									data_store <= rt[7:0];
									
									//signal send control part
									if(cpu_send && ram_receive)
									begin
										cpu_send <= 1'b0;
										write_cnt <= 2'd2;
									end
									else if(data_store == rt[7:0])
										cpu_send <= 1'b1;
									else
									begin
										cpu_send <= 1'b0;
										write_cnt <= 2'd1;
									end
								end
								
								else if(write_cnt == 2'd2)
								begin
									next_state <= WB;
									write_cnt <= 2'd0;
									mem_ctrl <= 2'b00;//disable
									{cpu_receive,cpu_send} <= 2'b00;
								end
								
								else
								begin
									next_state <= MEM;
									write_cnt <= write_cnt;
								end
							end
						default:
							begin
								mem_ctrl <= 2'b00;//disable
								temp <= temp;
								data_store <= 8'd0;
								data_addr <= 8'd0;
								next_state <= WB;
							end
					endcase
				end
				WB:
				begin
					if(OP == 4'b0000)//R sort
					begin
						case(IR[5:3])
							3'd0:R[0] <= temp;
							3'd1:R[1] <= temp;
							3'd2:R[2] <= temp;
							3'd3:R[3] <= temp;
							3'd4:R[4] <= temp;
							3'd5:R[5] <= temp;
							3'd6:R[6] <= temp;
							3'd7:R[7] <= temp;
						endcase
					end
					else if(OP[3])//I sort
					begin
						if((OP[3:2] == 2'b10) | (OP == 4'b1100))//write to rt
						begin
							case(IR[8:6])
								3'd0:R[0] <= temp;
								3'd1:R[1] <= temp;
								3'd2:R[2] <= temp;
								3'd3:R[3] <= temp;
								3'd4:R[4] <= temp;
								3'd5:R[5] <= temp;
								3'd6:R[6] <= temp;
								3'd7:R[7] <= temp;
							endcase
						end
					end
					else//J sort + remaining I sort
						{R[0],R[1],R[2],R[3],R[4],R[5],R[6],R[7]} <= {R[0],R[1],R[2],R[3],R[4],R[5],R[6],R[7]};
					done <= 1'b1;
					next_state <= IDLE;
				end
			endcase
			
		end
	end
	
endmodule