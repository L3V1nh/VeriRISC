module counter (
    input logic [4:0] data, ra,
    input load, enable, clk, rst_, jra,
    output logic [4:0] count
);
    logic [4:0] count_next;
    always_ff @( posedge clk, negedge rst_ ) begin
        if(~rst_) count <= '0;
        else count <= count_next;
    end

    always_comb begin : next_logic
        count_next=count;
        if(jra) count_next = ra + 1; 
        else if(load) count_next = data;
        else if(enable) count_next++;
    end
endmodule