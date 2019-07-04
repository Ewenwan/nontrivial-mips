`include "cpu_defs.svh"

module pc_generator (
	input  logic   clk,
	input  logic   rst_n,
	input  logic   flush,
	input  logic   hold_pc,

	// exception
	input  logic   except_valid,
	input  virt_t  except_vec,

	// branch prediction
	input  logic   predict_valid,
	input  virt_t  predict_vaddr,
	
	// branch misprediction
	input  branch_resolved_t resolved_branch,

	output virt_t  pc
);

localparam int PC_INC_OFFSET = $clog2(`FETCH_NUM) + 2;

virt_t npc, pc_now, fetch_vaddr;
assign pc = pc_now;
assign fetch_vaddr = predict_valid ? predict_vaddr : pc_now;

always_comb begin
	// default
	npc[31:PC_INC_OFFSET]  = fetch_vaddr[31:PC_INC_OFFSET] + 1;
	npc[PC_INC_OFFSET-1:0] = '0;

	// mispredict
	if(resolved_branch.valid & resolved_branch.mispredict) begin
		npc = resolved_branch.target;
	end

	// exception
	if(except_valid) begin
		npc = except_vec;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n || flush) begin
		pc_now <= `BOOT_VEC;
	end else if(~hold_pc) begin
		pc_now <= npc;
	end
end

endmodule