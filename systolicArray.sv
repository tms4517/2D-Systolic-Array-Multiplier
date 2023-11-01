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
  ( input  var logic                 i_clk
  , input  var logic                 i_arst

  , input  var logic [3:0][6:0][7:0] i_row
  , input  var logic [3:0][6:0][7:0] i_col

  , output var logic [3:0][3:0][15:0] o_c
  );

  // Variable used to pass data horizontally between PEs in the same row. The
  // output o_a of one PE is connected to the input i_a of the PE to its right.
  logic [3:0][2:0][7:0] rowInterConnect;

  // Variable used to pass data vertically between PEs in the same column. The
  // output o_b of one PE is connected to the input i_b of the PE below it.
  logic [2:0][3:0][7:0] colInterConnect;

  for (genvar i = 0; i < 4; i++) begin: la_PerRow
    for (genvar j = 0; j < 4; j++) begin: la_PerCol

      // Element group A (top row left most element).
      // PE receives both inputs from the row and col matrices.
      if ((i == 0) && (j == 0)) begin: la_ElementA

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (i_row[0][0])
        , .i_b (i_col[0][0])

        , .o_a (rowInterConnect[0][0])
        , .o_b (colInterConnect[0][0])
        , .o_y (o_c[0][0])
        );

      end: la_ElementA

      // Element group B (top row right most element).
      // PE receives input B from the col matrix and input A from the PE on its
      // LHS. It's output A is unconnected.
      else if ((i == 0) && (j == 3)) begin: la_ElementB

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (rowInterConnect[0][2])
        , .i_b (i_col[3][0])

        , .o_a ()
        , .o_b (colInterConnect[0][3])
        , .o_y (o_c[0][3])
        );

      end: la_ElementB

      // Element group C (bottom row left most element).
      // PEs receives input A from the row matrix and input B from the PE directly
      // above it. It's output B is unconnected.
      else if ((i == 3) && (j == 0)) begin: la_ElementC

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (i_row[3][0])
        , .i_b (colInterConnect[2][0])

        , .o_a (rowInterConnect[3][0])
        , .o_b ()
        , .o_y (o_c[i][0])
        );

      end: la_ElementC

      // Element group D (bottom row right most element).
      // PEs receives input A from the PE on its LHS and input B from the PE
      // directly above it. Output A and B are left unconnected.
      else if ((i == 3) && (j == 3)) begin: la_ElementD

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (rowInterConnect[3][2])
        , .i_b (colInterConnect[2][3])

        , .o_a ()
        , .o_b ()
        , .o_y (o_c[3][3])
        );

      end: la_ElementD

      // Element group E (top row excluding elements on the edges).
      // PEs receives input B from the col matrix and input A from the PE on its
      // LHS.
      if ((i == 0) && (0 < j) && (j < 3)) begin: la_ElementE

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (rowInterConnect[0][j-1])
        , .i_b (i_col[j][0])

        , .o_a (rowInterConnect[0][j])
        , .o_b (colInterConnect[0][j])
        , .o_y (o_c[0][j])
        );

      end: la_ElementE

      // Element group F (right most column excluding elements on the edges).
      // PEs receives input A from the PE on its LHS and input B from the PE
      // directly above it. Output A is left unconnected.
      else if ((0 < i) && (i < 3) && (j == 3)) begin: la_ElementF

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (rowInterConnect[i][2])
        , .i_b (colInterConnect[i-1][3])

        , .o_a ()
        , .o_b (colInterConnect[i][3])
        , .o_y (o_c[i][3])
        );

      end: la_ElementF

      // Element group G (bottom row excluding elements on the edges).
      // PEs receives input B from the PE above it and input A from the PE on its
      // LHS. Output B is left unconnected.
      else if ((i == 3) && (0 < j ) && (j < 3)) begin: la_ElementG

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (rowInterConnect[3][j-1])
        , .i_b (colInterConnect[2][j])

        , .o_a (rowInterConnect[3][j])
        , .o_b ()
        , .o_y (o_c[3][j])
        );

      end: la_ElementG

      // Element group H (left most column excluding elements on the edges).
      // PEs receives input A from the row matrix and input B from the PE directly
      // above it.
      else if ((0 < i) && (i < 3) && (j == 0)) begin: la_ElementH

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (i_row[i][0])
        , .i_b (colInterConnect[i-1][0])

        , .o_a (rowInterConnect[i][0])
        , .o_b (colInterConnect[i][0])
        , .o_y (o_c[i][0])
        );

      end: la_ElementH

      // Element group I (elements not in the top/bottom row and not in the
      // left/right most column).
      // PEs receives input B from the PE above it and input A from the PE on its
      // LHS. Output A is connected to the PE on it RHS and output B is connected
      // to the PE below it.
      else if ((0 < i ) && (i < 3) && (0 < j ) && (j < 3)) begin: la_ElementI

        pe u_pe
        ( .i_clk
        , .i_arst

        , .i_a (rowInterConnect[i][j-1])
        , .i_b (colInterConnect[i-1][j])

        , .o_a (rowInterConnect[i][j])
        , .o_b (colInterConnect[i][j])
        , .o_y (o_c[i][j])
        );

      end: la_ElementI

    end: la_PerCol
  end: la_PerRow

endmodule

`resetall
