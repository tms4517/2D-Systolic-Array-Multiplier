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

# Example matrices (both are 5x5 square matrices)
matrix_A = [
    [0x22, 0x6b, 0xc6, 0xe7, 0xa7],
    [0x3d, 0x8f, 0x58, 0x60, 0xf3],
    [0xfb, 0xa6, 0x9c, 0x8e, 0x33],
    [0x13, 0x69, 0x68, 0xc3, 0xe1],
    [0x89, 0x8a, 0xf6, 0x7a, 0x1d]
]

matrix_B = [
    [0xfd, 0x13, 0x45, 0xb1, 0x39],
    [0x1f, 0xd7, 0x62, 0x3b, 0xec],
    [0x2f, 0xd7, 0x4a, 0x48, 0x6c],
    [0x55, 0x7e, 0x30, 0x50, 0x6a],
    [0x1e, 0x18, 0xe2, 0x56, 0x6e]
]

# Multiply matrices
result_matrix = matrix_multiply(matrix_A, matrix_B)

# Print the result in hexadecimal
print_matrix_in_hex(result_matrix)
