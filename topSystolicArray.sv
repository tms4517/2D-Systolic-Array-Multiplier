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




endmodule

`resetall
