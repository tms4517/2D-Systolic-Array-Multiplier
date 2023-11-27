`default_nettype none

module topSystolicArray
  #(parameter int unsigned N = 4)                             /* Modify this */
  ( input  var logic                      i_clk
  , input  var logic                      i_arst

  , input  var logic [N-1:0][N-1:0][7:0]  i_a
  , input  var logic [N-1:0][N-1:0][7:0]  i_b

  , input  var logic                      i_validInput

  , output var logic [N-1:0][N-1:0][31:0] o_c

  , output var logic                      o_validResult
  );

  // {{{ Check matrix dimension size is valid
  // Note: Verilator crashes for matrix dimensions > 256.
  localparam bit N_VALID = N > 2;

  if (!N_VALID) begin: la_ParamCheck
    $error("Matrix dimension size 'N' is invalid.");
  end: la_ParamCheck

  // }}} Check matrix dimension size is valid

  // {{{ Control counter
  // This counter is used to determine when to assert o_validResult and sets up
  // the necessary control signals.

  // TODO: Confirm
  // Number of clock cycles required to complete matrix multiplication.
  localparam int unsigned MULT_CYCLES = 3*N-2;
  // `+1` to support counter_q + 1;
  localparam int unsigned MULT_CYCLES_W = $clog2(MULT_CYCLES+1);

  logic [MULT_CYCLES_W-1:0] counter_d, counter_q;

  always_ff @(posedge i_clk, posedge i_arst)
    if (i_arst)
      counter_q <= 0;
    else
      counter_q <= counter_d;

  always_comb
    if (doProcess_d == '1)
      counter_d = counter_q + 1'b1;
    else
      counter_d = '0;

  logic validResult_q;

  always_ff @(posedge i_clk, posedge i_arst)
    if (i_arst)
      validResult_q <= '0;
    else if (counter_q == MULT_CYCLES_W'(MULT_CYCLES))
      validResult_q <= '1;
    else
      validResult_q <= '0;

  always_comb
    o_validResult = validResult_q;

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
    else if (counter_q == MULT_CYCLES_W'(MULT_CYCLES+1))
      doProcess_d = '0;
    else
      doProcess_d = doProcess_q;

  // }}} Systolic array clock gate

  // {{{ Set-up row and column matrices

  localparam int unsigned PAD = 8*(N-1);
  localparam bit [PAD-1:0] APPEND_ZERO = PAD'(0);

  // The rows are inputs to the i_a port of PEs in the first column.
  // The columns are inputs to the i_b port of PEs in the first row.
  logic [N-1:0][(2*N)-2:0][7:0] row_d, row_q;
  logic [N-1:0][(2*N)-2:0][7:0] col_d, col_q;

  logic [N-1:0][N-1:0][7:0] invertedRowElements;
  logic [N-1:0][N-1:0][7:0] invertedColElements;

  // When i_validInput is asserted set up the row and col matrices. Else, right
  // shift by 1 element (8 bits) to pass the next inputs to the systolic array.

  // If (i_validInput) and (counter_q != '0) are both asserted the validInput
  // condition should take priority since the synthesis tool infers if, else as
  // priority encoding.

  for (genvar i = 0; i < N; i++) begin: la_perRowCol

    always_ff @(posedge i_clk, posedge i_arst)
      if (i_arst)
        row_q[i] <= '0;
      else
        row_q[i] <= row_d[i];

    always_comb
      if (i_validInput)
        row_d[i] = {APPEND_ZERO, invertedRowElements[i]} << i*8;
      else if (counter_q != '0)
        row_d[i] = row_q[i] >> 8;
      else
        row_d[i] = row_q[i];

    // Invert the positions of the elements in each row to form the row matrix.
    for (genvar j = 0; j < N; j++) begin: la_perRowElement

      always_comb
        invertedRowElements[i][j] = i_a[i][N-j-1];

    end: la_perRowElement

    always_ff @(posedge i_clk, posedge i_arst)
      if (i_arst)
        col_q[i] <= '0;
      else
        col_q[i] <= col_d[i];

    always_comb
      if (i_validInput)
        col_d[i] = {APPEND_ZERO, invertedColElements[i]} << i*8;
      else if (counter_q != '0)
        col_d[i] = col_q[i] >> 8;
      else
        col_d[i] = col_q[i];

    // Invert the positions of the elements in each col to form the col matrix.
    for (genvar j = 0; j < N; j++) begin: la_perColElement

      always_comb
        invertedColElements[i][j] = i_b[N-j-1][i];

    end: la_perColElement

  end: la_perRowCol

  // }}} Set-up rows and columns matrices

  systolicArray
  #(.N (N))
  u_systolicArray
  ( .i_clk
  , .i_arst

  , .i_doProcess (doProcess_q)

  , .i_row (row_q)
  , .i_col (col_q)

  , .o_c
  );
endmodule

`resetall
