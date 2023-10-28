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

  // {{{ Store valid inputs

  // a and b are 4x4 matrices where each element is 8-bits wide.
  logic [3:0][3:0][7:0] a_q, b_q;

  always_ff @(posedge i_clk, posedge i_arst)
    if (i_arst)
      a_q <= '0;
    else if (i_validInput)
      a_q <= i_a;
    else
      a_q <= a_q;

  always_ff @(posedge i_clk, posedge i_arst)
    if (i_arst)
      b_q <= '0;
    else if (i_validInput)
      b_q <= i_b;
    else
      b_q <= b_q;

  // }}} Store valid inputs

  // Note: Registering the inputs is not necessary and the rows and columns can be
  // set-up directly from the inputs.

  // {{{ Set-up rows and columns

  // The rows are inputs to the PEs in the first column.
  // The columns are inputs to the PEs in the first row.
  logic [3:0][6:0][7:0] row_q, col_q;

  for (genvar i = 0; i < 4; i++) begin: la_perRowCol

    always_ff @(posedge i_clk)
      row_q[i] <= ({24'b0, a_q} << i*8);

    always_ff @(posedge i_clk)
      col_q[i] <= ({24'b0, b_q[0][i], b_q[1][i], b_q[2][i], b_q[3][i]} << i*8);

  end: la_perRowCol

  // }}} Set-up rows and columns

endmodule

`resetall
