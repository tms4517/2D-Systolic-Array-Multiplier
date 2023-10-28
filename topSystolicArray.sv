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





endmodule

`resetall
