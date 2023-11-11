`default_nettype none

module topSystolicArray
  ( input  var logic                 i_clk
  , input  var logic                 i_arst

  , input  var logic [3:0][3:0][7:0] i_a
  , input  var logic [3:0][3:0][7:0] i_b

  , input  var logic                 i_validInput

  , output var logic [3:0][3:0][15:0] o_c

  , output var logic                 o_validResult
  );

  // {{{ Control counter
  // This counter is used to determine when to assert o_validResult and sets up
  // the necessary control signals.

  logic [3:0] counter_d, counter_q;

  always_ff @(posedge i_clk, posedge i_arst)
    if (i_arst)
      counter_q <= 0;
    else
      counter_q <= counter_d;

  always_comb
    if (i_validInput)
      counter_d = '0;
    else
      counter_d = counter_q + 1'b1;

  always_comb
    o_validResult = (counter_q == 4'd10) ? '1 : '0;

  logic doProcess;

  // }}} Control counter

  // {{{ Systolic array clock gate

  logic doProcess_d, doProcess_q;

  always_ff @(posedge i_clk, posedge i_arst)
    if (i_arst)
      doProcess_q <= '0;
    else
      doProcess_q <= doProcess_d;

  always_comb
    if (i_validInput)
      doProcess_d = '1;
    else if (counter_q == 4'd10)
      doProcess_d = '1;
    else
      doProcess_d = doProcess_q;

  // }}} Systolic array clock gate

  // {{{ Set-up row and column matrices

  // The rows are inputs to the i_a port of PEs in the first column.
  // The columns are inputs to the i_b port of PEs in the first row.
  logic [3:0][6:0][7:0] row_d, row_q;
  logic [3:0][6:0][7:0] col_d, col_q;

  // When i_validInput is asserted set up the row and col matrices. Else, right
  // shift by 1 element (8 bits) to pass the next inputs to the systolic array.

  // If (i_validInput) and (counter_q != '0) are both asserted the validInput
  // condition should take priority since the synthesis tool infers if, else as
  // priority encoding.

  for (genvar i = 0; i < 4; i++) begin: la_perRowCol

    always_ff @(posedge i_clk, posedge i_arst)
      if (i_arst)
        row_q[i] <= '0;
      else
        row_q[i] <= row_d[i];

    always_comb
      if (i_validInput)
        row_d[i] = {24'b0, i_a[i]} << i*8;
      else if (counter_q != '0)
        row_d[i] = row_q[i] >> 8;
      else
        row_d[i] = row_q[i];

    always_ff @(posedge i_clk, posedge i_arst)
      if (i_arst)
        col_q[i] <= '0;
      else
        col_q[i] <= col_d[i];

    always_comb
      if (i_validInput)
        col_d[i] = {24'b0, i_b[0][i], i_b[1][i], i_b[2][i], i_b[3][i]} << i*8;
      else if (counter_q != '0)
        col_d[i] = col_q[i] >> 8;
      else
        col_d[i] = col_q[i];

  end: la_perRowCol

  // }}} Set-up rows and columns matrices

  systolicArray u_systolicArray
  ( .i_clk
  , .i_arst

  , .i_doProcess (doProcess_q)

  , .i_row (row_q)
  , .i_col (col_q)

  , .o_c
  );
endmodule

`resetall
