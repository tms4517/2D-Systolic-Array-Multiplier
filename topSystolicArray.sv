`default_nettype none

module topSystolicArray
  ( input  var logic                 i_clk
  , input  var logic                 i_arst

  , input  var logic [3:0][3:0][7:0] i_a
  , input  var logic [3:0][3:0][7:0] i_b

  , input  var logic                 i_validInput

  , output var logic [3:0][3:0][7:0] o_c

  , output var logic                 o_validResult
  );

  // {{{ Set-up row and column matrices

  // The rows are inputs to the i_a port of PEs in the first column.
  // The columns are inputs to the i_b port of PEs in the first row.
  logic [3:0][6:0][7:0] row_d, row_q;
  logic [3:0][6:0][7:0] col_d, col_q;

  // When i_validInput is asserted set up the row and col matrices. Else, right
  // shift by 1 element (8 bits) to pass the next inputs to the systolic array.

  for (genvar i = 0; i < 4; i++) begin: la_perRowCol

    always_ff @(posedge i_clk, posedge i_arst)
      if (i_arst)
        row_q[i] <= '0;
      else
        row_q[i] <= row_d[i];

    always_comb
      if (i_validInput)
        row_d[i] = {24'b0, a_q[i] << i*8};
      else
        row_d[i] = {1'b0, row_d[i] >> 8};

    always_ff @(posedge i_clk, posedge i_arst)
      if (i_arst)
        col_q[i] <= '0;
      else
        col_q[i] <= col_d[i];

    always_comb
      if (i_validInput)
        col_d[i] = {24'b0, b_q[0][i], b_q[1][i], b_q[2][i], b_q[3][i]} << i*8};
      else
        col_d[i] = {1'b0, col_d[i] >> 8};

  end: la_perRowCol

  // }}} Set-up rows and columns matrices

endmodule

`resetall
