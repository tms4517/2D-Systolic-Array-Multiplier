#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <iomanip>
#include <cmath>

#include <verilated.h>         // Common verilator routines.
#include <verilated_vcd_c.h>   // Write waverforms to a VCD file.
#include "VtopSystolicArray.h" // Verilated DUT.

#define MAX_SIM_TIME 500  // Number of clk edges.
#define RESET_NEG_EDGE 5  // Clk edge number to deassert arst.
#define VERIF_START_TIME 7

#define N 4 // Square matrix dimension
#define WIDTH 8

// Calculate max value of an element.
const int maxValue = std::pow(2, WIDTH);

vluint64_t sim_time    = 0;
vluint64_t posedge_cnt = 0;

uint32_t matrixA[N][N];
uint32_t matrixB[N][N];
uint32_t matrixC[N][N];

// Assert arst only on the first clock edge.
// Note: By default all signals are initialized to 0, so there's no need to drive
// the other inputs to '0.
void dut_reset (VtopSystolicArray *dut)
{
  dut->i_arst = 0;

  if ((sim_time > 2) && (sim_time < RESET_NEG_EDGE))
  {
    dut->i_arst = 1;
  }
}

// Assert validInput after every 10 clk cycles (after reset).
void toggle_i_validInput(VtopSystolicArray *dut)
{
  dut->i_validInput = 0;

  if ((posedge_cnt%15 == 0) && (sim_time >= RESET_NEG_EDGE))
  {
    dut->i_validInput = 1;
  }
}

void displayMatrix(char matrix)
{
  if (matrix == 'A')
  {
    std::cout << std::endl;
    std::cout << "Matrix A " << std::endl;
    for (int i = 0; i < N; ++i)
    {
      for (int j = 0; j < N; ++j)
      {
          std::cout << std::hex << matrixA[i][j] << "\t";
      }
      std::cout << std::endl;
    }
  }
  else if (matrix == 'B')
  {
    std::cout << std::endl;
    std::cout << "Matrix B " << std::endl;
    for (int i = 0; i < N; ++i)
    {
      for (int j = 0; j < N; ++j)
      {
          std::cout << std::hex << matrixB[i][j] << "\t";
      }
      std::cout << std::endl;
    }
  }
  else if (matrix == 'C')
  {
    std::cout << std::endl;
    std::cout << "Result: Matrix C " << std::endl;
    for (int i = 0; i < N; ++i)
    {
      for (int j = 0; j < N; ++j)
      {
          std::cout << std::hex <<matrixC[i][j] << "\t";
      }
      std::cout << std::endl;
    }
  }
}

void initializeInputMatrices()
{
  for (int i = 0; i < N; i++)
  {
      for (int j = 0; j < N; ++j)
      {
        matrixA[i][j] = rand() % maxValue;
        matrixB[i][j] = rand() % maxValue;
      }
  }
}

void driveInputMatrices(VtopSystolicArray *dut)
{
  dut->i_a[0] = 0;
  dut->i_a[1] = 0;
  dut->i_a[2] = 0;
  dut->i_a[3] = 0;

  dut->i_b[0] = 0;
  dut->i_b[1] = 0;
  dut->i_b[2] = 0;
  dut->i_b[3] = 0;

  if ((posedge_cnt%15 == 0) && (sim_time >= RESET_NEG_EDGE))
  {
    initializeInputMatrices();
    displayMatrix('A');
    displayMatrix('B');

    for (int i = 0; i < N; i++)
    {
      dut->i_a[i] |=  matrixA[i][0]        & 0x000000FF;
      dut->i_a[i] |= (matrixA[i][1] << 8)  & 0x0000FF00;
      dut->i_a[i] |= (matrixA[i][2] << 16) & 0x00FF0000;
      dut->i_a[i] |= (matrixA[i][3] << 24) & 0xFF000000;

      dut->i_b[i] |=  matrixB[i][0]        & 0x000000FF;
      dut->i_b[i] |= (matrixB[i][1] << 8)  & 0x0000FF00;
      dut->i_b[i] |= (matrixB[i][2] << 16) & 0x00FF0000;
      dut->i_b[i] |= (matrixB[i][3] << 24) & 0xFF000000;
    }
  }
}

void calculateResultMatrix()
{
  for (int i = 0; i < N; ++i)
  {
    for (int j = 0; j < N; ++j)
    {
        matrixC[i][j] = 0;

        for (int k = 0; k < N; ++k)
        {
            matrixC[i][j] += matrixA[i][k] * matrixB[k][j];
        }
    }
  }
}

void verifyOutputMatrix(VtopSystolicArray *dut)
{
  if ((dut->o_validResult == 1) && (sim_time >= VERIF_START_TIME))
  {
    calculateResultMatrix();
    displayMatrix('C');

    // Note: Verilator represents the output matrix as 16 32 bit arrays.
    bool incorrect = false;

    for (int i = 0; i < N; ++i)
    {
      for (int j = 0; j < N; ++j)
      {
        if(dut->o_c[(N*i) + j] != matrixC[i][j])
        {
          incorrect = true;
        }
      }
    }

    if (incorrect)
    {
      std::cout << "ERROR: result matrix is incorrect." << std::endl;

      for (int i = 0; i < N*N; i++)
      {
        std::cout << std::hex << dut->o_c[i] << std::endl;
      }

      std::cout << " simtime: " << (int)sim_time << std::endl;
      std::cout << "*********************************************" << std::endl;
    }
  }
}

int main(int argc, char** argv, char** env)
{
  srand (time(NULL));
  Verilated::commandArgs(argc, argv);
  VtopSystolicArray *dut = new VtopSystolicArray; // Instantiate DUT.

  // {{{ Set-up waveform dumping.

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

  // }}} Set-up waveform dumping.

  while (sim_time < MAX_SIM_TIME)
  {
    dut_reset(dut);

    dut->i_clk ^= 1; // Toggle clk to create pos and neg edge.

    dut->eval(); // Evaluate all the signals in the DUT on each clock edge.

    if (dut->i_clk == 1)
    {
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
