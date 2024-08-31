import math
from scipy.optimize import fsolve

# Given values
# total = 69_000_000_000
# delta_x = total * 4 / 5
# delta_y = 100_000


total = 1_000_000_000
delta_x = total * 4 / 5
delta_y = 69_000

delta_C = total - delta_x
C = delta_y / delta_C
print("p for token =", C)


# Define the system of equations
def equations(vars):
    a, b = vars
    eq1 = C - a * math.exp(b * delta_x)  # C = a * e^(b * delta_x)
    eq2 = delta_y - (a / b) * (math.exp(b * delta_x) - 1)  # delta_y = (a/b) * (e^(b * delta_x) - 1)
    return [eq1, eq2]


# Initial guess
initial_guess = [1e-7, 1e-10]  # Start with a small guess for a and b

# Solve the system of equations
a, b = fsolve(equations, initial_guess)
print(a, b)
print(a * 10**18, b * 10**18)

