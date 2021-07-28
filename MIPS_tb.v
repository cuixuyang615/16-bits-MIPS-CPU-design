`timescale 1ns/1ns
module MIPS_tb();

	reg clk,rst_n,cpu_en;
	wire done;
	wire [15:0] data_addr;
	wire [7:0] data_write;
	reg [7:0]data_read;
	wire [1:0] mem_ctrl;
	
	wire wen,ren;
	wire [15:0] addr;
	
	wire cpu_send,cpu_receive;
	wire cpu_ready;
	
	reg     ram_send;
   reg     ram_receive;
	 
	assign addr = data_addr; 
	assign wen = mem_ctrl[0];
	assign ren = mem_ctrl[1];
	
	MIPS CPU(.clk(clk),
				.rst_n(rst_n),
				.cpu_en(cpu_en),
				.data_read(data_read),
				.ram_send(ram_send),
				.ram_receive(ram_receive),
				.cpu_send(cpu_send),
				.cpu_receive(cpu_receive),
				.cpu_ready(cpu_ready),
				.data_addr(data_addr),
				.data_store(data_write),
				.mem_ctrl(mem_ctrl),
				.done(done));
	
	
	initial
	begin
		clk = 1'b0;
		forever #10 clk = ~clk;
	end
	
	initial
	begin
		rst_n = 0;
		cpu_en = 0;
		
		#200
		rst_n = 1;
		cpu_en = 1;
		#20000
		$stop;
	end
	
	/*
	// cpu part
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			cpu_send <= 1'b0;
		else if(wen)
		begin
			if(cpu_send && ram_receive)//priority
				cpu_send <= 1'b0;
			else if((cpu_write == data_write) && (!ram_receive))
				cpu_send <= 1'b1;
			else
				cpu_send <= 1'b0;
		end
		else
			cpu_send <= 1'b0;
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			cpu_receive <= 1'b0;
		else if(ren)
		begin
			if(cpu_receive && ram_send)//priority
				cpu_receive <= 1'b0;
			else if((cpu_read == data_read) && ram_send)
				cpu_receive <= 1'b1;
			else
				cpu_receive <= 1'b0;
		end
		else
			cpu_receive <= 1'b0;
	end*/
	
	//ram part
    
	 reg   [7:0]  bram [4095:0]; 
	 
    always @(posedge clk or negedge rst_n)
    begin
       if (!rst_n)   
         begin
				$readmemh("D:/test.txt",bram);
				data_read <= 8'd0;
         end
       else if (wen) begin
            bram[addr] <= data_write;
       end
       else if (ren) begin
            data_read <= bram[addr];
       end
       else begin
			data_read <= 8'd0;
       end
    end

	 
	 always@(posedge clk or negedge rst_n)// in case of writing
	 begin
		if(!rst_n)
			ram_receive <= 1'b0;
		else if(wen)
		begin
			if(cpu_send && ram_receive)//priority
				ram_receive <= 1'b0;
			else if((bram[addr] == data_write) && cpu_send)
				ram_receive <= 1'b1;
			else
				ram_receive <= 1'b0;
		end
		else
			ram_receive <= 1'b0;
	 end
	 
	 reg avaliable;//prevent re-reading
	 always@(posedge cpu_ready or negedge cpu_receive)
	 begin
		if(cpu_ready)
			avaliable <= 1'b1;
		else if(!cpu_receive)
			avaliable <= 1'b0;
		else
			avaliable <= 1'b0;
	 end
	 
	 always@(posedge clk or negedge rst_n)// in case of reading
	 begin
		if(!rst_n)
			ram_send <= 1'b0;
		else if(ren)
		begin
			if(cpu_receive && ram_send)//priority
				ram_send <= 1'b0;
			else if((data_read == bram[addr]) && (!cpu_receive) && avaliable)
				ram_send <= 1'b1;
			else
				ram_send <= 1'b0;
		end
		else
			ram_send <= 1'b0;
	 end
endmodule