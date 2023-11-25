// This module interconnects the PEs to form a systolic array. Below, is an
// example of how PEs in a 4x4 systolic array are interconnected. The horizontal
// lines represent row interconnects, and the vertical lines represent column
// interconnects. The arrows indicate the direction of data flow.

// PE[0][0] --> PE[0][1] --> PE[0][2] --> PE[0][3]
//   |            |            |            |
//   v            v            v            v
// PE[1][0] --> PE[1][1] --> PE[1][2] --> PE[1][3]
//   |            |            |            |
//   v            v            v            v
// PE[2][0] --> PE[2][1] --> PE[2][2] --> PE[2][3]
//   |            |            |            |
//   v            v            v            v
// PE[3][0] --> PE[3][1] --> PE[3][2] --> PE[3][3]

`default_nettype none

module systolicArray
  #(parameter int unsigned N = 4)
  ( input  var logic                         i_clk
  , input  var logic                         i_arst

  , input  var logic                         i_doProcess

  , input  var logic [N-1:0][(2*N)-2:0][7:0] i_row
  , input  var logic [N-1:0][(2*N)-2:0][7:0] i_col

  , output var logic [N-1:0][N-1:0][31:0]    o_c
  );

  // Variable used to pass data horizontally between PEs in the same row. The
  // output o_a of one PE is connected to the input i_a of the PE to its right.
  logic [N-1:0][N:0][7:0] rowInterConnect;

  // Variable used to pass data vertically between PEs in the same column. The
  // output o_b of one PE is connected to the input i_b of the PE below it.
  logic [N:0][N-1:0][7:0] colInterConnect;

  for (genvar i = 0; i < N; i++) begin: la_PerDummyRowColInterconnect

    // These are dummy interconnects used to pass data from the row matrices to
    // the i_a ports of PE in the first col.
    always_comb
      rowInterConnect[i][0] = i_row[i][0];

    // These are dummy interconnects used to pass data  from the col matrices to
    // the i_b ports of PE in the first row.
    always_comb
      colInterConnect[0][i] = i_col[i][0];

  end: la_PerDummyRowColInterconnect

  for (genvar i = 0; i < N; i++) begin: la_PerRow
    for (genvar j = 0; j < N; j++) begin: la_PerCol

      pe u_pe
      ( .i_clk
      , .i_arst

      , .i_doProcess

      , .i_a (rowInterConnect[i][j])
      , .i_b (colInterConnect[i][j])

      , .o_a (rowInterConnect[i][j+1])
      , .o_b (colInterConnect[i+1][j])
      , .o_y (o_c[i][j])
      );

    end: la_PerCol
  end: la_PerRow

endmodule

`resetall
