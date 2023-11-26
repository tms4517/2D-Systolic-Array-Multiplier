#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <stdlib.h>
#include <vector>

#include "VtopSystolicArray.h" // Verilated DUT.
#include <verilated.h>         // Common verilator routines.
#include <verilated_vcd_c.h>   // Write waverforms to a VCD file.

#define MAX_SIM_TIME 500 // Number of clk edges.
#define RESET_NEG_EDGE 5 // Clk edge number to deassert arst.
#define VERIF_START_TIME 7

#define N 4 // Square matrix dimension
#define WIDTH 8

// Max value of an element.
const int maxValue = std::pow(2, WIDTH);
// Number of clk cycles before validInput should be asserted.
const int assertValidInput = (3 * N) + 3;

vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;

uint8_t matrixA[N][N];
uint8_t matrixB[N][N];
uint32_t matrixC[N][N];

// Assert arst only on the first clock edge.
// Note: By default all signals are initialized to 0, so there's no need to
// drive the other inputs to '0.
void dut_reset(VtopSystolicArray *dut) {
  dut->i_arst = 0;

  if ((sim_time > 2) && (sim_time < RESET_NEG_EDGE)) {
    dut->i_arst = 1;
  }
}

// Assert validInput after every 10 clk cycles (after reset).
void toggle_i_validInput(VtopSystolicArray *dut) {
  dut->i_validInput = 0;

  if ((posedge_cnt % assertValidInput == 0) && (sim_time >= RESET_NEG_EDGE)) {
    dut->i_validInput = 1;
  }
}

void displayMatrix(char matrix) {
  if (matrix == 'A') {
    std::cout << std::endl;
    std::cout << "Matrix A " << std::endl;
    for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
        std::cout << std::hex << static_cast<int>(matrixA[i][j]) << "\t";
      }
      std::cout << std::endl;
    }
  } else if (matrix == 'B') {
    std::cout << std::endl;
    std::cout << "Matrix B " << std::endl;
    for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
        std::cout << std::hex << static_cast<int>(matrixB[i][j]) << "\t";
      }
      std::cout << std::endl;
    }
  } else if (matrix == 'C') {
    std::cout << std::endl;
    std::cout << "Result: Matrix C " << std::endl;
    for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
        std::cout << std::hex << static_cast<int>(matrixC[i][j]) << "\t";
      }
      std::cout << std::endl;
    }
  }
}

void initializeInputMatrices() {
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < N; j++) {
      matrixA[i][j] = rand() % maxValue;
      matrixB[i][j] = rand() % maxValue;
    }
  }
}

void driveInputMatrices(VtopSystolicArray *dut) {

  int numArrays = (std::pow(N, 2) + 4 - 1) / 4;

  for (int i = 0; i < numArrays; i++) {
    dut->i_a[i] = 0;
    dut->i_b[i] = 0;
  }

  if ((posedge_cnt % assertValidInput == 0) && (sim_time >= RESET_NEG_EDGE)) {
    initializeInputMatrices();
    displayMatrix('A');
    displayMatrix('B');

    // Convert matrices to single arrays.
    std::vector<uint8_t> singleArrayA;
    std::vector<uint8_t> singleArrayB;

    for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
        singleArrayA.push_back(matrixA[i][j]);
        singleArrayB.push_back(matrixB[i][j]);
      }
    }

    // Drive the input ports.
    // Note: Verilator input ports are represented as 32 bit arrays. numArrays
    // represents the number of these arrays required to represent the input
    // matrix. Eg - 7 32 bit arrays are required to represent a 5x5 matrix.

    int index = 0;

    for (int i = 0; i < numArrays; i++) {
      for (int j = 0; j < 4; j++) {
        dut->i_a[i] |= (static_cast<uint32_t>(singleArrayA[index] << (8 * j)));
        dut->i_b[i] |= (static_cast<uint32_t>(singleArrayB[index] << (8 * j)));

        index++;
      }
    }
  }
}

void calculateResultMatrix() {
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < N; j++) {
      matrixC[i][j] = 0;

      for (int k = 0; k < N; ++k) {
        matrixC[i][j] += matrixA[i][k] * matrixB[k][j];
      }
    }
  }
}

void verifyOutputMatrix(VtopSystolicArray *dut) {
  if ((dut->o_validResult == 1) && (sim_time >= VERIF_START_TIME)) {
    calculateResultMatrix();
    displayMatrix('C');

    // Note: Verilator represents the output matrix as n^2 bit arrays.
    bool incorrect = false;

    for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
        if (dut->o_c[(N * i) + j] != matrixC[i][j]) {
          incorrect = true;
        }
      }
    }

    if (incorrect) {
      std::cout << "ERROR: result matrix is incorrect." << std::endl;

      for (int i = 0; i < N * N; i++) {
        std::cout << std::hex << dut->o_c[i] << std::endl;
      }

      std::cout << " simtime: " << (int)sim_time << std::endl;
      std::cout << "*********************************************" << std::endl;
    }
  }
}

int main(int argc, char **argv, char **env) {
  srand(time(NULL));
  Verilated::commandArgs(argc, argv);
  VtopSystolicArray *dut = new VtopSystolicArray; // Instantiate DUT.

  // {{{ Set-up waveform dumping.

  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");

  // }}} Set-up waveform dumping.

  while (sim_time < MAX_SIM_TIME) {
    dut_reset(dut);

    dut->i_clk ^= 1; // Toggle clk to create pos and neg edge.

    dut->eval(); // Evaluate all the signals in the DUT on each clock edge.

    if (dut->i_clk == 1) {
      posedge_cnt++;

      toggle_i_validInput(dut);
      driveInputMatrices(dut);
      verifyOutputMatrix(dut);
    }

    // Write all the traced signal values into the waveform dump file.
    m_trace->dump(sim_time);

    sim_time++;
  }

  m_trace->close();
  delete dut;
  exit(EXIT_SUCCESS);
}
