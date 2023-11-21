def matrix_multiply(matrix1, matrix2):
  # Check if matrices can be multiplied
  if len(matrix1) != len(matrix1[0]) or len(matrix2) != len(matrix2[0]) or len(matrix1[0]) != len(matrix2):
      raise ValueError("Both matrices must be square matrices of the same size for multiplication.")

  # Initialize the result matrix with zeros
  n = len(matrix1)
  result = [[0 for _ in range(n)] for _ in range(n)]

  # Perform matrix multiplication
  for i in range(n):
      for j in range(n):
          for k in range(n):
              result[i][j] += matrix1[i][k] * matrix2[k][j]

  return result

def print_matrix_in_hex(matrix):
  for row in matrix:
      hex_row = [hex(element) for element in row]
      print(hex_row)

# Example matrices (both are 2x2 square matrices)
matrix_A = [
    [2, 2, 2, 2],
    [2, 2, 2, 2],
    [2, 2, 2, 2],
    [2, 2, 2, 2],
]

matrix_B = [
    [3, 3, 3, 3],
    [3, 3, 3, 3],
    [3, 3, 3, 3],
    [3, 3, 3, 3],
]

# Multiply matrices
result_matrix = matrix_multiply(matrix_A, matrix_B)

# Print the result in hexadecimal
print_matrix_in_hex(result_matrix)
